import UIKit

class ViewController: UIViewController {

    private let flickSwitch = UISwitch()
    private let flickAlphabetQwertySwitch = UISwitch()
    private let qwertyEnglishSwitch = UISwitch()
    private let qwertyRomajiSwitch = UISwitch()
    
    // Shared UserDefaults using the App Group
    private let sharedDefaults = UserDefaults(suiteName: "group.com.simplekeys.app")

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "SimpleKeys 設定"
        view.backgroundColor = .systemGroupedBackground
        
        setupModernUI()
        loadSettings()
    }
    
    private func setupModernUI() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 30
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        // Setup Guide Section
        let guideHeader = createSectionHeader(title: "使い方")
        let guideCard = createCardView()
        
        let guideLabel = UILabel()
        guideLabel.text = "設定 > 一般 > キーボード > キーボード > 新しいキーボードを追加 から SimpleKeys を追加してください。"
        guideLabel.font = .systemFont(ofSize: 15)
        guideLabel.textColor = .label
        guideLabel.numberOfLines = 0
        guideLabel.translatesAutoresizingMaskIntoConstraints = false
        
        guideCard.addSubview(guideLabel)
        NSLayoutConstraint.activate([
            guideLabel.topAnchor.constraint(equalTo: guideCard.topAnchor, constant: 16),
            guideLabel.leadingAnchor.constraint(equalTo: guideCard.leadingAnchor, constant: 16),
            guideLabel.trailingAnchor.constraint(equalTo: guideCard.trailingAnchor, constant: -16),
            guideLabel.bottomAnchor.constraint(equalTo: guideCard.bottomAnchor, constant: -16)
        ])
        
        let guideSection = UIStackView(arrangedSubviews: [guideHeader, guideCard])
        guideSection.axis = .vertical
        guideSection.spacing = 8
        stackView.addArrangedSubview(guideSection)
        
        // Keyboard Mode Section
        let modeHeader = createSectionHeader(title: "有効にする入力モード")
        
        flickSwitch.addTarget(self, action: #selector(settingsChanged), for: .valueChanged)
        flickAlphabetQwertySwitch.addTarget(self, action: #selector(settingsChanged), for: .valueChanged)
        qwertyEnglishSwitch.addTarget(self, action: #selector(settingsChanged), for: .valueChanged)
        qwertyRomajiSwitch.addTarget(self, action: #selector(settingsChanged), for: .valueChanged)
        
        let flickCard = createCardView()
        let flickSection = buildSettingsRow(card: flickCard, title: "フリック入力 (Kana/ABC/123)", description: "日本語のフリック入力を使用します。", control: flickSwitch)
        
        let flickAlphaCard = createCardView()
        let flickAlphaSection = buildSettingsRow(card: flickAlphaCard, title: "フリックの英字をQWERTY化", description: "フリック入力中の「ABC」を押した時にQWERTY英語キーボードに切り替えます。", control: flickAlphabetQwertySwitch)
        
        let qwertyEnCard = createCardView()
        let qwertyEnSection = buildSettingsRow(card: qwertyEnCard, title: "QWERTY (英語)", description: "標準的な英語キーボードを使用します。", control: qwertyEnglishSwitch)
        
        let qwertyJaCard = createCardView()
        let qwertyJaSection = buildSettingsRow(card: qwertyJaCard, title: "QWERTY (ローマ字)", description: "ローマ字入力で日本語を入力します。", control: qwertyRomajiSwitch)
        
        let modeStack = UIStackView(arrangedSubviews: [modeHeader, flickSection, flickAlphaSection, qwertyEnSection, qwertyJaSection])
        modeStack.axis = .vertical
        modeStack.spacing = 12
        stackView.addArrangedSubview(modeStack)
    }
    
    private func createSectionHeader(title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }
    
    private func createCardView() -> UIView {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 10
        view.layer.cornerCurve = .continuous
        return view
    }
    
    private func buildSettingsRow(card: UIView, title: String, description: String, control: UIView) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = .systemFont(ofSize: 13)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        
        control.translatesAutoresizingMaskIntoConstraints = false
        
        card.addSubview(titleLabel)
        card.addSubview(control)
        card.addSubview(descLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            
            control.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            control.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            control.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),
            
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            descLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            descLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        
        return card
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
        }
        
        sharedDefaults?.set(flickSwitch.isOn, forKey: "enableFlick")
        sharedDefaults?.set(flickAlphabetQwertySwitch.isOn, forKey: "flickAlphabetIsQwerty")
        sharedDefaults?.set(qwertyEnglishSwitch.isOn, forKey: "enableQwertyEnglish")
        sharedDefaults?.set(qwertyRomajiSwitch.isOn, forKey: "enableQwertyRomaji")
        sharedDefaults?.synchronize()
    }
}
