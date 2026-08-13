import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        let titleLabel = UILabel()
        titleLabel.text = "SimpleKeys"
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textAlignment = .center
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "シンプルで使いやすいキーボード"
        subtitleLabel.font = .systemFont(ofSize: 18)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .secondaryLabel
        
        let instructionsLabel = UILabel()
        instructionsLabel.text = "設定 > 一般 > キーボード > キーボード > 新しいキーボードを追加 から SimpleKeys を追加してください"
        instructionsLabel.font = .systemFont(ofSize: 16)
        instructionsLabel.textAlignment = .center
        instructionsLabel.numberOfLines = 0
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, instructionsLabel])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }
}
