
import UIKit
import AVFoundation
import AudioToolbox

// MARK: - Models
struct UpdateInfo: Codable {
    let latest_version: String
    let updates: [UpdateItem]
}
struct UpdateItem: Codable {
    let version: String
    let date: String
    let title: String
    let body: String
}

// MARK: - Main Tab Bar
class ViewController: UITabBarController {
    let updatesVC = UpdatesViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let lang = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") ?? "ja"
        let isEn = lang == "en"
        
        let settingsVC = UINavigationController(rootViewController: SettingsViewController())
        settingsVC.tabBarItem = UITabBarItem(title: isEn ? "Settings" : "設定", image: UIImage(systemName: "gearshape.fill"), tag: 0)
        
        let updatesNav = UINavigationController(rootViewController: updatesVC)
        updatesNav.tabBarItem = UITabBarItem(title: isEn ? "Updates" : "アップデート情報", image: UIImage(systemName: "bell.fill"), tag: 1)
        
        viewControllers = [settingsVC, updatesNav]
        tabBar.tintColor = .systemBlue
        
        checkForUpdates()
    }
    
    func checkForUpdates() {
        let lang = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") ?? "ja"
        let urlString = "https://raw.githubusercontent.com/kotaaaaaaaa12/SimpleKeys/main/updates_\(lang).json"
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.updatesVC.showError("Invalid URL: \(urlString)")
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.updatesVC.showError("Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.updatesVC.showError("No HTTP response received.")
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    self?.updatesVC.showError("HTTP \(httpResponse.statusCode) from \(urlString)")
                    return
                }
                
                guard let data = data else {
                    self?.updatesVC.showError("No data received.")
                    return
                }
                
                do {
                    let updateInfo = try JSONDecoder().decode(UpdateInfo.self, from: data)
                    self?.updatesVC.updates = updateInfo.updates
                    self?.updatesVC.errorMessage = nil
                    self?.updatesVC.tableView.reloadData()
                    
                    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                    if updateInfo.latest_version.compare(currentVersion, options: .numeric) == .orderedDescending {
                        self?.tabBar.items?[1].badgeValue = "1"
                    } else {
                        self?.tabBar.items?[1].badgeValue = nil
                    }
                } catch {
                    self?.updatesVC.showError("JSON decode error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
}

// MARK: - Settings
class SettingsViewController: UITableViewController {
    
    private let flickSwitch = UISwitch()
    private let qwertyEnglishSwitch = UISwitch()
    private let qwertyRomajiSwitch = UISwitch()
    private let flickAlphabetQwertySwitch = UISwitch()
    private let flickOnlySwitch = UISwitch()
    private let oneHandedSegment = UISegmentedControl(items: ["左", "オフ", "右"])
    
    private let geminiSwitch = UISwitch()
    private let geminiApiKeyField: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .roundedRect
        tf.isSecureTextEntry = true
        tf.returnKeyType = .done
        return tf
    }()
    
    private let geminiModelField: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .roundedRect
        tf.returnKeyType = .done
        return tf
    }()
    
    private let languageSegment = UISegmentedControl(items: ["日本語", "English"])
    
    private let sharedDefaults = AppGroupHelper.shared.userDefaults

    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "SimpleKeys"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        setupControls()
        loadSettings()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkKeyboardEnabled()
    }
    
    private func checkKeyboardEnabled() {
        let hasLaunched = sharedDefaults?.bool(forKey: "keyboardHasLaunched") ?? false
        
        if !hasLaunched {
            let isEn = languageSegment.selectedSegmentIndex == 1
            let alert = UIAlertController(
                title: isEn ? "Setup Required" : "キーボードの設定",
                message: isEn ? "SimpleKeys keyboard has not been added yet. Please go to Settings > General > Keyboard > Keyboards > Add New Keyboard and add SimpleKeys." : "SimpleKeysキーボードがまだ追加されていません。設定 > 一般 > キーボード > キーボード > 新しいキーボードを追加 からSimpleKeysを追加してください。",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: isEn ? "Later" : "あとで", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: isEn ? "Open Settings" : "設定を開く", style: .default, handler: { _ in
                if let url = URL(string: "App-prefs:General&path=Keyboard/KEYBOARDS") {
                    UIApplication.shared.open(url)
                }
            }))
            self.present(alert, animated: true)
        }
    }
    
    private func setupControls() {
        flickSwitch.addTarget(self, action: #selector(settingsChanged), for: .valueChanged)
        flickAlphabetQwertySwitch.addTarget(self, action: #selector(settingsChanged), for: .valueChanged)
        flickOnlySwitch.addTarget(self, action: #selector(settingsChanged), for: .valueChanged)
        oneHandedSegment.addTarget(self, action: #selector(settingsChanged), for: .valueChanged)
        qwertyEnglishSwitch.addTarget(self, action: #selector(settingsChanged), for: .valueChanged)
        qwertyRomajiSwitch.addTarget(self, action: #selector(settingsChanged), for: .valueChanged)
        languageSegment.addTarget(self, action: #selector(languageChanged), for: .valueChanged)
        
        geminiSwitch.addTarget(self, action: #selector(settingsChanged), for: .valueChanged)
        geminiApiKeyField.addTarget(self, action: #selector(apiKeyChanged), for: .editingChanged)
        geminiApiKeyField.delegate = self
        
        geminiModelField.addTarget(self, action: #selector(modelChanged), for: .editingChanged)
        geminiModelField.delegate = self
    }
    
    private func loadSettings() {
        let defaults = sharedDefaults
        flickSwitch.isOn = defaults?.object(forKey: "enableFlick") == nil ? true : defaults?.bool(forKey: "enableFlick") ?? true
        flickAlphabetQwertySwitch.isOn = defaults?.bool(forKey: "flickAlphabetIsQwerty") ?? false
        flickOnlySwitch.isOn = defaults?.bool(forKey: "flickOnly") ?? false
        
        let ohMode = defaults?.string(forKey: "oneHandedMode") ?? "off"
        oneHandedSegment.selectedSegmentIndex = ohMode == "left" ? 0 : (ohMode == "right" ? 2 : 1)
        
        qwertyEnglishSwitch.isOn = defaults?.object(forKey: "enableQwertyEnglish") == nil ? true : defaults?.bool(forKey: "enableQwertyEnglish") ?? true
        qwertyRomajiSwitch.isOn = defaults?.object(forKey: "enableQwertyRomaji") == nil ? true : defaults?.bool(forKey: "enableQwertyRomaji") ?? true
        
        let lang = defaults?.string(forKey: "appLanguage") ?? "ja"
        languageSegment.selectedSegmentIndex = lang == "en" ? 1 : 0
        
        geminiSwitch.isOn = defaults?.bool(forKey: "enableGemini") ?? false
        geminiApiKeyField.text = defaults?.string(forKey: "geminiApiKey")
        let savedModel = defaults?.string(forKey: "geminiModel")
        geminiModelField.text = (savedModel != nil && !savedModel!.isEmpty) ? savedModel : "gemini-3.5-flash"
    }
    
    @objc private func settingsChanged() {
        if !flickSwitch.isOn && !qwertyEnglishSwitch.isOn && !qwertyRomajiSwitch.isOn {
            flickSwitch.isOn = true
            tableView.reloadData()
        }
        
        sharedDefaults?.set(flickSwitch.isOn, forKey: "enableFlick")
        sharedDefaults?.set(flickAlphabetQwertySwitch.isOn, forKey: "flickAlphabetIsQwerty")
        sharedDefaults?.set(flickOnlySwitch.isOn, forKey: "flickOnly")
        
        let ohMode = oneHandedSegment.selectedSegmentIndex == 0 ? "left" : (oneHandedSegment.selectedSegmentIndex == 2 ? "right" : "off")
        sharedDefaults?.set(ohMode, forKey: "oneHandedMode")
        
        sharedDefaults?.set(qwertyEnglishSwitch.isOn, forKey: "enableQwertyEnglish")
        sharedDefaults?.set(qwertyRomajiSwitch.isOn, forKey: "enableQwertyRomaji")
        sharedDefaults?.set(geminiSwitch.isOn, forKey: "enableGemini")
        sharedDefaults?.synchronize()
    }
    
    @objc private func apiKeyChanged() {
        sharedDefaults?.set(geminiApiKeyField.text, forKey: "geminiApiKey")
        sharedDefaults?.synchronize()
    }
    
    @objc private func modelChanged() {
        sharedDefaults?.set(geminiModelField.text, forKey: "geminiModel")
        sharedDefaults?.synchronize()
    }
    
    @objc private func languageChanged() {
        let lang = languageSegment.selectedSegmentIndex == 0 ? "ja" : "en"
        sharedDefaults?.set(lang, forKey: "appLanguage")
        sharedDefaults?.synchronize()
        
        tableView.reloadData()
        
        if let tabBarVC = tabBarController as? ViewController {
            let isEn = lang == "en"
            tabBarVC.tabBar.items?[0].title = isEn ? "Settings" : "設定"
            tabBarVC.tabBar.items?[1].title = isEn ? "Updates" : "お知らせ"
            oneHandedSegment.setTitle(isEn ? "Left" : "左", forSegmentAt: 0)
            oneHandedSegment.setTitle(isEn ? "Off" : "オフ", forSegmentAt: 1)
            oneHandedSegment.setTitle(isEn ? "Right" : "右", forSegmentAt: 2)
            tabBarVC.checkForUpdates()
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int { return 8 }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 1
        case 2: return 3
        case 3: return 3
        case 4: return 3
        case 5: return 1
        case 6: return 3
        case 7: return 3
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let isEn = languageSegment.selectedSegmentIndex == 1
        switch section {
        case 0: return isEn ? "Language" : "言語設定"
        case 1: return isEn ? "How to use" : "使い方"
        case 2: return isEn ? "Keyboard Modes" : "有効にする入力モード"
        case 3: return isEn ? "Flick Settings" : "フリック入力の詳細設定"
        case 4: return isEn ? "AI Conversion (Gemini)" : "AI変換設定 (Gemini)"
        case 5: return isEn ? "User Dictionary" : "ユーザー辞書"
        case 6: return isEn ? "Customization" : "カスタマイズ"
        case 7: return isEn ? "Coming Soon" : "開発中の機能 (Coming Soon)"
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let isEn = languageSegment.selectedSegmentIndex == 1
        switch section {
        case 1: return isEn ? "Go to Settings > General > Keyboard, add SimpleKeys, and Allow Full Access." : "設定アプリからキーボードを追加し、「フルアクセスを許可」をオンにしてください。"
        case 4: return isEn ? "Enter your Gemini API key to use cloud AI conversion. This requires Full Access." : "AI変換を利用するには、Gemini APIキーを入力してください（フルアクセス許可が必要です）。"
        case 5: return isEn ? "Register custom words for faster conversion." : "よく使う単語や特殊な変換を登録できます。"
        case 7: return isEn ? "These features will be available in future updates." : "これらの機能は今後のアップデートで追加される予定です。"
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        let isEn = languageSegment.selectedSegmentIndex == 1
        
        if indexPath.section == 0 {
            cell.contentView.addSubview(languageSegment)
            languageSegment.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                languageSegment.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                languageSegment.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                languageSegment.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16)
            ])
        } else if indexPath.section == 1 {
            cell.textLabel?.text = isEn ? "Settings > General > Keyboard > Keyboards > Add New Keyboard" : "設定 > 一般 > キーボード > キーボード > 新しいキーボードを追加"
            cell.textLabel?.numberOfLines = 0
            cell.detailTextLabel?.text = isEn ? "Tap here to open Settings app" : "ここをタップして設定アプリを開く"
            cell.detailTextLabel?.textColor = .systemBlue
            cell.imageView?.image = UIImage(systemName: "arrow.up.right.square")
            cell.imageView?.tintColor = .systemBlue
        } else if indexPath.section == 2 {
            if indexPath.row == 0 {
                cell.textLabel?.text = isEn ? "Flick Input (Kana)" : "フリック入力 (Kana/ABC/123)"
                cell.detailTextLabel?.text = isEn ? "Use Japanese flick layout" : "日本語のフリック入力を使用します"
                cell.accessoryView = flickSwitch
                cell.imageView?.image = UIImage(systemName: "hand.point.up.left.fill")
                cell.imageView?.tintColor = .systemGreen
            } else if indexPath.row == 1 {
                cell.textLabel?.text = isEn ? "QWERTY (English)" : "QWERTY (英語)"
                cell.detailTextLabel?.text = isEn ? "Standard English layout" : "標準的な英語キーボードを使用します"
                cell.accessoryView = qwertyEnglishSwitch
                cell.imageView?.image = UIImage(systemName: "keyboard")
                cell.imageView?.tintColor = .systemBlue
            } else if indexPath.row == 2 {
                cell.textLabel?.text = isEn ? "QWERTY (Romaji)" : "QWERTY (ローマ字)"
                cell.detailTextLabel?.text = isEn ? "Japanese Romaji layout" : "ローマ字入力で日本語を入力します"
                cell.accessoryView = qwertyRomajiSwitch
                cell.imageView?.image = UIImage(systemName: "textformat.alt")
                cell.imageView?.tintColor = .systemRed
            }
        } else if indexPath.section == 3 {
            if indexPath.row == 0 {
                let picker = UIColorPickerViewController()
                picker.delegate = self
                picker.supportsAlpha = true
                pickingColorFor = "border"
                picker.selectedColor = currentTheme.keyBorderColorHex != nil ? (UIColor(hex: currentTheme.keyBorderColorHex!) ?? .black) : .black
                present(picker, animated: true)
            } else if indexPath.row == 2 {
                let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
                let alert = UIAlertController(title: isEn ? "Border Style" : "フチの種類", message: nil, preferredStyle: .actionSheet)
                let stylesEn = ["Solid", "Dashed", "Dotted", "Double", "Dash-Dot", "Dash-Dot-Dot"]
                let stylesJa = ["実線", "破線", "点線", "二重線", "一点鎖線", "二点鎖線"]
                for i in 0..<stylesEn.count {
                    let action = UIAlertAction(title: isEn ? stylesEn[i] : stylesJa[i], style: .default) { [weak self] _ in
                        self?.currentTheme.keyBorderStyle = i
                        self?.updatePreview()
                        self?.tableView.reloadData()
                    }
                    if (currentTheme.keyBorderStyle ?? 0) == i { action.setValue(true, forKey: "checked") }
                    alert.addAction(action)
                }
                alert.addAction(UIAlertAction(title: isEn ? "Cancel" : "キャンセル", style: .cancel))
                if let popover = alert.popoverPresentationController {
                    popover.sourceView = tableView.cellForRow(at: indexPath)
                    popover.sourceRect = tableView.cellForRow(at: indexPath)?.bounds ?? .zero
                }
                present(alert, animated: true)
            }
        } else if indexPath.section == 5 {
            let picker = UIColorPickerViewController()
            picker.delegate = self
            picker.supportsAlpha = true
            
            if indexPath.row == 0 {
                pickingColorFor = "text"
                picker.selectedColor = currentTheme.textColorHex != nil ? (UIColor(hex: currentTheme.textColorHex!) ?? .black) : .black
            } else if indexPath.row == 1 {
                pickingColorFor = "keyBg"
                picker.selectedColor = currentTheme.keyColorHex != nil ? (UIColor(hex: currentTheme.keyColorHex!) ?? .white) : .white
            }
            present(picker, animated: true)
        } else if indexPath.section == 6 {
            if indexPath.row > 2 {
                cell.textLabel?.textColor = .secondaryLabel
                cell.detailTextLabel?.textColor = .tertiaryLabel
                cell.imageView?.tintColor = .systemGray
            }
            
            if indexPath.row == 0 {
                cell.textLabel?.text = isEn ? "Custom Themes" : "カスタムテーマ"
                cell.detailTextLabel?.text = isEn ? "Customize background color and images" : "背景色や画像を自由に設定できます"
                cell.imageView?.image = UIImage(systemName: "paintpalette.fill")
                cell.accessoryType = .disclosureIndicator
            } else if indexPath.row == 1 {
                cell.textLabel?.text = isEn ? "Manage Fonts" : "フォント管理"
                cell.detailTextLabel?.text = isEn ? "Install and manage custom fonts" : "カスタムフォントの追加や管理ができます"
                cell.imageView?.image = UIImage(systemName: "textformat")
                cell.accessoryType = .disclosureIndicator
            } else if indexPath.row == 2 {
                cell.textLabel?.text = isEn ? "Feedback & Cursor Settings" : "音・振動・カーソル感度のカスタマイズ"
                cell.detailTextLabel?.text = isEn ? "Fine-tune sound, vibration and cursor speed" : "キー音、振動、カーソル移動のスピードを調整"
                cell.imageView?.image = UIImage(systemName: "slider.horizontal.3")
                cell.accessoryType = .disclosureIndicator
            }
        } else if indexPath.section == 7 {
            if indexPath.row == 0 {
                cell.textLabel?.text = isEn ? "Real-time AI Translation" : "AIリアルタイム翻訳＆トーン変換"
                cell.detailTextLabel?.text = isEn ? "Translate or change text tone instantly" : "入力中のテキストを自動翻訳したり、敬語などに変換します"
                cell.imageView?.image = UIImage(systemName: "character.bubble.fill")
            } else if indexPath.row == 1 {
                cell.textLabel?.text = isEn ? "Clipboard & Snippets" : "クリップボード履歴＆定型文ボード"
                cell.detailTextLabel?.text = isEn ? "Access copy history and quick phrases" : "過去のコピー履歴やよく使う定型文をワンタップで入力"
                cell.imageView?.image = UIImage(systemName: "doc.on.clipboard.fill")
            } else if indexPath.row == 2 {
                cell.textLabel?.text = isEn ? "AI Emoji Suggestion" : "AI文脈絵文字・顔文字サジェスト"
                cell.detailTextLabel?.text = isEn ? "Smart emoji suggestions based on context" : "文章の感情に合わせて最適な絵文字・顔文字をAIが提案"
                cell.imageView?.image = UIImage(systemName: "face.smiling.fill")
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            tableView.deselectRow(at: indexPath, animated: true)
            if let url = URL(string: "App-prefs:General&path=Keyboard/KEYBOARDS") {
                UIApplication.shared.open(url)
            }
        } else if indexPath.section == 5 {
            let picker = UIColorPickerViewController()
            picker.delegate = self
            picker.supportsAlpha = true
            
            if indexPath.row == 0 {
                pickingColorFor = "text"
                picker.selectedColor = currentTheme.textColorHex != nil ? (UIColor(hex: currentTheme.textColorHex!) ?? .black) : .black
            } else if indexPath.row == 1 {
                pickingColorFor = "keyBg"
                picker.selectedColor = currentTheme.keyColorHex != nil ? (UIColor(hex: currentTheme.keyColorHex!) ?? .white) : .white
            }
            present(picker, animated: true)
        } else if indexPath.section == 6 {
            if indexPath.row == 0 {
                tableView.deselectRow(at: indexPath, animated: true)
                let vc = MyThemesViewController(style: .insetGrouped)
                navigationController?.pushViewController(vc, animated: true)
            } else if indexPath.row == 1 {
                tableView.deselectRow(at: indexPath, animated: true)
                let vc = FontManagerViewController()
                navigationController?.pushViewController(vc, animated: true)
            } else if indexPath.row == 2 {
                tableView.deselectRow(at: indexPath, animated: true)
                let vc = HapticsSensitivityViewController()
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}

extension SettingsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Updates
class UpdatesViewController: UITableViewController {
    
    var updates: [UpdateItem] = []
    var errorMessage: String? = nil
    
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let lang = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") ?? "ja"
        title = lang == "en" ? "Updates" : "アップデート情報"
        
        // Remove badge when viewed
        tabBarController?.tabBar.items?[1].badgeValue = nil
    }
    
    func showError(_ message: String) {
        errorMessage = message
        updates = []
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if errorMessage != nil { return 1 }
        if updates.isEmpty { return 1 }
        return updates.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if errorMessage != nil { return "⚠️ Error" }
        if updates.isEmpty { return nil }
        return updates[section].title
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if errorMessage != nil || updates.isEmpty { return nil }
        return updates[section].date
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = .systemFont(ofSize: 15)
        
        if let error = errorMessage {
            cell.textLabel?.text = error
            cell.textLabel?.textColor = .systemRed
        } else if updates.isEmpty {
            let lang = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") ?? "ja"
            cell.textLabel?.text = lang == "en" ? "Loading..." : "読み込み中..."
            cell.textLabel?.textColor = .secondaryLabel
        } else {
            cell.textLabel?.text = updates[indexPath.section].body
            cell.textLabel?.textColor = .label
        }
        
        return cell
    }
}


// MARK: - User Dictionary
struct UserDictItem: Codable {
    var yomi: String
    var kaki: String
}

class UserDictionaryViewController: UITableViewController {
    private var dictionary: [UserDictItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
        title = isEn ? "User Dictionary" : "ユーザー辞書"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        loadDictionary()
    }
    
    private func loadDictionary() {
        if let data = AppGroupHelper.shared.userDefaults?.data(forKey: "userDictionary"),
           let items = try? JSONDecoder().decode([UserDictItem].self, from: data) {
            dictionary = items
        }
        tableView.reloadData()
    }
    
    private func saveDictionary() {
        if let data = try? JSONEncoder().encode(dictionary) {
            AppGroupHelper.shared.userDefaults?.set(data, forKey: "userDictionary")
            AppGroupHelper.shared.userDefaults?.synchronize()
        }
    }
    
    @objc private func addButtonTapped() {
        showEditAlert(for: nil, at: nil)
    }
    
    private func showEditAlert(for item: UserDictItem?, at index: Int?) {
        let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
        let alertTitle = item == nil ? (isEn ? "Add Word" : "単語の登録") : (isEn ? "Edit Word" : "単語の編集")
        let alert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = isEn ? "Reading (e.g. btw)" : "よみ (例: おつ)"
            tf.text = item?.yomi
        }
        alert.addTextField { tf in
            tf.placeholder = isEn ? "Word (e.g. By the way)" : "単語 (例: お疲れ様です！)"
            tf.text = item?.kaki
        }
        
        let saveAction = UIAlertAction(title: isEn ? "Save" : "保存", style: .default) { [weak self] _ in
            guard let self = self,
                  let yomi = alert.textFields?[0].text, !yomi.isEmpty,
                  let kaki = alert.textFields?[1].text, !kaki.isEmpty else { return }
            
            let newItem = UserDictItem(yomi: yomi, kaki: kaki)
            if let index = index {
                self.dictionary[index] = newItem
            } else {
                self.dictionary.append(newItem)
            }
            self.saveDictionary()
            self.tableView.reloadData()
        }
        
        alert.addAction(UIAlertAction(title: isEn ? "Cancel" : "キャンセル", style: .cancel))
        alert.addAction(saveAction)
        present(alert, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dictionary.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        let item = dictionary[indexPath.row]
        cell.textLabel?.text = item.kaki
        cell.detailTextLabel?.text = item.yomi
        cell.detailTextLabel?.textColor = .secondaryLabel
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showEditAlert(for: dictionary[indexPath.row], at: indexPath.row)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            dictionary.remove(at: indexPath.row)
            saveDictionary()
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        let lang = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") ?? "ja"
        return lang == "en" ? "Delete" : "削除"
    }
}

// MARK: - My Themes & Editor
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
        let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
        if let data = AppGroupHelper.shared.userDefaults?.data(forKey: ThemeSettings.themesArrayKey),
           let saved = try? JSONDecoder().decode([ThemeSettings].self, from: data) {
            themes = saved
        }
        if themes.isEmpty {
            var defaultTheme = ThemeSettings(keyStyle: 0)
            defaultTheme.id = UUID().uuidString
            defaultTheme.name = isEn ? "Default" : "デフォルト"
            themes.append(defaultTheme)
            saveThemes()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let defaults = AppGroupHelper.shared.userDefaults
        if let crashLog = defaults?.string(forKey: "lastCrashLog") {
            let alert = UIAlertController(title: "Crash Detected", message: crashLog, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Copy & Clear", style: .default, handler: { _ in
                UIPasteboard.general.string = crashLog
                defaults?.removeObject(forKey: "lastCrashLog")
                defaults?.synchronize()
            }))
            alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
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
        let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
        
        cell.textLabel?.text = theme.name ?? (isEn ? "Untitled Theme" : "無題のテーマ")
        
        let styles = isEn ? ["Standard", "Frosted Glass", "Flat", "Clear Glass"] : ["標準", "磨りガラス", "フラット", "クリアガラス"]
        let styleName = (theme.keyStyle >= 0 && theme.keyStyle < styles.count) ? styles[theme.keyStyle] : (isEn ? "Unknown" : "不明")
        cell.detailTextLabel?.text = isEn ? "Style: \(styleName)" : "スタイル: \(styleName)"
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
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row != 0 // Prevent deleting the default theme
    }
    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
        return isEn ? "Delete" : "削除"
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            themes.remove(at: indexPath.row)
            saveThemes()
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}

class ThemeEditorViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIColorPickerViewControllerDelegate {
    var theme: ThemeSettings?
    var onSave: ((ThemeSettings) -> Void)?
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let previewContainer = UIView()
    
    private var currentTheme = ThemeSettings(keyStyle: 0)
    
    private let nameField = UITextField()
    private let opacitySlider = UISlider()
    
    private var pickingColorFor: String?
    
    private let keyboardVC = KeyboardViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
        title = isEn ? "Edit Theme" : "テーマ編集"
        view.backgroundColor = .systemGroupedBackground
        
        CustomFontManager.shared.registerAllCustomFonts()
        navigationController?.navigationBar.prefersLargeTitles = true
        
        keyboardVC.isPreviewMode = true
        
        if let t = theme {
            currentTheme = t
        } else {
            currentTheme.id = UUID().uuidString
            currentTheme.name = isEn ? "Custom Theme" : "カスタムテーマ"
            currentTheme.keyOpacity = 1.0
        }
        
        if currentTheme.keyOpacity == nil {
            currentTheme.keyOpacity = 1.0
        }
        
        setupUI()
        updatePreview()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: isEn ? "Save" : "保存", style: .done, target: self, action: #selector(saveTapped))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    private func setupUI() {
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.backgroundColor = .systemGray5
        previewContainer.layer.cornerRadius = 12
        previewContainer.clipsToBounds = true
        view.addSubview(previewContainer)
        
        addChild(keyboardVC)
        keyboardVC.view.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.addSubview(keyboardVC.view)
        keyboardVC.didMove(toParent: self)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            previewContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            previewContainer.heightAnchor.constraint(equalToConstant: 260),
            
            keyboardVC.view.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            keyboardVC.view.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),
            keyboardVC.view.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            keyboardVC.view.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        opacitySlider.minimumValue = 0.0
        opacitySlider.maximumValue = 1.0
        opacitySlider.value = Float(currentTheme.keyOpacity ?? 1.0)
        opacitySlider.addTarget(self, action: #selector(opacityChanged), for: .valueChanged)
        
        nameField.text = currentTheme.name
        nameField.placeholder = "Theme Name"
        nameField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)
    }
    
    private func updatePreview() {
        keyboardVC.previewTheme = currentTheme
        keyboardVC.updatePreviewTheme()
    }

    @objc private func nameChanged() {
        currentTheme.name = nameField.text
    }
    
    @objc private func opacityChanged() {
        currentTheme.keyOpacity = CGFloat(opacitySlider.value)
        updatePreview()
    }
    
    @objc private func borderWidthChanged(_ sender: UISlider) {
        currentTheme.keyBorderWidth = CGFloat(sender.value)
        updatePreview()
    }
    
    @objc private func flickBorderWidthChanged(_ sender: UISlider) {
        currentTheme.flickPopupBorderWidth = CGFloat(sender.value)
        updatePreview()
    }
    
    
    @objc private func saveTapped() {
        if currentTheme.name == nil || currentTheme.name!.isEmpty {
            let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
            currentTheme.name = isEn ? "Custom Theme" : "カスタムテーマ"
        }
        onSave?(currentTheme)
        navigationController?.popViewController(animated: true)
    }
    
    func isVideoBackground() -> Bool {
        guard let bgFile = currentTheme.backgroundImageFileName else { return false }
        let ext = (bgFile as NSString).pathExtension.lowercased()
        return ext == "mp4" || ext == "mov" || ext == "m4v"
    }

    func numberOfSections(in tableView: UITableView) -> Int { return 8 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 { return isVideoBackground() ? 3 : 2 }
        if section == 2 { return 2 } // Key Style and Button Shape
        if section == 3 { return 3 } // Border Color, Width, and Style
        if section == 4 { return 1 } // Opacity
        if section == 5 { return currentTheme.keyStyle == 0 ? 2 : 1 } // Colors
        if section == 6 { return 1 } // Font
        if section == 7 { return 7 } // Flick popup bg, text, highlight, border col, border width, border style, shape
        return 1
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
        if section == 0 { return isEn ? "Name" : "テーマ名" }
        if section == 1 { return isEn ? "Background Media" : "背景メディア" }
        if section == 2 { return isEn ? "Key Style & Shape" : "キースタイル & 形状" }
        if section == 3 { return isEn ? "Border Settings" : "ボタンのフチの設定" }
        if section == 4 { return isEn ? "Transparency" : "透過度" }
        if section == 5 { return isEn ? "Colors" : "色設定" }
        if section == 6 { return isEn ? "Font" : "フォント" }
        return isEn ? "Flick Popup" : "フリック吹き出し"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
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
                cell.textLabel?.text = isEn ? "Choose Media" : "メディアを選択"
                cell.accessoryType = .disclosureIndicator
            } else if indexPath.row == 1 {
                cell.textLabel?.text = isEn ? "Remove Media" : "メディアを削除"
                cell.textLabel?.textColor = .systemRed
            } else if indexPath.row == 2 {
                cell.textLabel?.text = isEn ? "Video Audio" : "動画の音声"
                cell.textLabel?.textColor = .label
                cell.selectionStyle = .none
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
                let toggle = UISwitch()
                toggle.isOn = currentTheme.videoAudioEnabled ?? false
                toggle.addTarget(self, action: #selector(videoAudioToggled(_:)), for: .valueChanged)
                cell.accessoryView = toggle
            }
        } else if indexPath.section == 2 {
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
            if indexPath.row == 0 {
                cell.textLabel?.text = isEn ? "Key Style" : "キースタイル"
                let style = currentTheme.keyStyle
                let stylesEn = ["Standard", "Frosted", "Flat", "Clear"]
                let stylesJa = ["標準", "磨りガラス", "フラット", "クリア"]
                cell.detailTextLabel?.text = isEn ? stylesEn[style] : stylesJa[style]
            } else if indexPath.row == 1 {
                cell.textLabel?.text = isEn ? "Button Shape" : "ボタンの形"
                let shape = currentTheme.buttonShape ?? 0
                let shapesEn = ["Rounded", "Oval", "Rect"]
                let shapesJa = ["角丸", "楕円", "四角"]
                cell.detailTextLabel?.text = isEn ? shapesEn[shape] : shapesJa[shape]
            }
        } else if indexPath.section == 3 {
            if indexPath.row == 0 {
                let picker = UIColorPickerViewController()
                picker.delegate = self
                picker.supportsAlpha = true
                pickingColorFor = "border"
                picker.selectedColor = currentTheme.keyBorderColorHex != nil ? (UIColor(hex: currentTheme.keyBorderColorHex!) ?? .black) : .black
                present(picker, animated: true)
            } else if indexPath.row == 2 {
                let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
                let alert = UIAlertController(title: isEn ? "Border Style" : "フチの種類", message: nil, preferredStyle: .actionSheet)
                let stylesEn = ["Solid", "Dashed", "Dotted", "Double", "Dash-Dot", "Dash-Dot-Dot"]
                let stylesJa = ["実線", "破線", "点線", "二重線", "一点鎖線", "二点鎖線"]
                for i in 0..<stylesEn.count {
                    let action = UIAlertAction(title: isEn ? stylesEn[i] : stylesJa[i], style: .default) { [weak self] _ in
                        self?.currentTheme.keyBorderStyle = i
                        self?.updatePreview()
                        self?.tableView.reloadData()
                    }
                    if (currentTheme.keyBorderStyle ?? 0) == i { action.setValue(true, forKey: "checked") }
                    alert.addAction(action)
                }
                alert.addAction(UIAlertAction(title: isEn ? "Cancel" : "キャンセル", style: .cancel))
                if let popover = alert.popoverPresentationController {
                    popover.sourceView = tableView.cellForRow(at: indexPath)
                    popover.sourceRect = tableView.cellForRow(at: indexPath)?.bounds ?? .zero
                }
                present(alert, animated: true)
            }
        } else if indexPath.section == 5 {
            let picker = UIColorPickerViewController()
            picker.delegate = self
            picker.supportsAlpha = true
            
            if indexPath.row == 0 {
                pickingColorFor = "text"
                picker.selectedColor = currentTheme.textColorHex != nil ? (UIColor(hex: currentTheme.textColorHex!) ?? .black) : .black
            } else if indexPath.row == 1 {
                pickingColorFor = "keyBg"
                picker.selectedColor = currentTheme.keyColorHex != nil ? (UIColor(hex: currentTheme.keyColorHex!) ?? .white) : .white
            }
            present(picker, animated: true)
        } else if indexPath.section == 6 {
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = isEn ? "Font Family" : "フォントファミリー"
            cell.detailTextLabel?.text = currentTheme.fontName ?? (isEn ? "System Default" : "システムデフォルト")
        } else if indexPath.section == 7 {
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
            if indexPath.row == 0 {
                cell.textLabel?.text = isEn ? "Popup Background" : "吹き出しの背景色"
                if let hex = currentTheme.flickPopupBgHex {
                    cell.detailTextLabel?.text = "■"
                    cell.detailTextLabel?.textColor = UIColor(hex: hex)
                } else {
                    cell.detailTextLabel?.text = isEn ? "Default (White)" : "デフォルト（白）"
                }
            } else if indexPath.row == 1 {
                cell.textLabel?.text = isEn ? "Popup Text" : "吹き出しの文字色"
                if let hex = currentTheme.flickPopupTextHex {
                    cell.detailTextLabel?.text = "■"
                    cell.detailTextLabel?.textColor = UIColor(hex: hex)
                } else {
                    cell.detailTextLabel?.text = isEn ? "Default (Black)" : "デフォルト（黒）"
                }
            } else if indexPath.row == 2 {
                cell.textLabel?.text = isEn ? "Highlight Color" : "選択時のハイライト色"
                if let hex = currentTheme.flickHighlightHex {
                    cell.detailTextLabel?.text = "■"
                    cell.detailTextLabel?.textColor = UIColor(hex: hex)
                } else {
                    cell.detailTextLabel?.text = isEn ? "Default (Blue)" : "デフォルト（青）"
                }
            } else if indexPath.row == 3 {
                cell.textLabel?.text = isEn ? "Border Color" : "フチの色"
                if let hex = currentTheme.flickPopupBorderColorHex {
                    cell.detailTextLabel?.text = "■"
                    cell.detailTextLabel?.textColor = UIColor(hex: hex)
                } else {
                    cell.detailTextLabel?.text = isEn ? "Default" : "デフォルト"
                }
            } else if indexPath.row == 4 {
                cell.accessoryType = .none
                let titleLabel = UILabel()
                titleLabel.text = isEn ? "Border Width" : "フチの太さ"
                titleLabel.font = .systemFont(ofSize: 16)
                
                let widthSlider = UISlider()
                widthSlider.minimumValue = 0.0
                widthSlider.maximumValue = 5.0
                widthSlider.value = Float(currentTheme.flickPopupBorderWidth ?? 0.0)
                widthSlider.addTarget(self, action: #selector(flickBorderWidthChanged(_:)), for: .valueChanged)
                
                let stack = UIStackView(arrangedSubviews: [titleLabel, widthSlider])
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
            } else if indexPath.row == 5 {
                cell.textLabel?.text = isEn ? "Border Style" : "フチの種類"
                let style = currentTheme.flickPopupBorderStyle ?? 0
                let stylesEn = ["Solid", "Dashed", "Dotted", "Double", "Dash-Dot", "Dash-Dot-Dot"]
                let stylesJa = ["実線", "破線", "点線", "二重線", "一点鎖線", "二点鎖線"]
                cell.detailTextLabel?.text = isEn ? stylesEn[style] : stylesJa[style]
            } else if indexPath.row == 6 {
                cell.textLabel?.text = isEn ? "Popup Shape" : "吹き出しの形"
                let shape = currentTheme.flickPopupShape ?? 0
                let shapesEn = ["Rounded", "Oval", "Rect"]
                let shapesJa = ["角丸", "楕円", "四角"]
                cell.detailTextLabel?.text = isEn ? shapesEn[shape] : shapesJa[shape]
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
                picker.mediaTypes = ["public.image", "public.movie"]
                present(picker, animated: true)
            } else if indexPath.row == 1 {
                currentTheme.backgroundImageFileName = nil
                updatePreview()
                tableView.reloadData()
            }
        } else if indexPath.section == 2 {
            let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            if indexPath.row == 0 {
                alert.title = isEn ? "Key Style" : "キースタイル"
                let stylesEn = ["Standard", "Frosted", "Flat", "Clear"]
                let stylesJa = ["標準", "磨りガラス", "フラット", "クリア"]
                for i in 0..<4 {
                    let action = UIAlertAction(title: isEn ? stylesEn[i] : stylesJa[i], style: .default) { [weak self] _ in
                        self?.currentTheme.keyStyle = i
                        self?.updatePreview()
                        self?.tableView.reloadData()
                    }
                    if currentTheme.keyStyle == i { action.setValue(true, forKey: "checked") }
                    alert.addAction(action)
                }
            } else if indexPath.row == 1 {
                alert.title = isEn ? "Button Shape" : "ボタンの形"
                let shapesEn = ["Rounded", "Oval", "Rect"]
                let shapesJa = ["角丸", "楕円", "四角"]
                for i in 0..<3 {
                    let action = UIAlertAction(title: isEn ? shapesEn[i] : shapesJa[i], style: .default) { [weak self] _ in
                        self?.currentTheme.buttonShape = i
                        self?.updatePreview()
                        self?.tableView.reloadData()
                    }
                    if (currentTheme.buttonShape ?? 0) == i { action.setValue(true, forKey: "checked") }
                    alert.addAction(action)
                }
            }
            alert.addAction(UIAlertAction(title: isEn ? "Cancel" : "キャンセル", style: .cancel))
            if let popover = alert.popoverPresentationController {
                popover.sourceView = tableView.cellForRow(at: indexPath)
                popover.sourceRect = tableView.cellForRow(at: indexPath)?.bounds ?? .zero
            }
            present(alert, animated: true)
        } else if indexPath.section == 3 {
            if indexPath.row == 0 {
                let picker = UIColorPickerViewController()
                picker.delegate = self
                picker.supportsAlpha = true
                pickingColorFor = "border"
                picker.selectedColor = currentTheme.keyBorderColorHex != nil ? (UIColor(hex: currentTheme.keyBorderColorHex!) ?? .black) : .black
                present(picker, animated: true)
            } else if indexPath.row == 2 {
                let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
                let alert = UIAlertController(title: isEn ? "Border Style" : "フチの種類", message: nil, preferredStyle: .actionSheet)
                let stylesEn = ["Solid", "Dashed", "Dotted", "Double", "Dash-Dot", "Dash-Dot-Dot"]
                let stylesJa = ["実線", "破線", "点線", "二重線", "一点鎖線", "二点鎖線"]
                for i in 0..<stylesEn.count {
                    let action = UIAlertAction(title: isEn ? stylesEn[i] : stylesJa[i], style: .default) { [weak self] _ in
                        self?.currentTheme.keyBorderStyle = i
                        self?.updatePreview()
                        self?.tableView.reloadData()
                    }
                    if (currentTheme.keyBorderStyle ?? 0) == i { action.setValue(true, forKey: "checked") }
                    alert.addAction(action)
                }
                alert.addAction(UIAlertAction(title: isEn ? "Cancel" : "キャンセル", style: .cancel))
                if let popover = alert.popoverPresentationController {
                    popover.sourceView = tableView.cellForRow(at: indexPath)
                    popover.sourceRect = tableView.cellForRow(at: indexPath)?.bounds ?? .zero
                }
                present(alert, animated: true)
            }
        } else if indexPath.section == 5 {
            let picker = UIColorPickerViewController()
            picker.delegate = self
            picker.supportsAlpha = true
            
            if indexPath.row == 0 {
                pickingColorFor = "text"
                picker.selectedColor = currentTheme.textColorHex != nil ? (UIColor(hex: currentTheme.textColorHex!) ?? .black) : .black
            } else if indexPath.row == 1 {
                pickingColorFor = "keyBg"
                picker.selectedColor = currentTheme.keyColorHex != nil ? (UIColor(hex: currentTheme.keyColorHex!) ?? .white) : .white
            }
            present(picker, animated: true)
        } else if indexPath.section == 6 {
            var fontNames: [String?] = [
                nil,
                "HiraginoSans-W3", "HiraginoSans-W6", "HiraginoSans-W8",
                "HiraMinProN-W3", "HiraMinProN-W6",
                "HiraMaruProN-W4",
                "ToppanBunkyuGothicPr6N-Regular",
                "ToppanBunkyuMidashiGothicStdN-ExtraBold",
                "ToppanBunkyuMinchoPr6N-Regular",
                "TsukuARdGothic-Regular", "TsukuBRdGothic-Regular",
                "Courier", "Menlo-Regular", "AvenirNext-Regular", "AvenirNext-Bold",
                "GillSans", "GillSans-Bold", "Georgia", "Georgia-Bold",
                "Futura-Medium", "Futura-Bold",
                "HelveticaNeue", "HelveticaNeue-Bold", "HelveticaNeue-Light",
                "ChalkboardSE-Regular", "MarkerFelt-Thin", "PartyLetPlain",
                "BradleyHandITCTT-Bold", "SnellRoundhand"
            ]
            let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
            var fontLabels = [
                isEn ? "System Default" : "システムデフォルト",
                isEn ? "Hiragino Sans" : "ヒラギノ角ゴ",
                isEn ? "Hiragino Sans Bold" : "ヒラギノ角ゴ (太字)",
                isEn ? "Hiragino Sans Extra Bold" : "ヒラギノ角ゴ (極太)",
                isEn ? "Hiragino Mincho" : "ヒラギノ明朝",
                isEn ? "Hiragino Mincho Bold" : "ヒラギノ明朝 (太字)",
                isEn ? "Hiragino Maru Gothic" : "ヒラギノ丸ゴ",
                isEn ? "Toppan Bunkyu Gothic" : "凸版文久ゴシック",
                isEn ? "Toppan Bunkyu Midashi Go" : "凸版文久見出しゴシック",
                isEn ? "Toppan Bunkyu Mincho" : "凸版文久明朝",
                isEn ? "Tsukushi A Maru Gothic" : "筑紫A丸ゴシック",
                isEn ? "Tsukushi B Maru Gothic" : "筑紫B丸ゴシック",
                "Courier", "Menlo", "Avenir Next", "Avenir Next Bold",
                "Gill Sans", "Gill Sans Bold", "Georgia", "Georgia Bold",
                "Futura", "Futura Bold",
                "Helvetica Neue", "Helvetica Neue Bold", "Helvetica Neue Light",
                "Chalkboard SE", "Marker Felt", "Party LET",
                "Bradley Hand", "Snell Roundhand"
            ]
            
            let customFonts = CustomFontManager.shared.getCustomFonts()
            for cf in customFonts {
                fontNames.append(cf.fontName)
                fontLabels.append(cf.displayName)
            }
            
            let alert = UIAlertController(title: isEn ? "Select Font" : "フォントを選択", message: nil, preferredStyle: .actionSheet)
            for (i, name) in fontLabels.enumerated() {
                let action = UIAlertAction(title: name, style: .default) { [weak self] _ in
                    self?.currentTheme.fontName = fontNames[i]
                    self?.updatePreview()
                    self?.tableView.reloadData()
                }
                if fontNames[i] == currentTheme.fontName { action.setValue(true, forKey: "checked") }
                alert.addAction(action)
            }
            
            let importAction = UIAlertAction(title: isEn ? "Manage Fonts..." : "フォント管理...", style: .default) { [weak self] _ in
                let fontVC = FontManagerViewController()
                self?.navigationController?.pushViewController(fontVC, animated: true)
            }
            alert.addAction(importAction)
            
            alert.addAction(UIAlertAction(title: isEn ? "Cancel" : "キャンセル", style: .cancel))
            if let popover = alert.popoverPresentationController {
                popover.sourceView = tableView.cellForRow(at: indexPath)
                popover.sourceRect = tableView.cellForRow(at: indexPath)?.bounds ?? .zero
            }
            present(alert, animated: true)
        } else if indexPath.section == 7 {
            let picker = UIColorPickerViewController()
            picker.delegate = self
            picker.supportsAlpha = true
            
            if indexPath.row == 0 {
                pickingColorFor = "flickPopupBg"
                picker.selectedColor = currentTheme.flickPopupBgHex != nil ? (UIColor(hex: currentTheme.flickPopupBgHex!) ?? .white) : .white
                present(picker, animated: true)
            } else if indexPath.row == 1 {
                pickingColorFor = "flickPopupText"
                picker.selectedColor = currentTheme.flickPopupTextHex != nil ? (UIColor(hex: currentTheme.flickPopupTextHex!) ?? .black) : .black
                present(picker, animated: true)
            } else if indexPath.row == 2 {
                pickingColorFor = "flickHighlight"
                picker.selectedColor = currentTheme.flickHighlightHex != nil ? (UIColor(hex: currentTheme.flickHighlightHex!) ?? .systemBlue) : .systemBlue
                present(picker, animated: true)
            } else if indexPath.row == 3 {
                pickingColorFor = "flickBorder"
                picker.selectedColor = currentTheme.flickPopupBorderColorHex != nil ? (UIColor(hex: currentTheme.flickPopupBorderColorHex!) ?? .black) : .black
                present(picker, animated: true)
            } else if indexPath.row == 5 {
                let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
                let alert = UIAlertController(title: isEn ? "Border Style" : "フチの種類", message: nil, preferredStyle: .actionSheet)
                
                let stylesEn = ["Solid", "Dashed", "Dotted", "Double", "Dash-Dot", "Dash-Dot-Dot"]
                let stylesJa = ["実線", "破線", "点線", "二重線", "一点鎖線", "二点鎖線"]
                
                for i in 0..<6 {
                    let action = UIAlertAction(title: isEn ? stylesEn[i] : stylesJa[i], style: .default) { [weak self] _ in
                        self?.currentTheme.flickPopupBorderStyle = i
                        self?.updatePreview()
                        self?.tableView.reloadData()
                    }
                    if (currentTheme.flickPopupBorderStyle ?? 0) == i {
                        action.setValue(true, forKey: "checked")
                    }
                    alert.addAction(action)
                }
                
                alert.addAction(UIAlertAction(title: isEn ? "Cancel" : "キャンセル", style: .cancel))
                if let popover = alert.popoverPresentationController {
                    popover.sourceView = tableView.cellForRow(at: indexPath)
                    popover.sourceRect = tableView.cellForRow(at: indexPath)?.bounds ?? .zero
                }
                present(alert, animated: true)
            } else if indexPath.row == 6 {
                let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
                let alert = UIAlertController(title: isEn ? "Popup Shape" : "吹き出しの形", message: nil, preferredStyle: .actionSheet)
                
                let shapesEn = ["Rounded", "Oval", "Rect"]
                let shapesJa = ["角丸", "楕円", "四角"]
                
                for i in 0..<3 {
                    let action = UIAlertAction(title: isEn ? shapesEn[i] : shapesJa[i], style: .default) { [weak self] _ in
                        self?.currentTheme.flickPopupShape = i
                        self?.updatePreview()
                        self?.tableView.reloadData()
                    }
                    if (currentTheme.flickPopupShape ?? 0) == i {
                        action.setValue(true, forKey: "checked")
                    }
                    alert.addAction(action)
                }
                
                alert.addAction(UIAlertAction(title: isEn ? "Cancel" : "キャンセル", style: .cancel))
                if let popover = alert.popoverPresentationController {
                    popover.sourceView = tableView.cellForRow(at: indexPath)
                    popover.sourceRect = tableView.cellForRow(at: indexPath)?.bounds ?? .zero
                }
                present(alert, animated: true)
            }
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
        } else if pickingColorFor == "flickPopupBg" {
            currentTheme.flickPopupBgHex = hexStr
        } else if pickingColorFor == "flickPopupText" {
            currentTheme.flickPopupTextHex = hexStr
        } else if pickingColorFor == "flickHighlight" {
            currentTheme.flickHighlightHex = hexStr
        } else if pickingColorFor == "flickBorder" {
            currentTheme.flickPopupBorderColorHex = hexStr
        }
        
        updatePreview()
        tableView.reloadData()
    }
    
    @objc func videoAudioToggled(_ sender: UISwitch) {
        currentTheme.videoAudioEnabled = sender.isOn
        updatePreview()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let mediaType = info[.mediaType] as? String, mediaType == "public.movie", let videoURL = info[.mediaURL] as? URL {
            picker.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                let ext = videoURL.pathExtension.isEmpty ? "mp4" : videoURL.pathExtension
                let fileName = "\(UUID().uuidString).\(ext)"
                if AppGroupHelper.shared.saveFile(from: videoURL, fileName: fileName) {
                    self.currentTheme.backgroundImageFileName = fileName
                    self.updatePreview()
                    self.tableView.reloadData()
                }
            }
        } else if let imageURL = info[.imageURL] as? URL, imageURL.pathExtension.lowercased() == "gif" {
            picker.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                let fileName = "\(UUID().uuidString).gif"
                if AppGroupHelper.shared.saveFile(from: imageURL, fileName: fileName) {
                    self.currentTheme.backgroundImageFileName = fileName
                    self.updatePreview()
                    self.tableView.reloadData()
                }
            }
        } else if let image = info[.originalImage] as? UIImage {
            picker.dismiss(animated: true) { [weak self] in
                let cropVC = ImageCropViewController()
                cropVC.originalImage = image
                cropVC.onCrop = { [weak self] croppedImage in
                    guard let self = self else { return }
                    let fileName = "\(UUID().uuidString).jpg"
                    if AppGroupHelper.shared.saveImage(croppedImage, fileName: fileName) {
                        self.currentTheme.backgroundImageFileName = fileName
                        self.updatePreview()
                        self.tableView.reloadData()
                    }
                }
                cropVC.modalPresentationStyle = .fullScreen
                self?.present(cropVC, animated: true)
            }
        } else {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Haptics & Sensitivity Settings
class HapticsSensitivityViewController: UITableViewController {
    
    private let hapticSwitch = UISwitch()
    private let soundSwitch = UISwitch()
    private let hapticSlider = UISlider()
    private let hapticTargetSegment = UISegmentedControl()
    private let cursorSlider = UISlider()
    private let soundVolumeSlider = UISlider()
    
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
        title = isEn ? "Haptics & Sensitivity" : "振動・カーソル感度"
        
        hapticSwitch.isOn = AppGroupHelper.shared.userDefaults?.object(forKey: "customHapticEnabled") as? Bool ?? true
        hapticSwitch.addTarget(self, action: #selector(hapticSwitchChanged), for: .valueChanged)
        
        if AppGroupHelper.shared.userDefaults?.object(forKey: "customSoundEnabled") == nil {
            AppGroupHelper.shared.userDefaults?.set(hapticSwitch.isOn, forKey: "customSoundEnabled")
        }
        soundSwitch.isOn = AppGroupHelper.shared.userDefaults?.object(forKey: "customSoundEnabled") as? Bool ?? true
        soundSwitch.addTarget(self, action: #selector(soundSwitchChanged), for: .valueChanged)
        
        hapticSlider.minimumValue = 0
        hapticSlider.maximumValue = 2
        hapticSlider.isContinuous = false
        hapticSlider.value = AppGroupHelper.shared.userDefaults?.object(forKey: "customHapticStrength") as? Float ?? 1.0
        hapticSlider.addTarget(self, action: #selector(hapticSliderChanged), for: .valueChanged)
        hapticSlider.isEnabled = hapticSwitch.isOn
        
        soundVolumeSlider.minimumValue = 0.1
        soundVolumeSlider.maximumValue = 1.0
        soundVolumeSlider.value = AppGroupHelper.shared.userDefaults?.object(forKey: "keyboardSoundVolume") as? Float ?? 0.5
        soundVolumeSlider.isContinuous = false
        soundVolumeSlider.addTarget(self, action: #selector(soundVolumeSliderChanged), for: .valueChanged)
        soundVolumeSlider.isEnabled = soundSwitch.isOn
        
        cursorSlider.minimumValue = 0.5
        cursorSlider.maximumValue = 2.5
        cursorSlider.value = AppGroupHelper.shared.userDefaults?.object(forKey: "cursorSensitivity") as? Float ?? 1.0
        cursorSlider.addTarget(self, action: #selector(cursorSliderChanged), for: .valueChanged)
        
        hapticTargetSegment.insertSegment(withTitle: isEn ? "All" : "すべて", at: 0, animated: false)
        hapticTargetSegment.insertSegment(withTitle: isEn ? "Chars" : "文字のみ", at: 1, animated: false)
        hapticTargetSegment.insertSegment(withTitle: isEn ? "Special" : "特殊のみ", at: 2, animated: false)
        hapticTargetSegment.selectedSegmentIndex = AppGroupHelper.shared.userDefaults?.integer(forKey: "hapticTriggerMode") ?? 0
        hapticTargetSegment.addTarget(self, action: #selector(hapticTargetChanged), for: .valueChanged)
    }
    
    @objc private func hapticSwitchChanged() {
        AppGroupHelper.shared.userDefaults?.set(hapticSwitch.isOn, forKey: "customHapticEnabled")
        hapticSlider.isEnabled = hapticSwitch.isOn
        
        if hapticSwitch.isOn {
            let style: UIImpactFeedbackGenerator.FeedbackStyle = {
                let val = Int(round(hapticSlider.value))
                if val == 0 { return .light }
                if val == 1 { return .medium }
                return .heavy
            }()
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
    }
    
    @objc private func soundSwitchChanged() {
        AppGroupHelper.shared.userDefaults?.set(soundSwitch.isOn, forKey: "customSoundEnabled")
        soundVolumeSlider.isEnabled = soundSwitch.isOn
        
        if soundSwitch.isOn {
            soundVolumeSliderChanged()
        }
    }
    
    @objc private func hapticSliderChanged() {
        hapticSlider.value = round(hapticSlider.value)
        AppGroupHelper.shared.userDefaults?.set(hapticSlider.value, forKey: "customHapticStrength")
        
        let style: UIImpactFeedbackGenerator.FeedbackStyle = {
            let val = Int(hapticSlider.value)
            if val == 0 { return .light }
            if val == 1 { return .medium }
            return .heavy
        }()
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    
    private var previewPlayers: [Any]?
    
    @objc private func soundVolumeSliderChanged() {
        AppGroupHelper.shared.userDefaults?.set(soundVolumeSlider.value, forKey: "keyboardSoundVolume")
        
        if previewPlayers == nil {
            var players = [AVAudioPlayer]()
            if let data = Data(base64Encoded: "UklGRggHAABXQVZFZm10IBAAAAABAAEARKwAAIhYAQACABAAZGF0YeQGAAABgAGA/38BgAGA/38BgP9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//39EtAJaUU7/fwGAepMBgLEzAYCjkwGA4asBgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYABgAGAAYBMg2aHFoz9j62UgZhMnD+hX6UgqditP7EUtvq5i73FwSXG1snRzWfRatVH2V7duuCX5GroAez871vzQfe4+gD+yQHyBHIItgtCD5US5hXbGCYcRx9hIq0lziiJK5wuoTF4NG43FjrdPJ8/YEIBRaRHUkr3TE5P2VE7VKZWG1ldW7xd9l8BYlFkdGZ+aHVqnWx1bmpwSnI8dA522neOeUl75nyifv9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f/9//3//f3x/wH4Efkh9i3zPexF7VHqXedp4HXhgd6N25nUpdWx0r3PycjZyenG+cAJwR2+MbtFtFm1cbKNr6Wowandpv2gHaFBnmWbjZS1leGTDYw9jW2KoYfZgRGCSX+JeMl6CXdRcJlx4W8xaIFp0WcpYIFh3V89WJ1aAVdpUNVSQU+xSSVKnUQVRZVDFTyZPiE7qTU5NskwXTH1L5EpLSrRJHUmHSPJHXkfKRjhGpkUVRYVE9kNoQ9tCTkLDQThBrkAlQJ0/Fj+PPgo+hT0BPX48/Dt6O/o6ejr8OX45ATmFOAk4jzcVN5w2JDatNTc1wTRNNNkzZjP0MoMyEjKiMTQxxTBYMOwvgC8VL6suQi7ZLXItCy2lLD8s2yt3KxQrsSpQKu8pjykwKdEocygWKLonXicDJ6kmTyb3JZ8lRyXxJJskRSTxI50jSiP3IqUiVCIEIrQhZSEWIcggeyAuIOIflx9MHwIfuR5wHice4B2ZHVIdDR3HHIMcPxz7G7gbdhs0G/MashpyGjMa9Bm1GXcZOhn9GMEYhRhKGA8Y1RebF2IXKRfxFrkWghZLFhUW3xWqFXUVQRUNFdoUpxR0FEIUERTfE68TfhNPEx8T8BLCEpQSZhI5EgwS3xGzEYgRXBExEQcR3RCzEIoQYRA4EBAQ6A/BD5oPcw9NDycPAQ/cDrcOkg5uDkoOJg4DDuANvQ2bDXkNVw02DRUN9AzUDLMMlAx0DFUMNgwXDPkL2wu9C6ALggtlC0kLLAsQC/QK2Qq9CqIKhwptClMKOAofCgUK7AnTCboJoQmJCXEJWQlBCSoJEgn7COUIzgi4CKIIjAh2CGAISwg2CCEIDAj4B+QH0Ae8B6gHlAeBB24HWwdIBzYHIwcRB/8G7QbbBsoGuAanBpYGhQZ1BmQGVAZEBjMGJAYUBgQG9QXmBdYFxwW5BaoFmwWNBX8FcQVjBVUFRwU5BSwFHwURBQQF9wTrBN4E0QTFBLkErQShBJUEiQR9BHEEZgQ=") {
                for _ in 0..<5 {
                    if let p = try? AVAudioPlayer(data: data) {
                        p.prepareToPlay()
                        players.append(p)
                    }
                }
            }
            previewPlayers = players
            try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
            try? AVAudioSession.sharedInstance().setActive(true)
        }
        
        if let players = previewPlayers as? [AVAudioPlayer], players.count > 0 {
            let volume = soundVolumeSlider.value
            let actualVolume = volume * 2.0
            
            let player = players[0]
            player.volume = actualVolume
            if player.isPlaying { player.currentTime = 0 }
            player.play()
        }
    }
    
    @objc private func cursorSliderChanged() {
        AppGroupHelper.shared.userDefaults?.set(cursorSlider.value, forKey: "cursorSensitivity")
    }
    
    @objc private func hapticTargetChanged() {
        AppGroupHelper.shared.userDefaults?.set(hapticTargetSegment.selectedSegmentIndex, forKey: "hapticTriggerMode")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 5
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
        if section == 0 {
            return isEn ? "Feedback (Sound & Vibration)" : "キーボードの音と振動"
        } else if section == 1 {
            return isEn ? "Cursor Sensitivity" : "カーソル移動の感度"
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
        if section == 0 {
            return isEn ? "Customize custom haptics and keyboard sounds." : "キーボードの音と振動をカスタマイズします。"
        } else if section == 1 {
            return isEn ? "Adjust how fast the cursor moves when dragging the space bar." : "空白キーを長押しして左右にスライドした時の、カーソル移動の速さを調整します。"
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell.textLabel?.text = isEn ? "Enable Custom Vibration" : "独自の振動をオン"
                cell.accessoryView = hapticSwitch
            } else if indexPath.row == 1 {
                hapticSlider.translatesAutoresizingMaskIntoConstraints = false
                cell.contentView.addSubview(hapticSlider)
                
                let minLabel = UILabel()
                minLabel.text = isEn ? "Light" : "弱"
                minLabel.font = .systemFont(ofSize: 12)
                minLabel.textAlignment = .center
                minLabel.textColor = .secondaryLabel
                minLabel.translatesAutoresizingMaskIntoConstraints = false
                
                let maxLabel = UILabel()
                maxLabel.text = isEn ? "Heavy" : "強"
                maxLabel.font = .systemFont(ofSize: 12)
                maxLabel.textAlignment = .center
                maxLabel.textColor = .secondaryLabel
                maxLabel.translatesAutoresizingMaskIntoConstraints = false
                
                cell.contentView.addSubview(minLabel)
                cell.contentView.addSubview(maxLabel)
                
                NSLayoutConstraint.activate([
                    minLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                    minLabel.widthAnchor.constraint(equalToConstant: 24),
                    minLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                    
                    maxLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                    maxLabel.widthAnchor.constraint(equalToConstant: 24),
                    maxLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                    
                    hapticSlider.leadingAnchor.constraint(equalTo: minLabel.trailingAnchor, constant: 16),
                    hapticSlider.trailingAnchor.constraint(equalTo: maxLabel.leadingAnchor, constant: -16),
                    hapticSlider.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
                ])
            } else if indexPath.row == 2 {
                cell.textLabel?.text = isEn ? "Enable Custom Sound" : "独自の音をオン"
                cell.accessoryView = soundSwitch
            } else if indexPath.row == 3 {
                soundVolumeSlider.translatesAutoresizingMaskIntoConstraints = false
                cell.contentView.addSubview(soundVolumeSlider)
                
                let minIcon = UIImageView(image: UIImage(systemName: "speaker.fill"))
                minIcon.tintColor = .secondaryLabel
                minIcon.contentMode = .scaleAspectFit
                minIcon.translatesAutoresizingMaskIntoConstraints = false
                cell.contentView.addSubview(minIcon)
                
                let maxIcon = UIImageView(image: UIImage(systemName: "speaker.wave.3.fill"))
                maxIcon.tintColor = .secondaryLabel
                maxIcon.contentMode = .scaleAspectFit
                maxIcon.translatesAutoresizingMaskIntoConstraints = false
                cell.contentView.addSubview(maxIcon)
                
                NSLayoutConstraint.activate([
                    minIcon.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                    minIcon.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                    minIcon.widthAnchor.constraint(equalToConstant: 24),
                    minIcon.heightAnchor.constraint(equalToConstant: 24),
                    
                    maxIcon.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                    maxIcon.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                    maxIcon.widthAnchor.constraint(equalToConstant: 24),
                    maxIcon.heightAnchor.constraint(equalToConstant: 24),
                    
                    soundVolumeSlider.leadingAnchor.constraint(equalTo: minIcon.trailingAnchor, constant: 16),
                    soundVolumeSlider.trailingAnchor.constraint(equalTo: maxIcon.leadingAnchor, constant: -16),
                    soundVolumeSlider.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
                ])
            } else if indexPath.row == 4 {
                cell.textLabel?.text = isEn ? "Target Keys" : "対象キー"
                hapticTargetSegment.sizeToFit()
                cell.accessoryView = hapticTargetSegment
            }
        } else if indexPath.section == 1 {
            cursorSlider.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(cursorSlider)
            
            let minLabel = UILabel()
            minLabel.text = isEn ? "Slow" : "遅い"
            minLabel.font = .systemFont(ofSize: 14)
            minLabel.textColor = .secondaryLabel
            minLabel.translatesAutoresizingMaskIntoConstraints = false
            
            let maxLabel = UILabel()
            maxLabel.text = isEn ? "Fast" : "速い"
            maxLabel.font = .systemFont(ofSize: 14)
            maxLabel.textColor = .secondaryLabel
            maxLabel.translatesAutoresizingMaskIntoConstraints = false
            
            cell.contentView.addSubview(minLabel)
            cell.contentView.addSubview(maxLabel)
            
            NSLayoutConstraint.activate([
                minLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                minLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                
                maxLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                maxLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                
                cursorSlider.leadingAnchor.constraint(equalTo: minLabel.trailingAnchor, constant: 16),
                cursorSlider.trailingAnchor.constraint(equalTo: maxLabel.leadingAnchor, constant: -16),
                cursorSlider.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
            ])
        } else if indexPath.section == 2 {
            cell.textLabel?.text = isEn ? "Reset Settings" : "設定をリセット"
            cell.textLabel?.textColor = .systemRed
            cell.textLabel?.textAlignment = .center
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 {
            tableView.deselectRow(at: indexPath, animated: true)
            AppGroupHelper.shared.userDefaults?.removeObject(forKey: "customHapticEnabled")
            AppGroupHelper.shared.userDefaults?.removeObject(forKey: "customSoundEnabled")
            AppGroupHelper.shared.userDefaults?.removeObject(forKey: "keyboardSoundVolume")
            AppGroupHelper.shared.userDefaults?.removeObject(forKey: "customHapticStrength")
            AppGroupHelper.shared.userDefaults?.removeObject(forKey: "hapticTriggerMode")
            AppGroupHelper.shared.userDefaults?.removeObject(forKey: "cursorSensitivity")
            
            hapticSwitch.isOn = true
            soundSwitch.isOn = true
            hapticSlider.value = 1.0
            soundVolumeSlider.value = 0.5
            hapticTargetSegment.selectedSegmentIndex = 0
            cursorSlider.value = 1.0
            
            hapticSlider.isEnabled = true
            soundVolumeSlider.isEnabled = true
            
            tableView.reloadData()
        }
    }
}
