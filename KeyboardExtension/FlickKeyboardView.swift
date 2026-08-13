import UIKit

protocol FlickKeyboardDelegate: AnyObject {
    func flickKeyboard(_ keyboard: FlickKeyboardView, didInputText text: String)
    func flickKeyboardDidPressDelete(_ keyboard: FlickKeyboardView)
    func flickKeyboardDidPressDakuten(_ keyboard: FlickKeyboardView)
    func flickKeyboardDidPressReturn(_ keyboard: FlickKeyboardView)
    func flickKeyboardDidPressSpace(_ keyboard: FlickKeyboardView)
    func flickKeyboardDidPressABC(_ keyboard: FlickKeyboardView)
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
    
    private(set) var currentPage: KeyboardPage = .kana
    private var isShifted = false // For ABC caps
    
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
    
    // Buttons we need references to
    private var globeButton: UIView!
    private var deleteButton: UIView!
    private var returnButton: UIView!
    private var spaceButton: UIView!
    private var abcButton: UIView!
    private var numButton: UIView!
    private var kaomojiButton: UIView!
    
    // Center grid buttons to update text
    private var gridButtons: [[UIView]] = []
    
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
    
    private var allButtons: [UIView] = []
    
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
        
        // Define a 5x5 grid using layout guides
        var rowGuides: [UILayoutGuide] = []
        var colGuides: [UILayoutGuide] = []
        
        for _ in 0..<5 {
            let rg = UILayoutGuide()
            containerView.addLayoutGuide(rg)
            rowGuides.append(rg)
            
            let cg = UILayoutGuide()
            containerView.addLayoutGuide(cg)
            colGuides.append(cg)
        }
        
        // Setup Equal Heights/Widths for guides
        for i in 0..<5 {
            NSLayoutConstraint.activate([
                rowGuides[i].leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                rowGuides[i].trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                colGuides[i].topAnchor.constraint(equalTo: containerView.topAnchor),
                colGuides[i].bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
            
            if i > 0 {
                NSLayoutConstraint.activate([
                    rowGuides[i].heightAnchor.constraint(equalTo: rowGuides[0].heightAnchor),
                    rowGuides[i].topAnchor.constraint(equalTo: rowGuides[i-1].bottomAnchor, constant: 6),
                    colGuides[i].widthAnchor.constraint(equalTo: colGuides[0].widthAnchor),
                    colGuides[i].leadingAnchor.constraint(equalTo: colGuides[i-1].trailingAnchor, constant: 6)
                ])
            }
        }
        
        // Pin outer guides
        NSLayoutConstraint.activate([
            rowGuides[0].topAnchor.constraint(equalTo: containerView.topAnchor),
            rowGuides[4].bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            colGuides[0].leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            colGuides[4].trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        
        // Helper to place a view in the grid
        func place(view: UIView, row: Int, col: Int, rowSpan: Int = 1, colSpan: Int = 1) {
            view.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(view)
            allButtons.append(view)
            
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: rowGuides[row].topAnchor),
                view.bottomAnchor.constraint(equalTo: rowGuides[row + rowSpan - 1].bottomAnchor),
                view.leadingAnchor.constraint(equalTo: colGuides[col].leadingAnchor),
                view.trailingAnchor.constraint(equalTo: colGuides[col + colSpan - 1].trailingAnchor)
            ])
        }
        
        // 1. Left Sidebar
        numButton = createSpecialKey(title: "☆123")
        numButton.accessibilityIdentifier = "num_switch"
        place(view: numButton, row: 0, col: 0)
        
        abcButton = createSpecialKey(title: "ABC")
        abcButton.accessibilityIdentifier = "abc_switch"
        place(view: abcButton, row: 1, col: 0)
        
        kaomojiButton = createSpecialKey(title: "^_^")
        kaomojiButton.accessibilityIdentifier = "kaomoji_switch"
        place(view: kaomojiButton, row: 2, col: 0)
        
        globeButton = createSpecialKey(title: "🌐")
        place(view: globeButton, row: 4, col: 0) // Globe in bottom left
        
        // 2. Center Grid
        gridButtons = Array(repeating: Array(repeating: UIView(), count: 3), count: 4)
        for rowIndex in 0..<4 {
            for colIndex in 0..<3 {
                let keyData = FlickKeyboardData.kanaKeys[rowIndex][colIndex]
                let isSpecial = (rowIndex == 3 && colIndex == 0)
                let btn = isSpecial ? createSpecialKey(title: keyData.center) : createFlickKey(keyData)
                if isSpecial { btn.accessibilityIdentifier = "dakuten" }
                
                place(view: btn, row: rowIndex, col: colIndex + 1)
                gridButtons[rowIndex][colIndex] = btn
            }
        }
        
        // 3. Right Sidebar
        deleteButton = createSpecialKey(title: "⌫")
        place(view: deleteButton, row: 0, col: 4)
        
        returnButton = createSpecialKey(title: "改行")
        if let lbl = returnButton.subviews.first as? UILabel { lbl.font = .systemFont(ofSize: 16) }
        place(view: returnButton, row: 1, col: 4, rowSpan: 3) // Spans rows 1,2,3
        
        // 4. Bottom Row
        spaceButton = createFlickKey(FlickKey(center: "空白", left: nil, up: nil, right: nil, down: nil))
        if let lbl = spaceButton.subviews.first as? UILabel { lbl.font = .systemFont(ofSize: 16) }
        place(view: spaceButton, row: 4, col: 1, colSpan: 4) // Spans from col 1 to 4
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
                    if currentPage == .alphabet {
                        isShifted.toggle()
                        updatePageUI()
                    } else if currentPage == .kana {
                        delegate?.flickKeyboardDidPressDakuten(self)
                    }
                } else if btn.accessibilityIdentifier == "abc_switch" {
                    delegate?.flickKeyboardDidPressABC(self)
                } else if btn.accessibilityIdentifier == "num_switch" {
                    if currentPage == .number {
                        currentPage = .kana
                    } else {
                        currentPage = .number
                    }
                    updatePageUI()
                } else if btn.accessibilityIdentifier == "kaomoji_switch" {
                    // TODO: Kaomoji
                }
            }
        }
        
        activeTouch = nil
        activeButton = nil
    }
    
    private func findButton(at point: CGPoint) -> UIView? {
        for btn in allButtons {
            let localPoint = self.convert(point, to: btn.superview)
            if btn.frame.contains(localPoint) {
                return btn
            }
        }
        return nil
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
        var text: String?
        switch direction {
        case .center: text = key.center
        case .left: text = key.left ?? key.center
        case .up: text = key.up ?? key.center
        case .right: text = key.right ?? key.center
        case .down: text = key.down ?? key.center
        }
        
        if currentPage == .alphabet && !isShifted {
            text = text?.lowercased()
        }
        
        return text
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
    
    // MARK: - Page Switching
    
    func switchToPage(_ page: KeyboardPage) {
        currentPage = page
        updatePageUI()
    }
    
    private func updatePageUI() {
        let keys: [[FlickKey]]
        switch currentPage {
        case .kana: keys = FlickKeyboardData.kanaKeys
        case .alphabet: keys = FlickKeyboardData.alphabetKeys
        case .number: keys = FlickKeyboardData.numberKeys
        }
        
        // Update sidebar highlights
        let isDark = self.isDarkMode
        let normalColor = isDark ? UIColor(white: 0.25, alpha: 1.0) : UIColor(red: 0.68, green: 0.70, blue: 0.74, alpha: 1.0)
        let activeColor = isDark ? UIColor.systemBlue : UIColor.systemBlue.withAlphaComponent(0.2)
        
        abcButton.backgroundColor = (currentPage == .alphabet) ? activeColor : normalColor
        numButton.backgroundColor = (currentPage == .number) ? activeColor : normalColor
        kaomojiButton.backgroundColor = normalColor
        
        if let kaomojiLbl = kaomojiButton.subviews.first(where: { $0 is UILabel }) as? UILabel {
            kaomojiLbl.text = (currentPage == .alphabet) ? "a/A" : "^_^"
        }
        
        // Update grid keys
        for rowIndex in 0..<4 {
            for colIndex in 0..<3 {
                let btn = gridButtons[rowIndex][colIndex]
                let keyData = keys[rowIndex][colIndex]
                keysMap[btn] = keyData
                
                if let label = btn.subviews.first(where: { $0 is UILabel }) as? UILabel {
                    var text = keyData.center
                    if currentPage == .alphabet && !isShifted {
                        text = text.lowercased()
                    }
                    if rowIndex == 3 && colIndex == 0 {
                        // The dakuten / shift button
                        if currentPage == .alphabet {
                            label.text = isShifted ? "⬆︎" : "⇧"
                            btn.accessibilityIdentifier = "dakuten" // Reuse for shift
                        } else if currentPage == .kana {
                            label.text = "゛゜小"
                            btn.accessibilityIdentifier = "dakuten"
                        } else {
                            label.text = text
                            btn.accessibilityIdentifier = nil
                        }
                        // Change styling for the special button
                        btn.backgroundColor = normalColor
                    } else {
                        label.text = text
                        btn.backgroundColor = isDark ? UIColor(white: 0.35, alpha: 1.0) : .white
                    }
                }
            }
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
