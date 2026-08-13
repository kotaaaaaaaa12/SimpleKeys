import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let flickSwitch = UISwitch()
    private let flickAlphabetQwertySwitch = UISwitch()
    private let qwertyEnglishSwitch = UISwitch()
    private let qwertyRomajiSwitch = UISwitch()
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    // Shared UserDefaults using the App Group
    private let sharedDefaults = UserDefaults(suiteName: "group.com.simplekeys.app")

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "SimpleKeys 設定"
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
        // Prevent turning off all modes
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
    
    // MARK: - UITableViewDataSource & Delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1 // Guide
        case 1: return 3 // Modes (Flick, QWERTY En, QWERTY Ja)
        case 2: return 1 // Flick settings
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "使い方"
        case 1: return "有効にする入力モード"
        case 2: return "フリック入力の詳細設定"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0: return "設定アプリからキーボードを追加し、「フルアクセスを許可」をオンにしてください。"
        case 1: return "地球儀マークで切り替えるキーボードを選択します。"
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
            cell.imageView?.tintColor = .systemGray
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                cell.textLabel?.text = "フリック入力 (Kana/ABC/123)"
                cell.detailTextLabel?.text = "日本語のフリック入力を使用します"
                cell.accessoryView = flickSwitch
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "QWERTY (英語)"
                cell.detailTextLabel?.text = "標準的な英語キーボードを使用します"
                cell.accessoryView = qwertyEnglishSwitch
            } else if indexPath.row == 2 {
                cell.textLabel?.text = "QWERTY (ローマ字)"
                cell.detailTextLabel?.text = "ローマ字入力で日本語を入力します"
                cell.accessoryView = qwertyRomajiSwitch
            }
        } else if indexPath.section == 2 {
            cell.textLabel?.text = "英字をQWERTY化"
            cell.detailTextLabel?.text = "フリック入力中の「ABC」を押した時にQWERTY英語キーボードに切り替えます"
            cell.detailTextLabel?.numberOfLines = 0
            cell.accessoryView = flickAlphabetQwertySwitch
        }
        
        return cell
    }
}
