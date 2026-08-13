import UIKit

class ViewController: UIViewController {

    private let styleSegmentedControl = UISegmentedControl(items: ["フリック", "QWERTY"])
    private let defaultModeSegmentedControl = UISegmentedControl(items: ["フリック", "QWERTY"])
    
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
        let modeHeader = createSectionHeader(title: "初期キーボード")
        let modeCard = createCardView()
        
        defaultModeSegmentedControl.selectedSegmentIndex = 0
        defaultModeSegmentedControl.addTarget(self, action: #selector(defaultModeChanged(_:)), for: .valueChanged)
        
        let modeSection = buildSettingsRow(
            card: modeCard,
            title: "初期レイアウト",
            description: "キーボードを開いたときに最初に表示されるレイアウトを選択します。",
            control: defaultModeSegmentedControl
        )
        
        let modeStack = UIStackView(arrangedSubviews: [modeHeader, modeSection])
        modeStack.axis = .vertical
        modeStack.spacing = 8
        stackView.addArrangedSubview(modeStack)
        
        // English Style Section
        let styleHeader = createSectionHeader(title: "英語入力のスタイル")
        let styleCard = createCardView()
        
        styleSegmentedControl.selectedSegmentIndex = 0
        styleSegmentedControl.addTarget(self, action: #selector(styleChanged(_:)), for: .valueChanged)
        
        let styleSection = buildSettingsRow(
            card: styleCard,
            title: "ABCボタンの動作",
            description: "「日本語キーボード」から「ABCボタン」を押して英語入力に切り替えた際のキーボードレイアウトを選択します。",
            control: styleSegmentedControl
        )
        
        let styleStack = UIStackView(arrangedSubviews: [styleHeader, styleSection])
        styleStack.axis = .vertical
        styleStack.spacing = 8
        stackView.addArrangedSubview(styleStack)
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
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            
            control.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            control.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            control.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            
            descLabel.topAnchor.constraint(equalTo: control.bottomAnchor, constant: 12),
            descLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            descLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            descLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        
        return card
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
