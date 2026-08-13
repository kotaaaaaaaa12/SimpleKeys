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
    
    func containerURL() -> URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }
    
    func saveImage(_ image: UIImage, fileName: String) -> Bool {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return false }
        guard let url = containerURL()?.appendingPathComponent(fileName) else { return false }
        do {
            try data.write(to: url)
            return true
        } catch {
            print("Failed to save image: \(error)")
            return false
        }
    }
    
    func loadImage(fileName: String) -> UIImage? {
        guard let url = containerURL()?.appendingPathComponent(fileName) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    
    func removeImage(fileName: String) {
        guard let url = containerURL()?.appendingPathComponent(fileName) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - Theme Models
struct ThemeSettings: Codable, Equatable {
    var id: String?
    var name: String?
    var backgroundImageFileName: String?
    var backgroundColorHex: String?
    var keyStyle: Int // 0: standard, 1: frosted glass, 2: flat, 3: clear glass
    var buttonShape: Int? // 0: rounded, 1: oval, 2: rect
    var fontName: String?
    var keyColorHex: String?
    var textColorHex: String?
    var keyBorderColorHex: String?
    var keyOpacity: CGFloat?
    var flickPopupBgHex: String?       // Flick popup background color
    var flickPopupTextHex: String?     // Flick popup text color
    var flickHighlightHex: String?     // Flick popup selected highlight color
    
    static let sharedKey = "customThemeSettings"
    static let themesArrayKey = "savedCustomThemes"
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
        flickSwitch.isOn = defaults?.object(forKey: "enableFlick") == nil ? true : defaults!.bool(forKey: "enableFlick")
        flickAlphabetQwertySwitch.isOn = defaults?.bool(forKey: "flickAlphabetIsQwerty") ?? false
        flickOnlySwitch.isOn = defaults?.bool(forKey: "flickOnly") ?? false
        
        let ohMode = defaults?.string(forKey: "oneHandedMode") ?? "off"
        oneHandedSegment.selectedSegmentIndex = ohMode == "left" ? 0 : (ohMode == "right" ? 2 : 1)
        
        qwertyEnglishSwitch.isOn = defaults?.object(forKey: "enableQwertyEnglish") == nil ? true : defaults!.bool(forKey: "enableQwertyEnglish")
        qwertyRomajiSwitch.isOn = defaults?.object(forKey: "enableQwertyRomaji") == nil ? true : defaults!.bool(forKey: "enableQwertyRomaji")
        
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
    
    override func numberOfSections(in tableView: UITableView) -> Int { return 7 }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 1
        case 2: return 3
        case 3: return 3
        case 4: return 3
        case 5: return 1
        case 6: return 5
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
        case 6: return isEn ? "Coming Soon" : "開発中・実装予定の機能 (Coming Soon)"
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let isEn = languageSegment.selectedSegmentIndex == 1
        switch section {
        case 1: return isEn ? "Go to Settings > General > Keyboard, add SimpleKeys, and Allow Full Access." : "設定アプリからキーボードを追加し、「フルアクセスを許可」をオンにしてください。"
        case 4: return isEn ? "Enter your Gemini API key to use cloud AI conversion. This requires Full Access." : "AI変換を利用するには、Gemini APIキーを入力してください（フルアクセス許可が必要です）。"
        case 5: return isEn ? "Register custom words for faster conversion." : "よく使う単語や特殊な変換を登録できます。"
        case 6: return isEn ? "These features will be available in future updates." : "これらの機能は今後のアップデートで追加される予定です。"
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
            if indexPath.row == 0 {
                cell.textLabel?.text = isEn ? "Alphabet layout is QWERTY" : "アルファベットをQWERTYにする"
                cell.detailTextLabel?.text = isEn ? "Use QWERTY layout for Alphabet in Flick keyboard" : "フリックキーボードの英字モードをQWERTYにします"
                cell.accessoryView = flickAlphabetQwertySwitch
            } else if indexPath.row == 1 {
                cell.textLabel?.text = isEn ? "Flick Only (Disable Toggle)" : "フリックのみ (ガラケー打ち無効)"
                cell.detailTextLabel?.text = isEn ? "Disable multiple taps to cycle characters" : "同じキーを連続タップしたときの文字切り替えを無効にします"
                cell.accessoryView = flickOnlySwitch
            } else if indexPath.row == 2 {
                cell.textLabel?.text = isEn ? "One-Handed Mode" : "片手モード"
                cell.detailTextLabel?.text = isEn ? "Shift keyboard for easy typing" : "キーボードを左右に寄せて片手で入力しやすくします"
                cell.accessoryView = oneHandedSegment
            }
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
                geminiModelField.placeholder = isEn ? "Model Name (e.g. gemini-3.5-flash)" : "モデル名 (例: gemini-3.5-flash)"
            }
        } else if indexPath.section == 5 {
            cell.textLabel?.text = isEn ? "User Dictionary" : "ユーザー辞書"
            cell.detailTextLabel?.text = isEn ? "Register frequently used words" : "よく使う単語を登録できます"
            cell.imageView?.image = UIImage(systemName: "book.fill")
            cell.accessoryType = .disclosureIndicator
        } else if indexPath.section == 6 {
            if indexPath.row != 0 {
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
                cell.textLabel?.text = isEn ? "Real-time AI Translation" : "AIリアルタイム翻訳＆トーン変換"
                cell.detailTextLabel?.text = isEn ? "Translate or change text tone instantly" : "入力中のテキストを自動翻訳したり、敬語などに変換します"
                cell.imageView?.image = UIImage(systemName: "character.bubble.fill")
            } else if indexPath.row == 2 {
                cell.textLabel?.text = isEn ? "Clipboard & Snippets" : "クリップボード履歴＆定型文ボード"
                cell.detailTextLabel?.text = isEn ? "Access copy history and quick phrases" : "過去のコピー履歴やよく使う定型文をワンタップで入力"
                cell.imageView?.image = UIImage(systemName: "doc.on.clipboard.fill")
            } else if indexPath.row == 3 {
                cell.textLabel?.text = isEn ? "AI Emoji Suggestion" : "AI文脈絵文字・顔文字サジェスト"
                cell.detailTextLabel?.text = isEn ? "Smart emoji suggestions based on context" : "文章の感情に合わせて最適な絵文字・顔文字をAIが提案"
                cell.imageView?.image = UIImage(systemName: "face.smiling.fill")
            } else if indexPath.row == 4 {
                cell.textLabel?.text = isEn ? "Haptics & Sensitivity Settings" : "振動・カーソル感度の詳細カスタマイズ"
                cell.detailTextLabel?.text = isEn ? "Fine-tune vibration and cursor speed" : "キーを弾いた時の振動やカーソル移動のスピードを調整"
                cell.imageView?.image = UIImage(systemName: "slider.horizontal.3")
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
            tableView.deselectRow(at: indexPath, animated: true)
            let vc = UserDictionaryViewController()
            navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.section == 6 && indexPath.row == 0 {
            tableView.deselectRow(at: indexPath, animated: true)
            let vc = MyThemesViewController(style: .insetGrouped)
            navigationController?.pushViewController(vc, animated: true)
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
            currentTheme.name = isEn ? "Custom Theme" : "カスタムテーマ"
            currentTheme.keyOpacity = 1.0
        }
        
        if currentTheme.keyOpacity == nil {
            currentTheme.keyOpacity = 1.0
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
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: isEn ? "Save" : "保存", style: .done, target: self, action: #selector(saveTapped))
    }
    
    private let keyboardTypeSegment = UISegmentedControl(items: ["Kana", "QWERTY"])
    
    class PreviewKeyView: UIView {
        var shape: Int = 0 { didSet { setNeedsLayout() } }
        var blurView: UIVisualEffectView?
        var isSpecial: Bool = false
        
        override func layoutSubviews() {
            super.layoutSubviews()
            let radius: CGFloat = shape == 0 ? 6 : (shape == 1 ? min(bounds.width, bounds.height) / 2.0 : 0)
            layer.cornerRadius = radius
            blurView?.layer.cornerRadius = radius
        }
    }
    
    private func setupUI() {
        keyboardTypeSegment.selectedSegmentIndex = 0
        keyboardTypeSegment.addTarget(self, action: #selector(keyboardTypeChanged), for: .valueChanged)
        keyboardTypeSegment.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboardTypeSegment)
        
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
        
        buildGrid(isQwerty: false)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            keyboardTypeSegment.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            keyboardTypeSegment.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            previewContainer.topAnchor.constraint(equalTo: keyboardTypeSegment.bottomAnchor, constant: 12),
            previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            previewContainer.heightAnchor.constraint(equalToConstant: 220),
            
            previewBgImageView.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            previewBgImageView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            previewBgImageView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            previewBgImageView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),
            
            previewGrid.centerXAnchor.constraint(equalTo: previewContainer.centerXAnchor),
            previewGrid.centerYAnchor.constraint(equalTo: previewContainer.centerYAnchor),
            previewGrid.widthAnchor.constraint(equalTo: previewContainer.widthAnchor, constant: -16),
            previewGrid.heightAnchor.constraint(equalToConstant: 180),
            
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
    
    @objc private func keyboardTypeChanged() {
        buildGrid(isQwerty: keyboardTypeSegment.selectedSegmentIndex == 1)
        updatePreview()
    }
    
    private func buildGrid(isQwerty: Bool) {
        previewGrid.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if isQwerty {
            previewGrid.axis = .vertical
            
            let row0 = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
            let row1 = ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
            let row2 = ["Z", "X", "C", "V", "B", "N", "M"]
            
            let r0Stack = UIStackView(); r0Stack.axis = .horizontal; r0Stack.distribution = .fill; r0Stack.spacing = 6
            var allNormalKeys: [UIView] = []
            
            for k in row0 {
                let key = createPreviewKey(k)
                r0Stack.addArrangedSubview(key)
                allNormalKeys.append(key)
            }
            
            let r1Stack = UIStackView(); r1Stack.axis = .horizontal; r1Stack.distribution = .fill; r1Stack.spacing = 6
            let r1SpacerL = UIView(); let r1SpacerR = UIView()
            r1Stack.addArrangedSubview(r1SpacerL)
            for k in row1 {
                let key = createPreviewKey(k)
                r1Stack.addArrangedSubview(key)
                allNormalKeys.append(key)
            }
            r1Stack.addArrangedSubview(r1SpacerR)
            
            let r2Stack = UIStackView(); r2Stack.axis = .horizontal; r2Stack.distribution = .fill; r2Stack.spacing = 6
            let shiftKey = createPreviewKey("shift", isSystemImage: true, isSpecial: true)
            r2Stack.addArrangedSubview(shiftKey)
            for k in row2 {
                let key = createPreviewKey(k)
                r2Stack.addArrangedSubview(key)
                allNormalKeys.append(key)
            }
            let delKey = createPreviewKey("delete.left", isSystemImage: true, isSpecial: true)
            r2Stack.addArrangedSubview(delKey)
            
            let r3Stack = UIStackView(); r3Stack.axis = .horizontal; r3Stack.distribution = .fill; r3Stack.spacing = 6
            let numKey = createPreviewKey("123", isSpecial: true)
            let globeKey = createPreviewKey("globe", isSystemImage: true, isSpecial: true)
            let spaceKey = createPreviewKey("space")
            let returnKey = createPreviewKey("return", isSpecial: true)
            r3Stack.addArrangedSubview(numKey)
            r3Stack.addArrangedSubview(globeKey)
            r3Stack.addArrangedSubview(spaceKey)
            r3Stack.addArrangedSubview(returnKey)
            
            previewGrid.addArrangedSubview(r0Stack)
            previewGrid.addArrangedSubview(r1Stack)
            previewGrid.addArrangedSubview(r2Stack)
            previewGrid.addArrangedSubview(r3Stack)
            
            if let firstKey = allNormalKeys.first {
                for key in allNormalKeys.dropFirst() {
                    key.widthAnchor.constraint(equalTo: firstKey.widthAnchor).isActive = true
                }
                r1SpacerL.widthAnchor.constraint(equalTo: r1SpacerR.widthAnchor).isActive = true
                shiftKey.widthAnchor.constraint(equalTo: delKey.widthAnchor).isActive = true
                
                numKey.widthAnchor.constraint(equalTo: firstKey.widthAnchor, multiplier: 1.5).isActive = true
                globeKey.widthAnchor.constraint(equalTo: firstKey.widthAnchor, multiplier: 1.2).isActive = true
                returnKey.widthAnchor.constraint(equalTo: firstKey.widthAnchor, multiplier: 2.0).isActive = true
            }
            
        } else {
            previewGrid.axis = .horizontal
            
            let cols = [
                ["☆123", "ABC", "^_^", "globe"],
                ["あ", "た", "ま", "小/濁"],
                ["か", "な", "や", "わ"],
                ["さ", "は", "ら", "、"]
            ]
            
            for (i, col) in cols.enumerated() {
                let colStack = UIStackView()
                colStack.axis = .vertical; colStack.distribution = .fillEqually; colStack.spacing = 8
                for k in col {
                    let isGlobe = (k == "globe")
                    colStack.addArrangedSubview(createPreviewKey(k, isSystemImage: isGlobe, isSpecial: i == 0 || (i == 1 && k == "小/濁")))
                }
                previewGrid.addArrangedSubview(colStack)
            }
            
            let rightCol = UIStackView()
            rightCol.axis = .vertical; rightCol.distribution = .fill; rightCol.spacing = 8
            let delKey = createPreviewKey("delete.left", isSystemImage: true, isSpecial: true)
            let spcKey = createPreviewKey("空白")
            let retKey = createPreviewKey("改行", isSpecial: true)
            rightCol.addArrangedSubview(delKey)
            rightCol.addArrangedSubview(spcKey)
            rightCol.addArrangedSubview(retKey)
            previewGrid.addArrangedSubview(rightCol)
            
            delKey.heightAnchor.constraint(equalTo: spcKey.heightAnchor).isActive = true
            retKey.heightAnchor.constraint(equalTo: spcKey.heightAnchor, multiplier: 2.0, constant: 8).isActive = true
        }
    }
    
    private func createPreviewKey(_ title: String, isSystemImage: Bool = false, isSpecial: Bool = false) -> PreviewKeyView {
        let key = PreviewKeyView()
        key.isSpecial = isSpecial
        
        if isSystemImage {
            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
            let imageView = UIImageView(image: UIImage(systemName: title, withConfiguration: config))
            imageView.tintColor = .black
            imageView.tag = 778
            imageView.translatesAutoresizingMaskIntoConstraints = false
            key.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: key.centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: key.centerYAnchor)
            ])
        } else {
            let label = UILabel()
            label.text = title
            label.textAlignment = .center
            label.font = .systemFont(ofSize: title.count > 1 ? 14 : 18)
            label.tag = 777
            label.translatesAutoresizingMaskIntoConstraints = false
            key.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: key.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: key.centerYAnchor)
            ])
        }
        return key
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
        let opacity = currentTheme.keyOpacity ?? 1.0
        
        let defaultBorderCol = UIColor.black.withAlphaComponent(0.3).cgColor
        let borderCol = currentTheme.keyBorderColorHex != nil ? (UIColor(hex: currentTheme.keyBorderColorHex!)?.cgColor ?? defaultBorderCol) : defaultBorderCol
        
        let defaultTextCol = UIColor.black
        let textCol = currentTheme.textColorHex != nil ? (UIColor(hex: currentTheme.textColorHex!) ?? defaultTextCol) : defaultTextCol
        
        let defaultKeyBgCol = UIColor.white
        let keyBgCol = currentTheme.keyColorHex != nil ? (UIColor(hex: currentTheme.keyColorHex!) ?? defaultKeyBgCol) : defaultKeyBgCol
        let specialBg = UIColor(red: 0.68, green: 0.70, blue: 0.74, alpha: 1.0)
        
        let clearBgAlpha = 0.15 * opacity
        
        func updateKeyView(_ v: UIView) {
            guard let keyView = v as? PreviewKeyView else {
                for sub in v.subviews { updateKeyView(sub) }
                return
            }
            
            keyView.subviews.filter { $0 is UIVisualEffectView }.forEach { $0.removeFromSuperview() }
            
            if let label = keyView.viewWithTag(777) as? UILabel {
                label.textColor = textCol
                if let fontName = currentTheme.fontName, let customFont = UIFont(name: fontName, size: label.font.pointSize) {
                    label.font = customFont
                }
            }
            if let imageView = keyView.viewWithTag(778) as? UIImageView {
                imageView.tintColor = textCol
            }
            
            keyView.shape = shape
            
            if currentTheme.keyStyle == 1 || currentTheme.keyStyle == 3 {
                keyView.backgroundColor = currentTheme.keyStyle == 3 ? UIColor.white.withAlphaComponent(clearBgAlpha) : .clear
                keyView.layer.shadowOpacity = 0
                keyView.layer.borderWidth = 0.5
                keyView.layer.borderColor = borderCol
                
                if currentTheme.keyStyle == 1 {
                    let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                    blur.layer.borderWidth = 0.5
                    blur.layer.borderColor = borderCol
                    blur.clipsToBounds = true
                    blur.translatesAutoresizingMaskIntoConstraints = false
                    blur.alpha = opacity
                    keyView.insertSubview(blur, at: 0)
                    NSLayoutConstraint.activate([
                        blur.leadingAnchor.constraint(equalTo: keyView.leadingAnchor),
                        blur.trailingAnchor.constraint(equalTo: keyView.trailingAnchor),
                        blur.topAnchor.constraint(equalTo: keyView.topAnchor),
                        blur.bottomAnchor.constraint(equalTo: keyView.bottomAnchor)
                    ])
                    keyView.blurView = blur
                }
            } else if currentTheme.keyStyle == 2 {
                keyView.backgroundColor = .clear
                keyView.layer.shadowOpacity = 0
                keyView.layer.borderWidth = 1
                keyView.layer.borderColor = borderCol
            } else {
                keyView.backgroundColor = keyView.isSpecial ? specialBg : keyBgCol
                keyView.layer.shadowOpacity = 0.3
                keyView.layer.borderWidth = 0
            }
        }
        
        for row in previewGrid.arrangedSubviews {
            updateKeyView(row)
        }
    }
    
    @objc private func saveTapped() {
        if currentTheme.name == nil || currentTheme.name!.isEmpty {
            let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
            currentTheme.name = isEn ? "Custom Theme" : "カスタムテーマ"
        }
        onSave?(currentTheme)
        navigationController?.popViewController(animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int { return 7 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 { return 2 }
        if section == 3 { return 1 } // Opacity
        if section == 4 { return 3 } // Colors
        if section == 5 { return 1 } // Font
        if section == 6 { return 3 } // Flick popup colors
        return 1
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
        if section == 0 { return isEn ? "Name" : "テーマ名" }
        if section == 1 { return isEn ? "Background" : "背景画像" }
        if section == 2 { return isEn ? "Key Style & Shape" : "キースタイル & 形状" }
        if section == 3 { return isEn ? "Transparency" : "透過度" }
        if section == 4 { return isEn ? "Colors" : "色設定" }
        if section == 5 { return isEn ? "Font" : "フォント" }
        return isEn ? "Flick Popup" : "フリック吹き出し"
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
        } else if indexPath.section == 5 {
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = isEn ? "Font Family" : "フォントファミリー"
            cell.detailTextLabel?.text = currentTheme.fontName ?? (isEn ? "System Default" : "システムデフォルト")
        } else if indexPath.section == 6 {
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
                picker.selectedColor = currentTheme.textColorHex != nil ? (UIColor(hex: currentTheme.textColorHex!) ?? .black) : .black
            } else if indexPath.row == 1 {
                pickingColorFor = "border"
                picker.selectedColor = currentTheme.keyBorderColorHex != nil ? (UIColor(hex: currentTheme.keyBorderColorHex!) ?? .black) : .black
            } else if indexPath.row == 2 {
                pickingColorFor = "keyBg"
                picker.selectedColor = currentTheme.keyColorHex != nil ? (UIColor(hex: currentTheme.keyColorHex!) ?? .white) : .white
            }
            present(picker, animated: true)
        } else if indexPath.section == 5 {
            let fontNames = [nil, "HiraginoSans-W3", "HiraMinProN-W3", "Courier", "Menlo-Regular", "AvenirNext-Regular", "GillSans", "Georgia", "Futura-Medium"]
            let isEn = AppGroupHelper.shared.userDefaults?.string(forKey: "appLanguage") == "en"
            let fontLabels = [
                isEn ? "System Default" : "システムデフォルト",
                isEn ? "Hiragino Sans" : "ヒラギノ角ゴ",
                isEn ? "Hiragino Mincho" : "ヒラギノ明朝",
                "Courier",
                "Menlo",
                "Avenir Next",
                "Gill Sans",
                "Georgia",
                "Futura"
            ]
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
            alert.addAction(UIAlertAction(title: isEn ? "Cancel" : "キャンセル", style: .cancel))
            if let popover = alert.popoverPresentationController {
                popover.sourceView = tableView.cellForRow(at: indexPath)
                popover.sourceRect = tableView.cellForRow(at: indexPath)?.bounds ?? .zero
            }
            present(alert, animated: true)
        } else if indexPath.section == 6 {
            let picker = UIColorPickerViewController()
            picker.delegate = self
            picker.supportsAlpha = true
            
            if indexPath.row == 0 {
                pickingColorFor = "flickPopupBg"
                picker.selectedColor = currentTheme.flickPopupBgHex != nil ? (UIColor(hex: currentTheme.flickPopupBgHex!) ?? .white) : .white
            } else if indexPath.row == 1 {
                pickingColorFor = "flickPopupText"
                picker.selectedColor = currentTheme.flickPopupTextHex != nil ? (UIColor(hex: currentTheme.flickPopupTextHex!) ?? .black) : .black
            } else if indexPath.row == 2 {
                pickingColorFor = "flickHighlight"
                picker.selectedColor = currentTheme.flickHighlightHex != nil ? (UIColor(hex: currentTheme.flickHighlightHex!) ?? .systemBlue) : .systemBlue
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
        } else if pickingColorFor == "flickPopupBg" {
            currentTheme.flickPopupBgHex = hexStr
        } else if pickingColorFor == "flickPopupText" {
            currentTheme.flickPopupTextHex = hexStr
        } else if pickingColorFor == "flickHighlight" {
            currentTheme.flickHighlightHex = hexStr
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

extension UIColor {
    convenience init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        }
        if hexString.count != 6 && hexString.count != 8 { return nil }
        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)
        if hexString.count == 6 {
            self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                      green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                      blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                      alpha: 1.0)
        } else {
            self.init(red: CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0,
                      green: CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0,
                      blue: CGFloat((rgbValue & 0x0000FF00) >> 8) / 255.0,
                      alpha: CGFloat(rgbValue & 0x000000FF) / 255.0)
        }
    }
}
