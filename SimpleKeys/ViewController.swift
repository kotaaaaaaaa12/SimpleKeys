import UIKit

class ViewController: UIViewController {

    private let styleSegmentedControl = UISegmentedControl(items: ["フリック", "QWERTY"])
    
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
            
            styleLabel.topAnchor.constraint(equalTo: instructionsLabel.bottomAnchor, constant: 40),
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
        // 0: Flick, 1: QWERTY
        let style = sharedDefaults?.integer(forKey: "englishInputStyle") ?? 0
        styleSegmentedControl.selectedSegmentIndex = style
    }
    
    @objc private func styleChanged(_ sender: UISegmentedControl) {
        sharedDefaults?.set(sender.selectedSegmentIndex, forKey: "englishInputStyle")
        sharedDefaults?.synchronize()
    }
}
