import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        
        setupUI()
    }
    
    private func setupUI() {
        let titleLabel = UILabel()
        titleLabel.text = "SimpleKeys"
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        let instructionsLabel = UILabel()
        instructionsLabel.text = "設定 > 一般 > キーボード > キーボード > 新しいキーボードを追加 から SimpleKeys を追加してください。\n\n※ キーボードへのフルアクセスを許可する必要はありません。"
        instructionsLabel.font = .systemFont(ofSize: 15)
        instructionsLabel.textColor = .secondaryLabel
        instructionsLabel.numberOfLines = 0
        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionsLabel)
        
        let tipsTitle = UILabel()
        tipsTitle.text = "Tips"
        tipsTitle.font = .systemFont(ofSize: 20, weight: .semibold)
        tipsTitle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tipsTitle)
        
        let tipsDesc = UILabel()
        tipsDesc.text = "・「ABC」ボタンを長押しすると、英語入力のレイアウトを「フリック」と「QWERTY」で切り替えることができます。\n・「あいう」ボタンで瞬時に日本語フリックに戻ります。"
        tipsDesc.font = .systemFont(ofSize: 15)
        tipsDesc.textColor = .label
        tipsDesc.numberOfLines = 0
        tipsDesc.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tipsDesc)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            instructionsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            instructionsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            tipsTitle.topAnchor.constraint(equalTo: instructionsLabel.bottomAnchor, constant: 40),
            tipsTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            tipsDesc.topAnchor.constraint(equalTo: tipsTitle.bottomAnchor, constant: 12),
            tipsDesc.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tipsDesc.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }
}
