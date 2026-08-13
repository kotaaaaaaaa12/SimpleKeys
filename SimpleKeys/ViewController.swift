import UIKit

class ViewController: UIViewController {

    private let styleSegmentedControl = UISegmentedControl(items: ["フリック", "QWERTY"])
    private let defaultModeSegmentedControl = UISegmentedControl(items: ["フリック", "QWERTY"])
    
    // Shared UserDefaults using the App Group
    private let sharedDefaults = UserDefaults(suiteName: "group.com.simplekeys.app")

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        
        setupUI()
        loadSettings()
    }
    
    private func setupUI() {
        let titleLabel = UILabel()
        titleLabel.text = "SimpleKeys 設定"
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        let instructionsLabel = UILabel()
        instructionsLabel.text = "設定 > 一般 > キーボード > キーボード > 新しいキーボードを追加 から SimpleKeys を追加してください。"
        instructionsLabel.font = .systemFont(ofSize: 14)
        instructionsLabel.textColor = .secondaryLabel
        instructionsLabel.numberOfLines = 0
        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionsLabel)
        
        // Default Mode Setting
        let defaultModeLabel = UILabel()
        defaultModeLabel.text = "初期キーボード"
        defaultModeLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        defaultModeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(defaultModeLabel)
        
        defaultModeSegmentedControl.selectedSegmentIndex = 0
        defaultModeSegmentedControl.addTarget(self, action: #selector(defaultModeChanged(_:)), for: .valueChanged)
        defaultModeSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(defaultModeSegmentedControl)
        
        let defaultModeDesc = UILabel()
        defaultModeDesc.text = "キーボードを開いたときに最初に表示されるレイアウトを選択します。"
        defaultModeDesc.font = .systemFont(ofSize: 13, weight: .regular)
        defaultModeDesc.textColor = .secondaryLabel
        defaultModeDesc.numberOfLines = 0
        defaultModeDesc.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(defaultModeDesc)
        
        // English Style Setting
        let styleLabel = UILabel()
        styleLabel.text = "英語入力のスタイル (ABCボタン)"
        styleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        styleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(styleLabel)
        
        styleSegmentedControl.selectedSegmentIndex = 0
        styleSegmentedControl.addTarget(self, action: #selector(styleChanged(_:)), for: .valueChanged)
        styleSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(styleSegmentedControl)
        
        let descLabel = UILabel()
        descLabel.text = "「日本語キーボード」から「ABCボタン」を押して英語入力に切り替えた際のキーボードレイアウトを選択します。"
        descLabel.font = .systemFont(ofSize: 13, weight: .regular)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            instructionsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            instructionsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            defaultModeLabel.topAnchor.constraint(equalTo: instructionsLabel.bottomAnchor, constant: 40),
            defaultModeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            defaultModeSegmentedControl.topAnchor.constraint(equalTo: defaultModeLabel.bottomAnchor, constant: 12),
            defaultModeSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            defaultModeSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            defaultModeDesc.topAnchor.constraint(equalTo: defaultModeSegmentedControl.bottomAnchor, constant: 12),
            defaultModeDesc.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            defaultModeDesc.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            styleLabel.topAnchor.constraint(equalTo: defaultModeDesc.bottomAnchor, constant: 40),
            styleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            styleSegmentedControl.topAnchor.constraint(equalTo: styleLabel.bottomAnchor, constant: 12),
            styleSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            styleSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            descLabel.topAnchor.constraint(equalTo: styleSegmentedControl.bottomAnchor, constant: 12),
            descLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }
    
    private func loadSettings() {
        let defaultMode = sharedDefaults?.integer(forKey: "defaultKeyboardMode") ?? 0
        defaultModeSegmentedControl.selectedSegmentIndex = defaultMode
        
        let style = sharedDefaults?.integer(forKey: "englishInputStyle") ?? 0
        styleSegmentedControl.selectedSegmentIndex = style
    }
    
    @objc private func defaultModeChanged(_ sender: UISegmentedControl) {
        sharedDefaults?.set(sender.selectedSegmentIndex, forKey: "defaultKeyboardMode")
        sharedDefaults?.synchronize()
    }
    
    @objc private func styleChanged(_ sender: UISegmentedControl) {
        sharedDefaults?.set(sender.selectedSegmentIndex, forKey: "englishInputStyle")
        sharedDefaults?.synchronize()
    }
}
