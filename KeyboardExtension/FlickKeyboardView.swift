import UIKit

/// フリック入力キーボードビュー
class FlickKeyboardView: UIView {
    
    // MARK: - Types
    
    struct FlickKey {
        let center: String
        let left: String?
        let up: String?
        let right: String?
        let down: String?
    }
    
    enum FlickDirection {
        case center, left, up, right, down
    }
    
    // MARK: - Properties
    
    weak var delegate: FlickKeyboardDelegate?
    
    private var flickKeys: [[FlickKey]] = []
    private var activeButton: UIButton?
    private var startPoint: CGPoint = .zero
    private var popupView: UIView?
    
    /// 濁点/半濁点/小文字モード
    private var isSmallMode = false
    
    // MARK: - Flick Key Definitions
    
    private static let kanaKeys: [[FlickKey]] = [
        // Row 1
        [
            FlickKey(center: "あ", left: "い", up: "う", right: "え", down: "お"),
            FlickKey(center: "か", left: "き", up: "く", right: "け", down: "こ"),
            FlickKey(center: "さ", left: "し", up: "す", right: "せ", down: "そ"),
            FlickKey(center: "た", left: "ち", up: "つ", right: "て", down: "と"),
            FlickKey(center: "な", left: "に", up: "ぬ", right: "ね", down: "の"),
        ],
        // Row 2
        [
            FlickKey(center: "は", left: "ひ", up: "ふ", right: "へ", down: "ほ"),
            FlickKey(center: "ま", left: "み", up: "む", right: "め", down: "も"),
            FlickKey(center: "や", left: "（", up: "ゆ", right: "）", down: "よ"),
            FlickKey(center: "ら", left: "り", up: "る", right: "れ", down: "ろ"),
            FlickKey(center: "わ", left: "を", up: "ん", right: "ー", down: "〜"),
        ],
    ]
    
    // 濁点・半濁点テーブル
    private static let dakutenMap: [Character: Character] = [
        "か": "が", "き": "ぎ", "く": "ぐ", "け": "げ", "こ": "ご",
        "さ": "ざ", "し": "じ", "す": "ず", "せ": "ぜ", "そ": "ぞ",
        "た": "だ", "ち": "ぢ", "つ": "づ", "て": "で", "と": "ど",
        "は": "ば", "ひ": "び", "ふ": "ぶ", "へ": "べ", "ほ": "ぼ",
        "う": "ゔ",
    ]
    
    private static let handakutenMap: [Character: Character] = [
        "は": "ぱ", "ひ": "ぴ", "ふ": "ぷ", "へ": "ぺ", "ほ": "ぽ",
    ]
    
    private static let smallMap: [Character: Character] = [
        "あ": "ぁ", "い": "ぃ", "う": "ぅ", "え": "ぇ", "お": "ぉ",
        "つ": "っ", "や": "ゃ", "ゆ": "ゅ", "よ": "ょ", "わ": "ゎ",
    ]
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        flickKeys = FlickKeyboardView.kanaKeys
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        flickKeys = FlickKeyboardView.kanaKeys
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 6
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -3),
        ])
        
        // Kana rows (2 rows × 5 keys)
        for (rowIndex, row) in flickKeys.enumerated() {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 4
            
            for (colIndex, key) in row.enumerated() {
                let button = createFlickButton(title: key.center)
                button.tag = rowIndex * 100 + colIndex
                
                let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleFlickPan(_:)))
                button.addGestureRecognizer(panGesture)
                
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleFlickTap(_:)))
                button.addGestureRecognizer(tapGesture)
                
                rowStack.addArrangedSubview(button)
            }
            
            rowStack.heightAnchor.constraint(equalToConstant: 46).isActive = true
            mainStack.addArrangedSubview(rowStack)
        }
        
        // Function row 3: 小゛゜  、  。  ？  ！
        let funcRow = UIStackView()
        funcRow.axis = .horizontal
        funcRow.distribution = .fillEqually
        funcRow.spacing = 4
        
        let dakutenBtn = createSpecialButton(title: "゛小")
        dakutenBtn.addTarget(self, action: #selector(dakutenPressed), for: .touchUpInside)
        funcRow.addArrangedSubview(dakutenBtn)
        
        let commaBtn = createFlickButton(title: "、")
        commaBtn.tag = 9000
        commaBtn.addTarget(self, action: #selector(punctuationPressed(_:)), for: .touchUpInside)
        funcRow.addArrangedSubview(commaBtn)
        
        let periodBtn = createFlickButton(title: "。")
        periodBtn.tag = 9001
        periodBtn.addTarget(self, action: #selector(punctuationPressed(_:)), for: .touchUpInside)
        funcRow.addArrangedSubview(periodBtn)
        
        let questionBtn = createFlickButton(title: "？")
        questionBtn.tag = 9002
        questionBtn.addTarget(self, action: #selector(punctuationPressed(_:)), for: .touchUpInside)
        funcRow.addArrangedSubview(questionBtn)
        
        let exclaimBtn = createFlickButton(title: "！")
        exclaimBtn.tag = 9003
        exclaimBtn.addTarget(self, action: #selector(punctuationPressed(_:)), for: .touchUpInside)
        funcRow.addArrangedSubview(exclaimBtn)
        
        funcRow.heightAnchor.constraint(equalToConstant: 42).isActive = true
        mainStack.addArrangedSubview(funcRow)
        
        // Bottom row: 🌐 space return ⌫
        let bottomRow = UIStackView()
        bottomRow.axis = .horizontal
        bottomRow.spacing = 4
        
        let globeBtn = createSpecialButton(title: "🌐")
        globeBtn.tag = 8000
        globeBtn.widthAnchor.constraint(equalToConstant: 44).isActive = true
        bottomRow.addArrangedSubview(globeBtn)
        // Globe button must be set up by the view controller
        
        let spaceBtn = createFlickButton(title: "スペース")
        spaceBtn.titleLabel?.font = .systemFont(ofSize: 14)
        spaceBtn.addTarget(self, action: #selector(spacePressed), for: .touchUpInside)
        bottomRow.addArrangedSubview(spaceBtn)
        
        let returnBtn = createSpecialButton(title: "確定")
        returnBtn.titleLabel?.font = .systemFont(ofSize: 14)
        returnBtn.addTarget(self, action: #selector(returnPressed), for: .touchUpInside)
        returnBtn.widthAnchor.constraint(equalToConstant: 72).isActive = true
        bottomRow.addArrangedSubview(returnBtn)
        
        let deleteBtn = createSpecialButton(title: "⌫")
        deleteBtn.addTarget(self, action: #selector(deletePressed), for: .touchUpInside)
        deleteBtn.widthAnchor.constraint(equalToConstant: 44).isActive = true
        bottomRow.addArrangedSubview(deleteBtn)
        
        bottomRow.heightAnchor.constraint(equalToConstant: 42).isActive = true
        mainStack.addArrangedSubview(bottomRow)
    }
    
    // MARK: - Button Factory
    
    private func createFlickButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        button.backgroundColor = .white
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 6
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowRadius = 0.5
        button.layer.shadowOpacity = 0.3
        button.clipsToBounds = false
        return button
    }
    
    private func createSpecialButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.backgroundColor = UIColor(red: 0.68, green: 0.70, blue: 0.74, alpha: 1.0)
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 6
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowRadius = 0.5
        button.layer.shadowOpacity = 0.3
        button.clipsToBounds = false
        return button
    }
    
    // MARK: - Globe Button Access
    
    /// 🌐ボタンを外部から取得（handleInputModeList設定用）
    func getGlobeButton() -> UIButton? {
        return findButton(withTag: 8000)
    }
    
    private func findButton(withTag tag: Int) -> UIButton? {
        func search(in view: UIView) -> UIButton? {
            if let button = view as? UIButton, button.tag == tag {
                return button
            }
            for sub in view.subviews {
                if let found = search(in: sub) { return found }
            }
            return nil
        }
        return search(in: self)
    }
    
    // MARK: - Flick Gesture Handling
    
    @objc private func handleFlickTap(_ gesture: UITapGestureRecognizer) {
        guard let button = gesture.view as? UIButton else { return }
        let key = flickKeyForButton(button)
        guard let key = key else { return }
        
        animateKeyPress(button)
        delegate?.flickKeyboard(self, didInputText: key.center)
    }
    
    @objc private func handleFlickPan(_ gesture: UIPanGestureRecognizer) {
        guard let button = gesture.view as? UIButton else { return }
        
        switch gesture.state {
        case .began:
            startPoint = gesture.location(in: button)
            activeButton = button
            showPopup(for: button)
            
        case .changed:
            let current = gesture.location(in: button)
            let dx = current.x - startPoint.x
            let dy = current.y - startPoint.y
            let direction = detectDirection(dx: dx, dy: dy)
            updatePopup(direction: direction, for: button)
            
        case .ended, .cancelled:
            let current = gesture.location(in: button)
            let dx = current.x - startPoint.x
            let dy = current.y - startPoint.y
            let direction = detectDirection(dx: dx, dy: dy)
            
            if let key = flickKeyForButton(button) {
                let text = textForDirection(direction, key: key)
                if let text = text {
                    animateKeyPress(button)
                    delegate?.flickKeyboard(self, didInputText: text)
                }
            }
            
            hidePopup()
            activeButton = nil
            
        default:
            break
        }
    }
    
    private func detectDirection(dx: CGFloat, dy: CGFloat) -> FlickDirection {
        let threshold: CGFloat = 20
        let distance = sqrt(dx * dx + dy * dy)
        
        if distance < threshold {
            return .center
        }
        
        if abs(dx) > abs(dy) {
            return dx < 0 ? .left : .right
        } else {
            return dy < 0 ? .up : .down
        }
    }
    
    private func flickKeyForButton(_ button: UIButton) -> FlickKey? {
        let tag = button.tag
        let row = tag / 100
        let col = tag % 100
        guard row < flickKeys.count, col < flickKeys[row].count else { return nil }
        return flickKeys[row][col]
    }
    
    private func textForDirection(_ direction: FlickDirection, key: FlickKey) -> String? {
        switch direction {
        case .center: return key.center
        case .left: return key.left
        case .up: return key.up
        case .right: return key.right
        case .down: return key.down
        }
    }
    
    // MARK: - Popup Preview
    
    private func showPopup(for button: UIButton) {
        let popup = UIView()
        popup.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
        popup.layer.cornerRadius = 8
        popup.translatesAutoresizingMaskIntoConstraints = false
        
        guard let key = flickKeyForButton(button) else { return }
        
        let label = UILabel()
        label.text = key.center
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        popup.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: popup.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: popup.centerYAnchor),
        ])
        
        // Show popup above the button
        if let window = button.window {
            window.addSubview(popup)
            let buttonFrame = button.convert(button.bounds, to: window)
            
            NSLayoutConstraint.activate([
                popup.widthAnchor.constraint(equalToConstant: 52),
                popup.heightAnchor.constraint(equalToConstant: 52),
                popup.centerXAnchor.constraint(equalTo: window.leadingAnchor, constant: buttonFrame.midX),
                popup.bottomAnchor.constraint(equalTo: window.topAnchor, constant: buttonFrame.minY - 4),
            ])
        }
        
        popupView = popup
    }
    
    private func updatePopup(direction: FlickDirection, for button: UIButton) {
        guard let popup = popupView,
              let label = popup.subviews.first as? UILabel,
              let key = flickKeyForButton(button) else { return }
        
        let text = textForDirection(direction, key: key)
        label.text = text ?? key.center
    }
    
    private func hidePopup() {
        popupView?.removeFromSuperview()
        popupView = nil
    }
    
    // MARK: - Key Press Animation
    
    private func animateKeyPress(_ button: UIButton) {
        UIView.animate(withDuration: 0.05, animations: {
            button.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                button.transform = .identity
            }
        }
    }
    
    // MARK: - Button Actions
    
    @objc private func dakutenPressed() {
        delegate?.flickKeyboardDidPressDakuten(self)
    }
    
    @objc private func punctuationPressed(_ sender: UIButton) {
        guard let text = sender.titleLabel?.text else { return }
        animateKeyPress(sender)
        delegate?.flickKeyboard(self, didInputText: text)
    }
    
    @objc private func spacePressed() {
        delegate?.flickKeyboard(self, didInputText: " ")
    }
    
    @objc private func returnPressed() {
        delegate?.flickKeyboard(self, didInputText: "\n")
    }
    
    @objc private func deletePressed() {
        delegate?.flickKeyboardDidPressDelete(self)
    }
    
    // MARK: - Appearance
    
    func updateAppearance(isDark: Bool) {
        if isDark {
            backgroundColor = UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1.0)
            updateColors(
                keyBg: UIColor(white: 0.35, alpha: 1.0),
                specialBg: UIColor(white: 0.25, alpha: 1.0),
                textColor: .white,
                shadowColor: UIColor.black.cgColor
            )
        } else {
            backgroundColor = UIColor(red: 0.82, green: 0.84, blue: 0.86, alpha: 1.0)
            updateColors(
                keyBg: .white,
                specialBg: UIColor(red: 0.68, green: 0.70, blue: 0.74, alpha: 1.0),
                textColor: .black,
                shadowColor: UIColor(white: 0.5, alpha: 1.0).cgColor
            )
        }
    }
    
    private func updateColors(keyBg: UIColor, specialBg: UIColor, textColor: UIColor, shadowColor: CGColor) {
        func apply(to view: UIView) {
            if let button = view as? UIButton {
                button.setTitleColor(textColor, for: .normal)
                button.layer.shadowColor = shadowColor
                let title = button.titleLabel?.text ?? ""
                let isSpecial = ["🌐", "⌫", "確定", "゛小"].contains(title)
                button.backgroundColor = isSpecial ? specialBg : keyBg
            }
            for sub in view.subviews {
                apply(to: sub)
            }
        }
        apply(to: self)
    }
}

// MARK: - Delegate Protocol

protocol FlickKeyboardDelegate: AnyObject {
    func flickKeyboard(_ keyboard: FlickKeyboardView, didInputText text: String)
    func flickKeyboardDidPressDelete(_ keyboard: FlickKeyboardView)
    func flickKeyboardDidPressDakuten(_ keyboard: FlickKeyboardView)
}
