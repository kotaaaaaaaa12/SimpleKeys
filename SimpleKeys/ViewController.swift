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

// MARK: - Main Tab Bar
class ViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let settingsVC = UINavigationController(rootViewController: SettingsViewController())
        settingsVC.tabBarItem = UITabBarItem(title: "設定", image: UIImage(systemName: "gearshape.fill"), tag: 0)
        
        let updatesVC = UINavigationController(rootViewController: UpdatesViewController())
        updatesVC.tabBarItem = UITabBarItem(title: "お知らせ", image: UIImage(systemName: "bell.fill"), tag: 1)
        
        viewControllers = [settingsVC, updatesVC]
        tabBar.tintColor = .systemBlue
    }
}

// MARK: - Settings
class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let flickSwitch = UISwitch()
    private let flickAlphabetQwertySwitch = UISwitch()
    private let qwertyEnglishSwitch = UISwitch()
    private let qwertyRomajiSwitch = UISwitch()
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let sharedDefaults = AppGroupHelper.shared.userDefaults

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "SimpleKeys"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemGroupedBackground
        
        setupTableView()
        setupSwitches()
        loadSettings()
    }
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupSwitches() {
        flickSwitch.addTarget(self, action: #selector(settingsChanged), for: .valueChanged)
        flickAlphabetQwertySwitch.addTarget(self, action: #selector(settingsChanged), for: .valueChanged)
        qwertyEnglishSwitch.addTarget(self, action: #selector(settingsChanged), for: .valueChanged)
        qwertyRomajiSwitch.addTarget(self, action: #selector(settingsChanged), for: .valueChanged)
    }
    
    private func loadSettings() {
        let defaults = sharedDefaults
        flickSwitch.isOn = defaults?.object(forKey: "enableFlick") == nil ? true : defaults!.bool(forKey: "enableFlick")
        flickAlphabetQwertySwitch.isOn = defaults?.bool(forKey: "flickAlphabetIsQwerty") ?? false
        qwertyEnglishSwitch.isOn = defaults?.object(forKey: "enableQwertyEnglish") == nil ? true : defaults!.bool(forKey: "enableQwertyEnglish")
        qwertyRomajiSwitch.isOn = defaults?.object(forKey: "enableQwertyRomaji") == nil ? true : defaults!.bool(forKey: "enableQwertyRomaji")
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
        sharedDefaults?.synchronize()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int { return 4 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1 // Guide
        case 1: return 3 // Modes
        case 2: return 1 // Flick settings
        case 3: return 4 // Future
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "使い方"
        case 1: return "有効にする入力モード"
        case 2: return "フリック入力の詳細設定"
        case 3: return "開発中・実装予定の機能 (Coming Soon)"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0: return "設定アプリからキーボードを追加し、「フルアクセスを許可」をオンにしてください。"
        case 3: return "これらの機能は今後のアップデートで追加される予定です。"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.selectionStyle = .none
        
        if indexPath.section == 0 {
            cell.textLabel?.text = "設定 > 一般 > キーボード"
            cell.textLabel?.numberOfLines = 0
            cell.imageView?.image = UIImage(systemName: "gear")
            cell.imageView?.tintColor = .systemBlue
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                cell.textLabel?.text = "フリック入力 (Kana/ABC/123)"
                cell.detailTextLabel?.text = "日本語のフリック入力を使用します"
                cell.accessoryView = flickSwitch
                cell.imageView?.image = UIImage(systemName: "hand.point.up.left.fill")
                cell.imageView?.tintColor = .systemGreen
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "QWERTY (英語)"
                cell.detailTextLabel?.text = "標準的な英語キーボードを使用します"
                cell.accessoryView = qwertyEnglishSwitch
                cell.imageView?.image = UIImage(systemName: "keyboard")
                cell.imageView?.tintColor = .systemBlue
            } else if indexPath.row == 2 {
                cell.textLabel?.text = "QWERTY (ローマ字)"
                cell.detailTextLabel?.text = "ローマ字入力で日本語を入力します"
                cell.accessoryView = qwertyRomajiSwitch
                cell.imageView?.image = UIImage(systemName: "textformat.alt")
                cell.imageView?.tintColor = .systemRed
            }
        } else if indexPath.section == 2 {
            cell.textLabel?.text = "英字をQWERTY化"
            cell.detailTextLabel?.text = "フリック入力中の「ABC」を押した時にQWERTY英語キーボードに切り替えます"
            cell.detailTextLabel?.numberOfLines = 0
            cell.accessoryView = flickAlphabetQwertySwitch
            cell.imageView?.image = UIImage(systemName: "arrow.triangle.2.circlepath")
            cell.imageView?.tintColor = .systemOrange
        } else if indexPath.section == 3 {
            let fakeSwitch = UISwitch()
            fakeSwitch.isEnabled = false
            cell.accessoryView = fakeSwitch
            cell.textLabel?.textColor = .secondaryLabel
            cell.detailTextLabel?.textColor = .tertiaryLabel
            cell.imageView?.tintColor = .systemGray
            
            if indexPath.row == 0 {
                cell.textLabel?.text = "カスタムテーマ"
                cell.detailTextLabel?.text = "背景色や画像を自由に設定できます"
                cell.imageView?.image = UIImage(systemName: "paintpalette.fill")
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "ユーザー辞書"
                cell.detailTextLabel?.text = "よく使う単語を登録できます"
                cell.imageView?.image = UIImage(systemName: "book.fill")
            } else if indexPath.row == 2 {
                cell.textLabel?.text = "トグル入力 (ガラケー打ち)"
                cell.detailTextLabel?.text = "ボタンを何度も押して文字を切り替えます"
                cell.imageView?.image = UIImage(systemName: "candybarphone")
            } else if indexPath.row == 3 {
                cell.textLabel?.text = "片手モード"
                cell.detailTextLabel?.text = "キーボードを左右に寄せて片手で入力しやすくします"
                cell.imageView?.image = UIImage(systemName: "hand.point.up.left")
            }
        }
        
        return cell
    }
}

// MARK: - Updates
class UpdatesViewController: UITableViewController {
    
    let updates = [
        ("v1.2.0 - 新UI & ヘボン式拡張!", "・メインアプリのUIをモダンに刷新し、お知らせタブを追加しました。\n・SideStore等の無料署名環境でも設定が読み込めるようにApp Group取得ロジックを改良しました！\n・ローマ字入力の変換パターンを大幅追加 (qa→くぁ, va→ゔぁ 等)\n・SF Symbolsの導入でUIをiOSネイティブに刷新\n・フリックの英字大文字トグル機能 (a/A) を実装", "2026-08-13"),
        ("v1.1.0 - QWERTY長押し対応", "・QWERTYキーボードで長押しによる特殊文字入力に対応\n・設定アプリからキーボードモードの表示/非表示を切り替え可能に", "2026-08-11"),
        ("v1.0.0 - 初期リリース", "・フリック入力 (日本語/英字/数字)\n・QWERTY入力 (英語/ローマ字)\n・ダークモード対応", "2026-08-01")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "アップデート情報"
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView = UITableView(frame: .zero, style: .insetGrouped)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return updates.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return updates[section].0
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return updates[section].2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = updates[indexPath.section].1
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = .systemFont(ofSize: 15)
        cell.selectionStyle = .none
        return cell
    }
}
