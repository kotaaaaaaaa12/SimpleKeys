import UIKit

// MARK: - AppGroupHelper
class AppGroupHelper {
    static let shared = AppGroupHelper()
    
    private(set) var appGroupID: String = "group.com.simplekeys.app"
    private(set) var userDefaults: UserDefaults?
    
    private init() {
        if let group = resolveAppGroup() {
            self.appGroupID = group
        }
        self.userDefaults = UserDefaults(suiteName: self.appGroupID)
    }
    
    private func resolveAppGroup() -> String? {
        guard let path = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let string = String(data: data, encoding: .isoLatin1) else {
            return nil
        }
        
        if let startRange = string.range(of: "<?xml"),
           let endRange = string.range(of: "</plist>") {
            let plistString = String(string[startRange.lowerBound...endRange.upperBound])
            if let plistData = plistString.data(using: .utf8),
               let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any],
               let entitlements = plist["Entitlements"] as? [String: Any],
               let appGroups = entitlements["com.apple.security.application-groups"] as? [String],
               let firstGroup = appGroups.first {
                return firstGroup
            }
        }
        return nil
    }
}

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
        
        let settingsVC = UINavigationController(rootViewController: SettingsViewController())
        settingsVC.tabBarItem = UITabBarItem(title: "設定", image: UIImage(systemName: "gearshape.fill"), tag: 0)
        
        let updatesNav = UINavigationController(rootViewController: updatesVC)
        updatesNav.tabBarItem = UITabBarItem(title: "お知らせ", image: UIImage(systemName: "bell.fill"), tag: 1)
        
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
        flickSwitch.isOn = defaults?.object(forKey: "enableFlick") == nil ? true : defaults!.bool(forKey: "enableFlick")
        flickAlphabetQwertySwitch.isOn = defaults?.bool(forKey: "flickAlphabetIsQwerty") ?? false
        qwertyEnglishSwitch.isOn = defaults?.object(forKey: "enableQwertyEnglish") == nil ? true : defaults!.bool(forKey: "enableQwertyEnglish")
        qwertyRomajiSwitch.isOn = defaults?.object(forKey: "enableQwertyRomaji") == nil ? true : defaults!.bool(forKey: "enableQwertyRomaji")
        
        let lang = defaults?.string(forKey: "appLanguage") ?? "ja"
        languageSegment.selectedSegmentIndex = lang == "en" ? 1 : 0
        
        geminiSwitch.isOn = defaults?.bool(forKey: "enableGemini") ?? false
        geminiApiKeyField.text = defaults?.string(forKey: "geminiApiKey")
        let savedModel = defaults?.string(forKey: "geminiModel")
        geminiModelField.text = (savedModel != nil && !savedModel!.isEmpty) ? savedModel : "gemini-2.0-flash"
    }
    
    @objc private func settingsChanged() {
        if !flickSwitch.isOn && !qwertyEnglishSwitch.isOn && !qwertyRomajiSwitch.isOn {
            flickSwitch.isOn = true
            tableView.reloadData()
        }
        
        sharedDefaults?.set(flickSwitch.isOn, forKey: "enableFlick")
        sharedDefaults?.set(flickAlphabetQwertySwitch.isOn, forKey: "flickAlphabetIsQwerty")
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
            tabBarVC.checkForUpdates()
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int { return 6 }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 1
        case 2: return 3
        case 3: return 1
        case 4: return 3
        case 5: return 4
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
        case 5: return isEn ? "Coming Soon" : "開発中・実装予定の機能 (Coming Soon)"
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let isEn = languageSegment.selectedSegmentIndex == 1
        switch section {
        case 1: return isEn ? "Go to Settings > General > Keyboard, add SimpleKeys, and Allow Full Access." : "設定アプリからキーボードを追加し、「フルアクセスを許可」をオンにしてください。"
        case 4: return isEn ? "Enter your Gemini API key to use cloud AI conversion. This requires Full Access." : "AI変換を利用するには、Gemini APIキーを入力してください（フルアクセス許可が必要です）。"
        case 5: return isEn ? "These features will be available in future updates." : "これらの機能は今後のアップデートで追加される予定です。"
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.selectionStyle = .none
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
            cell.textLabel?.text = isEn ? "Alphabet layout is QWERTY" : "アルファベットをQWERTYにする"
            cell.detailTextLabel?.text = isEn ? "Use QWERTY layout for Alphabet in Flick keyboard" : "フリックキーボードの英字モードをQWERTYにします"
            cell.accessoryView = flickAlphabetQwertySwitch
        } else if indexPath.section == 4 {
            if indexPath.row == 0 {
                cell.textLabel?.text = isEn ? "Enable Gemini AI Conversion" : "Gemini AI変換を有効にする"
                cell.accessoryView = geminiSwitch
            } else if indexPath.row == 1 {
                cell.contentView.addSubview(geminiApiKeyField)
                geminiApiKeyField.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    geminiApiKeyField.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                    geminiApiKeyField.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                    geminiApiKeyField.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16)
                ])
                geminiApiKeyField.placeholder = isEn ? "Enter Gemini API Key..." : "Gemini APIキーを入力..."
            } else if indexPath.row == 2 {
                cell.contentView.addSubview(geminiModelField)
                geminiModelField.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    geminiModelField.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                    geminiModelField.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                    geminiModelField.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16)
                ])
                geminiModelField.placeholder = isEn ? "Model Name (e.g. gemini-2.0-flash)" : "モデル名 (例: gemini-2.0-flash)"
            }
        } else if indexPath.section == 5 {
            cell.textLabel?.textColor = .secondaryLabel
            cell.detailTextLabel?.textColor = .tertiaryLabel
            cell.imageView?.tintColor = .systemGray
            
            if indexPath.row == 0 {
                cell.textLabel?.text = isEn ? "Custom Themes" : "カスタムテーマ"
                cell.detailTextLabel?.text = isEn ? "Customize background color and images" : "背景色や画像を自由に設定できます"
                cell.imageView?.image = UIImage(systemName: "paintpalette.fill")
            } else if indexPath.row == 1 {
                cell.textLabel?.text = isEn ? "User Dictionary" : "ユーザー辞書"
                cell.detailTextLabel?.text = isEn ? "Register frequently used words" : "よく使う単語を登録できます"
                cell.imageView?.image = UIImage(systemName: "book.fill")
            } else if indexPath.row == 2 {
                cell.textLabel?.text = isEn ? "Toggle Input" : "トグル入力 (ガラケー打ち)"
                cell.detailTextLabel?.text = isEn ? "Multi-tap to cycle through characters" : "ボタンを何度も押して文字を切り替えます"
                cell.imageView?.image = UIImage(systemName: "candybarphone")
            } else if indexPath.row == 3 {
                cell.textLabel?.text = isEn ? "One-Handed Mode" : "片手モード"
                cell.detailTextLabel?.text = isEn ? "Shift keyboard left/right for easy typing" : "キーボードを左右に寄せて片手で入力しやすくします"
                cell.imageView?.image = UIImage(systemName: "hand.point.up.left")
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

