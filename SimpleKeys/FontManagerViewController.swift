import UIKit

class FontManagerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIDocumentPickerDelegate {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var customFonts: [CustomFont] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
        title = isEn ? "Manage Fonts" : "フォント管理"
        view.backgroundColor = .systemGroupedBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addFontTapped))
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        loadFonts()
    }
    
    private func loadFonts() {
        customFonts = CustomFontManager.shared.getCustomFonts()
        tableView.reloadData()
    }
    
    @objc private func addFontTapped() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.font, .data])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }
    
    // MARK: - UIDocumentPickerDelegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
        
        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        CustomFontManager.shared.importFont(from: url) { [weak self] fontName, errorStr in
            DispatchQueue.main.async {
                if let err = errorStr {
                    let alert = UIAlertController(title: isEn ? "Error" : "エラー", message: err, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                } else {
                    self?.loadFonts()
                }
            }
        }
    }
    
    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return customFonts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let font = customFonts[indexPath.row]
        cell.textLabel?.text = font.displayName
        cell.detailTextLabel?.text = font.fontName
        if let uiFont = UIFont(name: font.fontName, size: 16) {
            cell.textLabel?.font = uiFont
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let font = customFonts[indexPath.row]
        let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
        
        let alert = UIAlertController(title: isEn ? "Rename Font" : "フォント名変更", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.text = font.displayName
        }
        alert.addAction(UIAlertAction(title: isEn ? "Cancel" : "キャンセル", style: .cancel))
        alert.addAction(UIAlertAction(title: isEn ? "Save" : "保存", style: .default, handler: { [weak self] _ in
            if let newName = alert.textFields?.first?.text, !newName.isEmpty {
                CustomFontManager.shared.setDisplayName(newName, forFont: font.fontName)
                self?.loadFonts()
            }
        }))
        present(alert, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let font = customFonts[indexPath.row]
            CustomFontManager.shared.removeFont(font)
            customFonts.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}
