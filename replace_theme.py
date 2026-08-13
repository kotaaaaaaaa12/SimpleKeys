import re

file_path = "SimpleKeys/SimpleKeys/ViewController.swift"

with open(file_path, "r") as f:
    content = f.read()

# Find the start of ThemeSettingsViewController
start_idx = content.find("// MARK: - Theme Settings")

if start_idx == -1:
    print("Could not find start index")
    exit(1)

new_content = content[:start_idx] + """// MARK: - My Themes & Editor

class MyThemesViewController: UITableViewController {
    var themes: [ThemeSettings] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
        title = isEn ? "My Themes" : "マイテーマ"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadThemes()
        tableView.reloadData()
    }
    
    private func loadThemes() {
        if let data = AppGroupHelper.shared.userDefaults?.data(forKey: ThemeSettings.themesArrayKey),
           let saved = try? JSONDecoder().decode([ThemeSettings].self, from: data) {
            themes = saved
        }
        if themes.isEmpty {
            var defaultTheme = ThemeSettings(keyStyle: 0)
            defaultTheme.id = UUID().uuidString
            defaultTheme.name = "Default"
            themes.append(defaultTheme)
            saveThemes()
        }
    }
    
    private func saveThemes() {
        if let data = try? JSONEncoder().encode(themes) {
            AppGroupHelper.shared.userDefaults?.set(data, forKey: ThemeSettings.themesArrayKey)
            AppGroupHelper.shared.userDefaults?.synchronize()
        }
    }
    
    @objc private func addTapped() {
        let editor = ThemeEditorViewController()
        editor.onSave = { [weak self] newTheme in
            self?.themes.append(newTheme)
            self?.saveThemes()
        }
        navigationController?.pushViewController(editor, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return themes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        let theme = themes[indexPath.row]
        cell.textLabel?.text = theme.name ?? "Untitled Theme"
        
        let styles = ["Standard", "Frosted Glass", "Flat", "Clear Glass"]
        cell.detailTextLabel?.text = "Style: \(styles[theme.keyStyle])"
        cell.detailTextLabel?.textColor = .secondaryLabel
        
        var activeThemeId: String? = nil
        if let data = AppGroupHelper.shared.userDefaults?.data(forKey: ThemeSettings.sharedKey),
           let saved = try? JSONDecoder().decode(ThemeSettings.self, from: data) {
            activeThemeId = saved.id
        }
        
        cell.accessoryType = (theme.id == activeThemeId && activeThemeId != nil) ? .checkmark : .detailButton
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let theme = themes[indexPath.row]
        if let data = try? JSONEncoder().encode(theme) {
            AppGroupHelper.shared.userDefaults?.set(data, forKey: ThemeSettings.sharedKey)
            AppGroupHelper.shared.userDefaults?.synchronize()
        }
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let editor = ThemeEditorViewController()
        editor.theme = themes[indexPath.row]
        editor.onSave = { [weak self] updatedTheme in
            self?.themes[indexPath.row] = updatedTheme
            self?.saveThemes()
            
            var activeThemeId: String? = nil
            if let data = AppGroupHelper.shared.userDefaults?.data(forKey: ThemeSettings.sharedKey),
               let saved = try? JSONDecoder().decode(ThemeSettings.self, from: data) {
                activeThemeId = saved.id
            }
            if activeThemeId == updatedTheme.id {
                if let data = try? JSONEncoder().encode(updatedTheme) {
                    AppGroupHelper.shared.userDefaults?.set(data, forKey: ThemeSettings.sharedKey)
                }
            }
        }
        navigationController?.pushViewController(editor, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            themes.remove(at: indexPath.row)
            saveThemes()
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}

class ThemeEditorViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var theme: ThemeSettings?
    var onSave: ((ThemeSettings) -> Void)?
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let previewContainer = UIView()
    private let previewBgImageView = UIImageView()
    private let previewKeyStack = UIStackView()
    
    private var currentTheme = ThemeSettings(keyStyle: 0)
    
    private let keyStyleSegment = UISegmentedControl(items: [])
    private let buttonShapeSegment = UISegmentedControl(items: [])
    private let nameField = UITextField()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
        title = isEn ? "Edit Theme" : "テーマ編集"
        view.backgroundColor = .systemGroupedBackground
        
        if let t = theme {
            currentTheme = t
        } else {
            currentTheme.id = UUID().uuidString
            currentTheme.name = "Custom Theme"
        }
        
        let styleItems = isEn ? ["Standard", "Frosted", "Flat", "Clear"] : ["標準", "磨りガラス", "フラット", "クリア"]
        for (i, item) in styleItems.enumerated() {
            keyStyleSegment.insertSegment(withTitle: item, at: i, animated: false)
        }
        
        let shapeItems = isEn ? ["Rounded", "Oval", "Rect"] : ["角丸", "楕円", "四角"]
        for (i, item) in shapeItems.enumerated() {
            buttonShapeSegment.insertSegment(withTitle: item, at: i, animated: false)
        }
        
        setupUI()
        updatePreview()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
    }
    
    private func setupUI() {
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.backgroundColor = .systemGray5
        previewContainer.layer.cornerRadius = 12
        previewContainer.clipsToBounds = true
        view.addSubview(previewContainer)
        
        previewBgImageView.translatesAutoresizingMaskIntoConstraints = false
        previewBgImageView.contentMode = .scaleAspectFill
        previewContainer.addSubview(previewBgImageView)
        
        previewKeyStack.translatesAutoresizingMaskIntoConstraints = false
        previewKeyStack.axis = .horizontal
        previewKeyStack.distribution = .fillEqually
        previewKeyStack.spacing = 8
        previewContainer.addSubview(previewKeyStack)
        
        for i in 0..<3 {
            let key = UIView()
            
            let label = UILabel()
            label.text = ["A", "B", "C"][i]
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 20)
            label.translatesAutoresizingMaskIntoConstraints = false
            
            key.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: key.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: key.centerYAnchor)
            ])
            
            previewKeyStack.addArrangedSubview(key)
        }
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            previewContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            previewContainer.heightAnchor.constraint(equalToConstant: 200),
            
            previewBgImageView.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            previewBgImageView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            previewBgImageView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            previewBgImageView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),
            
            previewKeyStack.centerXAnchor.constraint(equalTo: previewContainer.centerXAnchor),
            previewKeyStack.centerYAnchor.constraint(equalTo: previewContainer.centerYAnchor),
            previewKeyStack.widthAnchor.constraint(equalToConstant: 200),
            previewKeyStack.heightAnchor.constraint(equalToConstant: 45),
            
            tableView.topAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        keyStyleSegment.selectedSegmentIndex = currentTheme.keyStyle
        keyStyleSegment.addTarget(self, action: #selector(settingChanged), for: .valueChanged)
        
        buttonShapeSegment.selectedSegmentIndex = currentTheme.buttonShape ?? 0
        buttonShapeSegment.addTarget(self, action: #selector(settingChanged), for: .valueChanged)
        
        nameField.text = currentTheme.name
        nameField.placeholder = "Theme Name"
        nameField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)
    }
    
    @objc private func nameChanged() {
        currentTheme.name = nameField.text
    }
    
    @objc private func settingChanged() {
        currentTheme.keyStyle = keyStyleSegment.selectedSegmentIndex
        currentTheme.buttonShape = buttonShapeSegment.selectedSegmentIndex
        updatePreview()
    }
    
    private func updatePreview() {
        if let bgFile = currentTheme.backgroundImageFileName, let img = AppGroupHelper.shared.loadImage(fileName: bgFile) {
            previewBgImageView.image = img
            previewContainer.backgroundColor = .clear
        } else {
            previewBgImageView.image = nil
            previewContainer.backgroundColor = .systemGray5
        }
        
        let shape = currentTheme.buttonShape ?? 0
        let radius: CGFloat = shape == 0 ? 5 : (shape == 1 ? 22.5 : 0)
        
        for v in previewKeyStack.arrangedSubviews {
            v.subviews.filter { $0 is UIVisualEffectView }.forEach { $0.removeFromSuperview() }
            
            v.layer.cornerRadius = radius
            
            if currentTheme.keyStyle == 1 || currentTheme.keyStyle == 3 {
                v.backgroundColor = currentTheme.keyStyle == 3 ? UIColor.white.withAlphaComponent(0.15) : .clear
                v.layer.shadowOpacity = 0
                v.layer.borderWidth = 0.5
                v.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
                
                if currentTheme.keyStyle == 1 {
                    let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                    blur.layer.cornerRadius = radius
                    blur.clipsToBounds = true
                    blur.translatesAutoresizingMaskIntoConstraints = false
                    v.insertSubview(blur, at: 0)
                    NSLayoutConstraint.activate([
                        blur.leadingAnchor.constraint(equalTo: v.leadingAnchor),
                        blur.trailingAnchor.constraint(equalTo: v.trailingAnchor),
                        blur.topAnchor.constraint(equalTo: v.topAnchor),
                        blur.bottomAnchor.constraint(equalTo: v.bottomAnchor)
                    ])
                }
            } else if currentTheme.keyStyle == 2 {
                v.backgroundColor = .clear
                v.layer.shadowOpacity = 0
                v.layer.borderWidth = 1
                v.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor
            } else {
                v.backgroundColor = .white
                v.layer.shadowOpacity = 0.3
                v.layer.borderWidth = 0
            }
        }
    }
    
    @objc private func saveTapped() {
        if currentTheme.name == nil || currentTheme.name!.isEmpty {
            currentTheme.name = "Custom Theme"
        }
        onSave?(currentTheme)
        navigationController?.popViewController(animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int { return 3 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 1 ? 2 : 1
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
        if section == 0 { return isEn ? "Name" : "テーマ名" }
        if section == 1 { return isEn ? "Background" : "背景画像" }
        return isEn ? "Key Style & Shape" : "キースタイル & 形状"
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
        
        if indexPath.section == 0 {
            nameField.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(nameField)
            NSLayoutConstraint.activate([
                nameField.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                nameField.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                nameField.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
            ])
        } else if indexPath.section == 1 {
            cell.selectionStyle = .default
            if indexPath.row == 0 {
                cell.textLabel?.text = isEn ? "Choose Image" : "画像を選択"
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.textLabel?.text = isEn ? "Remove Image" : "画像を削除"
                cell.textLabel?.textColor = .systemRed
            }
        } else {
            let stack = UIStackView(arrangedSubviews: [keyStyleSegment, buttonShapeSegment])
            stack.axis = .vertical
            stack.spacing = 16
            stack.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                stack.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                stack.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
                stack.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12)
            ])
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                let picker = UIImagePickerController()
                picker.delegate = self
                picker.sourceType = .photoLibrary
                present(picker, animated: true)
            } else {
                currentTheme.backgroundImageFileName = nil
                updatePreview()
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            let fileName = "\(UUID().uuidString).jpg"
            if AppGroupHelper.shared.saveImage(image, fileName: fileName) {
                currentTheme.backgroundImageFileName = fileName
                updatePreview()
            }
        }
    }
}
"""

with open(file_path, "w") as f:
    f.write(new_content)
