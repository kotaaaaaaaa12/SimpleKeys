import UIKit

protocol FlickKeyboardDelegate: AnyObject {
    func flickKeyboard(_ keyboard: FlickKeyboardView, didInputText text: String)
    func flickKeyboardDidPressDelete(_ keyboard: FlickKeyboardView)
    func flickKeyboardDidPressDakuten(_ keyboard: FlickKeyboardView)
    func flickKeyboardDidPressReturn(_ keyboard: FlickKeyboardView)
    func flickKeyboardDidPressSpace(_ keyboard: FlickKeyboardView)
}

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
    
    private var activeTouch: UITouch?
    private var activeButton: UIView?
    private var startPoint: CGPoint = .zero
    private var popupView: UIView?
    private var popupLabel: UILabel?
    
    // State
    private var isDarkMode = false
    
    // Layout views
    private var containerView: UIView!
    private var keysMap: [UIView: FlickKey] = [:]
    
    // Basic Kana Keys
    private let kanaKeys: [[FlickKey]] = [
        [
            FlickKey(center: "あ", left: "い", up: "う", right: "え", down: "お"),
            FlickKey(center: "か", left: "き", up: "く", right: "け", down: "こ"),
            FlickKey(center: "さ", left: "し", up: "す", right: "せ", down: "そ")
        ],
        [
            FlickKey(center: "た", left: "ち", up: "つ", right: "て", down: "と"),
            FlickKey(center: "な", left: "に", up: "ぬ", right: "ね", down: "の"),
            FlickKey(center: "は", left: "ひ", up: "ふ", right: "へ", down: "ほ")
        ],
        [
            FlickKey(center: "ま", left: "み", up: "む", right: "め", down: "も"),
            FlickKey(center: "や", left: "「", up: "ゆ", right: "」", down: "よ"),
            FlickKey(center: "ら", left: "り", up: "る", right: "れ", down: "ろ")
        ],
        [
            // ゛゜小 is handled specially
            FlickKey(center: "゛゜小", left: nil, up: nil, right: nil, down: nil),
            FlickKey(center: "わ", left: "を", up: "ん", right: "ー", down: "〜"),
            FlickKey(center: "、", left: "。", up: "？", right: "！", down: "…")
        ]
    ]
    
    // Buttons we need references to
    private var globeButton: UIView!
    private var deleteButton: UIView!
    private var returnButton: UIView!
    private var spaceButton: UIView!
    private var shiftButton: UIView! // ABC, ☆123 etc
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        isMultipleTouchEnabled = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        isMultipleTouchEnabled = false
    }
    
    // MARK: - Setup
    
    private func setupView() {
        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4)
        ])
        
        // Main Horizontal Stack: [ Left Sidebar ] [ Center Grid ] [ Right Sidebar ]
        let mainStack = UIStackView()
        mainStack.axis = .horizontal
        mainStack.spacing = 6
        mainStack.distribution = .fillProportionally
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: containerView.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            mainStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        
        // 1. Left Sidebar
        let leftStack = UIStackView()
        leftStack.axis = .vertical
        leftStack.spacing = 6
        leftStack.distribution = .fillEqually
        
        let numBtn = createSpecialKey(title: "☆123")
        let abcBtn = createSpecialKey(title: "ABC")
        let kaomojiBtn = createSpecialKey(title: "^_^")
        globeButton = createSpecialKey(title: "🌐")
        
        leftStack.addArrangedSubview(numBtn)
        leftStack.addArrangedSubview(abcBtn)
        leftStack.addArrangedSubview(kaomojiBtn)
        leftStack.addArrangedSubview(globeButton)
        leftStack.widthAnchor.constraint(equalToConstant: 44).isActive = true
        mainStack.addArrangedSubview(leftStack)
        
        // 2. Center Grid
        let centerStack = UIStackView()
        centerStack.axis = .vertical
        centerStack.spacing = 6
        centerStack.distribution = .fillEqually
        
        for rowIndex in 0..<4 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 6
            rowStack.distribution = .fillEqually
            
            for colIndex in 0..<3 {
                let keyData = kanaKeys[rowIndex][colIndex]
                let isSpecial = (rowIndex == 3 && colIndex == 0)
                let btn = isSpecial ? createSpecialKey(title: keyData.center) : createFlickKey(keyData)
                if isSpecial { btn.accessibilityIdentifier = "dakuten" }
                rowStack.addArrangedSubview(btn)
            }
            centerStack.addArrangedSubview(rowStack)
        }
        
        // Add space bar below center grid? 
        // Apple puts Space in the bottom row, spanning across.
        // For simplicity, let's just make a 5th row in centerStack for Space
        spaceButton = createFlickKey(FlickKey(center: "空白", left: nil, up: nil, right: nil, down: nil))
        if let lbl = spaceButton.subviews.first as? UILabel { lbl.font = .systemFont(ofSize: 16) }
        centerStack.addArrangedSubview(spaceButton)
        
        mainStack.addArrangedSubview(centerStack)
        
        // 3. Right Sidebar
        let rightStack = UIStackView()
        rightStack.axis = .vertical
        rightStack.spacing = 6
        
        deleteButton = createSpecialKey(title: "⌫")
        returnButton = createSpecialKey(title: "改行")
        if let lbl = returnButton.subviews.first as? UILabel { lbl.font = .systemFont(ofSize: 16) }
        
        rightStack.addArrangedSubview(deleteButton)
        rightStack.addArrangedSubview(returnButton)
        
        deleteButton.heightAnchor.constraint(equalTo: rightStack.heightAnchor, multiplier: 0.2).isActive = true
        rightStack.widthAnchor.constraint(equalToConstant: 54).isActive = true
        mainStack.addArrangedSubview(rightStack)
    }
    
    // MARK: - Key Builders
    
    private func createFlickKey(_ keyData: FlickKey) -> UIView {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 6
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowOpacity = 0.3
        view.layer.shadowRadius = 0
        
        let label = UILabel()
        label.text = keyData.center
        label.font = .systemFont(ofSize: 22, weight: .regular)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        keysMap[view] = keyData
        return view
    }
    
    private func createSpecialKey(title: String) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.68, green: 0.70, blue: 0.74, alpha: 1.0)
        view.layer.cornerRadius = 6
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowOpacity = 0.3
        view.layer.shadowRadius = 0
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 18, weight: .regular)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
    }
    
    // MARK: - Public Accessors
    
    func getGlobeButton() -> UIView {
        return globeButton
    }
    
    // MARK: - Touch Handling (Responsive)
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, activeTouch == nil else { return }
        activeTouch = touch
        startPoint = touch.location(in: self)
        
        activeButton = findButton(at: startPoint)
        guard let btn = activeButton else { return }
        
        animateKeyDown(btn)
        
        if keysMap[btn] != nil {
            showPopup(for: btn)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, touch == activeTouch, let btn = activeButton else { return }
        let currentPoint = touch.location(in: self)
        
        if keysMap[btn] != nil {
            let dx = currentPoint.x - startPoint.x
            let dy = currentPoint.y - startPoint.y
            let direction = detectDirection(dx: dx, dy: dy)
            updatePopup(direction: direction, for: btn)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, touch == activeTouch else { return }
        finishTouch(at: touch.location(in: self))
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, touch == activeTouch else { return }
        finishTouch(at: touch.location(in: self), cancelled: true)
    }
    
    private func finishTouch(at point: CGPoint, cancelled: Bool = false) {
        guard let btn = activeButton else {
            activeTouch = nil
            return
        }
        
        animateKeyUp(btn)
        hidePopup()
        
        if !cancelled {
            if let keyData = keysMap[btn] {
                // Kana key
                let dx = point.x - startPoint.x
                let dy = point.y - startPoint.y
                let direction = detectDirection(dx: dx, dy: dy)
                if let text = textForDirection(direction, key: keyData) {
                    if text == "空白" {
                        delegate?.flickKeyboardDidPressSpace(self)
                    } else {
                        delegate?.flickKeyboard(self, didInputText: text)
                    }
                }
            } else {
                // Special key
                if btn == deleteButton {
                    delegate?.flickKeyboardDidPressDelete(self)
                } else if btn == returnButton {
                    delegate?.flickKeyboardDidPressReturn(self)
                } else if btn == globeButton {
                    // Handled by KeyboardViewController UIControl target if we converted to UIButton,
                    // but since it's UIView now, we must trigger it manually or let VC attach a recognizer.
                    // Actually, let's leave globe to standard target-action in VC if possible,
                    // but we changed it to UIView. We will fix this by providing a UIButton for globe.
                } else if btn.accessibilityIdentifier == "dakuten" {
                    delegate?.flickKeyboardDidPressDakuten(self)
                }
            }
        }
        
        activeTouch = nil
        activeButton = nil
    }
    
    private func findButton(at point: CGPoint) -> UIView? {
        // Deep search for the lowest level view that looks like a button
        func search(in view: UIView) -> UIView? {
            for sub in view.subviews.reversed() { // search top-most first
                if sub.frame.contains(view.convert(point, to: sub.superview)) {
                    if sub.backgroundColor != nil && sub.layer.cornerRadius > 0 {
                        return sub
                    }
                    if let found = search(in: sub) { return found }
                }
            }
            return nil
        }
        return search(in: self)
    }
    
    // MARK: - Flick Logic
    
    private func detectDirection(dx: CGFloat, dy: CGFloat) -> FlickDirection {
        let threshold: CGFloat = 25
        let distance = sqrt(dx * dx + dy * dy)
        
        if distance < threshold { return .center }
        
        if abs(dx) > abs(dy) {
            return dx < 0 ? .left : .right
        } else {
            return dy < 0 ? .up : .down
        }
    }
    
    private func textForDirection(_ direction: FlickDirection, key: FlickKey) -> String? {
        switch direction {
        case .center: return key.center
        case .left: return key.left ?? key.center
        case .up: return key.up ?? key.center
        case .right: return key.right ?? key.center
        case .down: return key.down ?? key.center
        }
    }
    
    // MARK: - Popup
    
    private func showPopup(for button: UIView) {
        guard keysMap[button] != nil else { return }
        
        let popup = UIView()
        popup.backgroundColor = UIColor.systemBlue
        popup.layer.cornerRadius = 8
        popup.layer.shadowColor = UIColor.black.cgColor
        popup.layer.shadowOpacity = 0.3
        popup.layer.shadowOffset = CGSize(width: 0, height: 2)
        popup.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        popup.addSubview(label)
        popupLabel = label
        
        updatePopup(direction: .center, for: button)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: popup.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: popup.centerYAnchor)
        ])
        
        if let window = button.window {
            window.addSubview(popup)
            let frame = button.convert(button.bounds, to: window)
            
            NSLayoutConstraint.activate([
                popup.widthAnchor.constraint(equalToConstant: 60),
                popup.heightAnchor.constraint(equalToConstant: 60),
                popup.centerXAnchor.constraint(equalTo: window.leadingAnchor, constant: frame.midX),
                popup.bottomAnchor.constraint(equalTo: window.topAnchor, constant: frame.minY - 10)
            ])
        }
        popupView = popup
    }
    
    private func updatePopup(direction: FlickDirection, for button: UIView) {
        guard let key = keysMap[button], let text = textForDirection(direction, key: key) else { return }
        popupLabel?.text = text
        
        // Optional: animate popup position slightly based on direction
        guard let popup = popupView, let window = button.window else { return }
        let frame = button.convert(button.bounds, to: window)
        let offset: CGFloat = 15
        var dx: CGFloat = 0, dy: CGFloat = 0
        switch direction {
        case .left: dx = -offset
        case .right: dx = offset
        case .up: dy = -offset
        case .down: dy = offset
        case .center: break
        }
        
        popup.transform = CGAffineTransform(translationX: dx, y: dy)
    }
    
    private func hidePopup() {
        popupView?.removeFromSuperview()
        popupView = nil
        popupLabel = nil
    }
    
    // MARK: - Animations
    
    private func animateKeyDown(_ view: UIView) {
        UIView.animate(withDuration: 0.05) {
            view.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            view.alpha = 0.8
        }
    }
    
    private func animateKeyUp(_ view: UIView) {
        UIView.animate(withDuration: 0.1) {
            view.transform = .identity
            view.alpha = 1.0
        }
    }
    
    // MARK: - Appearance
    
    func updateAppearance(isDark: Bool) {
        self.isDarkMode = isDark
        let bg = isDark ? UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1.0) : UIColor(red: 0.82, green: 0.84, blue: 0.86, alpha: 1.0)
        let keyBg = isDark ? UIColor(white: 0.35, alpha: 1.0) : .white
        let specialBg = isDark ? UIColor(white: 0.25, alpha: 1.0) : UIColor(red: 0.68, green: 0.70, blue: 0.74, alpha: 1.0)
        let textCol = isDark ? UIColor.white : UIColor.black
        
        backgroundColor = bg
        
        func apply(to view: UIView) {
            let isSpecial = (view == globeButton || view == deleteButton || view == returnButton || view.accessibilityIdentifier == "dakuten" || view.subviews.first(where: { ($0 as? UILabel)?.text == "☆123" || ($0 as? UILabel)?.text == "ABC" || ($0 as? UILabel)?.text == "^_^" }) != nil)
            
            if view.layer.cornerRadius > 0 && view != containerView && view.superview != nil {
                view.backgroundColor = isSpecial ? specialBg : keyBg
                if let lbl = view.subviews.first(where: { $0 is UILabel }) as? UILabel {
                    lbl.textColor = textCol
                }
            }
            for sub in view.subviews { apply(to: sub) }
        }
        apply(to: self)
    }
}
