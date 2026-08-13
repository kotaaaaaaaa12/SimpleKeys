import re

file_path = "SimpleKeys/SimpleKeys/ViewController.swift"

with open(file_path, "r") as f:
    content = f.read()

start_str = "class ThemeEditorViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {"
end_str = "}\n\nextension UIColor {"

start_idx = content.find(start_str)
end_idx = content.find(end_str, start_idx)

if start_idx == -1 or end_idx == -1:
    print("Could not find ThemeEditorViewController")
    exit(1)

new_class = r"""class ThemeEditorViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIColorPickerViewControllerDelegate {
    var theme: ThemeSettings?
    var onSave: ((ThemeSettings) -> Void)?
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let previewContainer = UIView()
    private let previewBgImageView = UIImageView()
    private let previewGrid = UIStackView()
    
    private var currentTheme = ThemeSettings(keyStyle: 0)
    
    private let keyStyleSegment = UISegmentedControl(items: [])
    private let buttonShapeSegment = UISegmentedControl(items: [])
    private let nameField = UITextField()
    private let opacitySlider = UISlider()
    
    private var pickingColorFor: String?
    
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
            currentTheme.keyOpacity = 1.0
        }
        
        if currentTheme.keyOpacity == nil { currentTheme.keyOpacity = 1.0 }
        
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
        
        previewGrid.translatesAutoresizingMaskIntoConstraints = false
        previewGrid.axis = .vertical
        previewGrid.distribution = .fillEqually
        previewGrid.spacing = 8
        previewContainer.addSubview(previewGrid)
        
        // Build a fake QWERTY grid
        let rows = [
            ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
            ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
            ["Z", "X", "C", "V", "B", "N", "M"]
        ]
        for row in rows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 6
            for letter in row {
                let key = UIView()
                let label = UILabel()
                label.text = letter
                label.textAlignment = .center
                label.font = .systemFont(ofSize: 18)
                label.tag = 777
                label.translatesAutoresizingMaskIntoConstraints = false
                key.addSubview(label)
                NSLayoutConstraint.activate([
                    label.centerXAnchor.constraint(equalTo: key.centerXAnchor),
                    label.centerYAnchor.constraint(equalTo: key.centerYAnchor)
                ])
                rowStack.addArrangedSubview(key)
            }
            previewGrid.addArrangedSubview(rowStack)
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
            
            previewGrid.centerXAnchor.constraint(equalTo: previewContainer.centerXAnchor),
            previewGrid.centerYAnchor.constraint(equalTo: previewContainer.centerYAnchor),
            previewGrid.widthAnchor.constraint(equalTo: previewContainer.widthAnchor, constant: -16),
            previewGrid.heightAnchor.constraint(equalToConstant: 160),
            
            tableView.topAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        keyStyleSegment.selectedSegmentIndex = currentTheme.keyStyle
        keyStyleSegment.addTarget(self, action: #selector(settingChanged), for: .valueChanged)
        
        buttonShapeSegment.selectedSegmentIndex = currentTheme.buttonShape ?? 0
        buttonShapeSegment.addTarget(self, action: #selector(settingChanged), for: .valueChanged)
        
        opacitySlider.minimumValue = 0.0
        opacitySlider.maximumValue = 1.0
        opacitySlider.value = Float(currentTheme.keyOpacity ?? 1.0)
        opacitySlider.addTarget(self, action: #selector(opacityChanged), for: .valueChanged)
        
        nameField.text = currentTheme.name
        nameField.placeholder = "Theme Name"
        nameField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)
    }
    
    @objc private func nameChanged() {
        currentTheme.name = nameField.text
    }
    
    @objc private func opacityChanged() {
        currentTheme.keyOpacity = CGFloat(opacitySlider.value)
        updatePreview()
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
        let radius: CGFloat = shape == 0 ? 5 : (shape == 1 ? 22 : 0)
        let opacity = currentTheme.keyOpacity ?? 1.0
        
        let defaultBorderCol = UIColor.white.withAlphaComponent(0.3).cgColor
        let borderCol = currentTheme.keyBorderColorHex != nil ? (UIColor(hex: currentTheme.keyBorderColorHex!)?.cgColor ?? defaultBorderCol) : defaultBorderCol
        
        let defaultTextCol = UIColor.label
        let textCol = currentTheme.textColorHex != nil ? (UIColor(hex: currentTheme.textColorHex!) ?? defaultTextCol) : defaultTextCol
        
        let defaultKeyBgCol = UIColor.white
        let keyBgCol = currentTheme.keyColorHex != nil ? (UIColor(hex: currentTheme.keyColorHex!) ?? defaultKeyBgCol) : defaultKeyBgCol
        
        let clearBgAlpha = 0.15 * opacity
        
        for row in previewGrid.arrangedSubviews {
            if let stack = row as? UIStackView {
                for v in stack.arrangedSubviews {
                    v.subviews.filter { $0 is UIVisualEffectView }.forEach { $0.removeFromSuperview() }
                    
                    if let label = v.viewWithTag(777) as? UILabel {
                        label.textColor = textCol
                    }
                    
                    v.layer.cornerRadius = radius
                    
                    if currentTheme.keyStyle == 1 || currentTheme.keyStyle == 3 {
                        v.backgroundColor = currentTheme.keyStyle == 3 ? UIColor.white.withAlphaComponent(clearBgAlpha) : .clear
                        v.layer.shadowOpacity = 0
                        v.layer.borderWidth = 0.5
                        v.layer.borderColor = borderCol
                        
                        if currentTheme.keyStyle == 1 {
                            let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                            blur.layer.cornerRadius = radius
                            blur.layer.borderWidth = 0.5
                            blur.layer.borderColor = borderCol
                            blur.clipsToBounds = true
                            blur.translatesAutoresizingMaskIntoConstraints = false
                            blur.alpha = opacity
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
                        v.layer.borderColor = borderCol
                    } else {
                        v.backgroundColor = keyBgCol
                        v.layer.shadowOpacity = 0.3
                        v.layer.borderWidth = 0
                    }
                }
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
    
    func numberOfSections(in tableView: UITableView) -> Int { return 5 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 { return 2 }
        if section == 3 { return 1 } // Opacity
        if section == 4 { return 3 } // Colors
        return 1
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
        if section == 0 { return isEn ? "Name" : "テーマ名" }
        if section == 1 { return isEn ? "Background" : "背景画像" }
        if section == 2 { return isEn ? "Key Style & Shape" : "キースタイル & 形状" }
        if section == 3 { return isEn ? "Transparency" : "透過度" }
        return isEn ? "Colors" : "色設定"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
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
        } else if indexPath.section == 2 {
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
        } else if indexPath.section == 3 {
            let stack = UIStackView(arrangedSubviews: [opacitySlider])
            stack.axis = .vertical
            stack.spacing = 8
            stack.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                stack.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                stack.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
                stack.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12)
            ])
        } else if indexPath.section == 4 {
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
            if indexPath.row == 0 {
                cell.textLabel?.text = isEn ? "Text Color" : "テキストの色"
                if let hex = currentTheme.textColorHex {
                    cell.detailTextLabel?.text = "■"
                    cell.detailTextLabel?.textColor = UIColor(hex: hex)
                } else {
                    cell.detailTextLabel?.text = isEn ? "Default" : "デフォルト"
                }
            } else if indexPath.row == 1 {
                cell.textLabel?.text = isEn ? "Border Color" : "フチの色"
                if let hex = currentTheme.keyBorderColorHex {
                    cell.detailTextLabel?.text = "■"
                    cell.detailTextLabel?.textColor = UIColor(hex: hex)
                } else {
                    cell.detailTextLabel?.text = isEn ? "Default" : "デフォルト"
                }
            } else if indexPath.row == 2 {
                cell.textLabel?.text = isEn ? "Key Background Color" : "キーの背景色 (標準用)"
                if let hex = currentTheme.keyColorHex {
                    cell.detailTextLabel?.text = "■"
                    cell.detailTextLabel?.textColor = UIColor(hex: hex)
                } else {
                    cell.detailTextLabel?.text = isEn ? "Default" : "デフォルト"
                }
            }
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
        } else if indexPath.section == 4 {
            let picker = UIColorPickerViewController()
            picker.delegate = self
            picker.supportsAlpha = true
            
            if indexPath.row == 0 {
                pickingColorFor = "text"
                picker.selectedColor = currentTheme.textColorHex != nil ? (UIColor(hex: currentTheme.textColorHex!) ?? .label) : .label
            } else if indexPath.row == 1 {
                pickingColorFor = "border"
                picker.selectedColor = currentTheme.keyBorderColorHex != nil ? (UIColor(hex: currentTheme.keyBorderColorHex!) ?? .white) : .white
            } else if indexPath.row == 2 {
                pickingColorFor = "keyBg"
                picker.selectedColor = currentTheme.keyColorHex != nil ? (UIColor(hex: currentTheme.keyColorHex!) ?? .white) : .white
            }
            present(picker, animated: true)
        }
    }
    
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        let color = viewController.selectedColor
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let hexStr: String
        if a < 1.0 {
            hexStr = String(format: "#%02lX%02lX%02lX%02lX", lroundf(Float(a * 255)), lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        } else {
            hexStr = String(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        }
        
        if pickingColorFor == "text" {
            currentTheme.textColorHex = hexStr
        } else if pickingColorFor == "border" {
            currentTheme.keyBorderColorHex = hexStr
        } else if pickingColorFor == "keyBg" {
            currentTheme.keyColorHex = hexStr
        }
        updatePreview()
        tableView.reloadData()
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

new_content = content[:start_idx] + new_class + content[end_idx:]

with open(file_path, "w") as f:
    f.write(new_content)
