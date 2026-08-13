import UIKit

struct FlickKey {
    let center: String
    let left: String?
    let up: String?
    let right: String?
    let down: String?
}

enum KeyboardPage {
    case kana
    case alphabet
    case number
}

struct FlickKeyboardData {
    static let kanaKeys: [[FlickKey]] = [
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
            FlickKey(center: "゛゜小", left: nil, up: nil, right: nil, down: nil),
            FlickKey(center: "わ", left: "を", up: "ん", right: "ー", down: "〜"),
            FlickKey(center: "、", left: "。", up: "？", right: "！", down: "…")
        ]
    ]

    static let alphabetKeys: [[FlickKey]] = [
        [
            FlickKey(center: "@#/", left: "@", up: "#", right: "/", down: "&"),
            FlickKey(center: "ABC", left: "A", up: "B", right: "C", down: nil),
            FlickKey(center: "DEF", left: "D", up: "E", right: "F", down: nil)
        ],
        [
            FlickKey(center: "GHI", left: "G", up: "H", right: "I", down: nil),
            FlickKey(center: "JKL", left: "J", up: "K", right: "L", down: nil),
            FlickKey(center: "MNO", left: "M", up: "N", right: "O", down: nil)
        ],
        [
            FlickKey(center: "PQRS", left: "P", up: "Q", right: "R", down: "S"),
            FlickKey(center: "TUV", left: "T", up: "U", right: "V", down: nil),
            FlickKey(center: "WXYZ", left: "W", up: "X", right: "Y", down: "Z")
        ],
        [
            FlickKey(center: "a/A", left: nil, up: nil, right: nil, down: nil),
            FlickKey(center: "’\"()", left: "’", up: "\"", right: "(", down: ")"),
            FlickKey(center: ".,?!", left: ".", up: ",", right: "?", down: "!")
        ]
    ]

    static let numberKeys: [[FlickKey]] = [
        [
            FlickKey(center: "1", left: nil, up: nil, right: nil, down: nil),
            FlickKey(center: "2", left: nil, up: nil, right: nil, down: nil),
            FlickKey(center: "3", left: nil, up: nil, right: nil, down: nil)
        ],
        [
            FlickKey(center: "4", left: nil, up: nil, right: nil, down: nil),
            FlickKey(center: "5", left: nil, up: nil, right: nil, down: nil),
            FlickKey(center: "6", left: nil, up: nil, right: nil, down: nil)
        ],
        [
            FlickKey(center: "7", left: nil, up: nil, right: nil, down: nil),
            FlickKey(center: "8", left: nil, up: nil, right: nil, down: nil),
            FlickKey(center: "9", left: nil, up: nil, right: nil, down: nil)
        ],
        [
            FlickKey(center: "+-*/", left: "+", up: "-", right: "*", down: "/"),
            FlickKey(center: "0", left: nil, up: nil, right: nil, down: nil),
            FlickKey(center: ".,", left: ".", up: ",", right: nil, down: nil)
        ]
    ]
}

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
    private var popupLabels: [FlickDirection: UILabel] = [:]
    
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
    
    private var deleteTimer: Timer?
    
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
        
        // Define a 4x5 grid using layout guides
        var rowGuides: [UILayoutGuide] = []
        var colGuides: [UILayoutGuide] = []
        
        for i in 0..<4 {
            let rg = UILayoutGuide()
            containerView.addLayoutGuide(rg)
            rowGuides.append(rg)
        }
        
        for i in 0..<5 {
            let cg = UILayoutGuide()
            containerView.addLayoutGuide(cg)
            colGuides.append(cg)
        }
        
        // Setup Equal Heights/Widths for guides
        for i in 0..<4 {
            NSLayoutConstraint.activate([
                rowGuides[i].leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                rowGuides[i].trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
            ])
            if i > 0 {
                NSLayoutConstraint.activate([
                    rowGuides[i].heightAnchor.constraint(equalTo: rowGuides[0].heightAnchor),
                    rowGuides[i].topAnchor.constraint(equalTo: rowGuides[i-1].bottomAnchor, constant: 6)
                ])
            }
        }
        
        for i in 0..<5 {
            NSLayoutConstraint.activate([
                colGuides[i].topAnchor.constraint(equalTo: containerView.topAnchor),
                colGuides[i].bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
            if i > 0 {
                NSLayoutConstraint.activate([
                    colGuides[i].widthAnchor.constraint(equalTo: colGuides[0].widthAnchor),
                    colGuides[i].leadingAnchor.constraint(equalTo: colGuides[i-1].trailingAnchor, constant: 6)
                ])
            }
        }
        
        NSLayoutConstraint.activate([
            rowGuides[0].topAnchor.constraint(equalTo: containerView.topAnchor),
            rowGuides[3].bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
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
        
        globeButton = createSpecialKey(title: "🌐")
        place(view: globeButton, row: 2, col: 0, rowSpan: 2) // Spans row 2 and 3
        
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
        deleteButton.accessibilityIdentifier = "delete"
        place(view: deleteButton, row: 0, col: 4)
        
        spaceButton = createFlickKey(FlickKey(center: "空白", left: nil, up: nil, right: nil, down: nil))
        if let lbl = spaceButton.subviews.first as? UILabel { lbl.font = .systemFont(ofSize: 16) }
        place(view: spaceButton, row: 1, col: 4)
        
        returnButton = createSpecialKey(title: "改行")
        returnButton.accessibilityIdentifier = "return"
        if let lbl = returnButton.subviews.first as? UILabel { lbl.font = .systemFont(ofSize: 16) }
        place(view: returnButton, row: 2, col: 4, rowSpan: 2) // Spans row 2 and 3
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
        } else if btn.accessibilityIdentifier == "delete" {
            startDeleteTimer()
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
        stopDeleteTimer()
        guard let touch = touches.first, touch == activeTouch else { return }
        finishTouch(at: touch.location(in: self))
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        stopDeleteTimer()
        hidePopup()
        if let btn = activeButton { animateKeyUp(btn) }
        activeButton = nil
    }
    
    private func startDeleteTimer() {
        deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { [weak self] _ in
            self?.deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.flickKeyboardDidPressDelete(self)
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }
    
    private func stopDeleteTimer() {
        deleteTimer?.invalidate()
        deleteTimer = nil
    }
    
    private func finishTouch(at point: CGPoint, cancelled: Bool = false) {
        guard let btn = activeButton else {
            activeTouch = nil
            return
        }
        
        animateKeyUp(btn)
        hidePopup()
        
        if !cancelled {
            if btn.accessibilityIdentifier == "dakuten" {
                if currentPage == .alphabet {
                    isShifted.toggle()
                    updatePageUI()
                } else if currentPage == .kana {
                    delegate?.flickKeyboardDidPressDakuten(self)
                }
            } else if let keyData = keysMap[btn] {
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
                if btn.accessibilityIdentifier == "delete" {
                    delegate?.flickKeyboardDidPressDelete(self)
                } else if btn.accessibilityIdentifier == "return" {
                    delegate?.flickKeyboardDidPressReturn(self)
                } else if btn == globeButton {
                    // Handled by KeyboardViewController
                } else if btn.accessibilityIdentifier == "abc_switch" {
                    delegate?.flickKeyboardDidPressABC(self)
                } else if btn.accessibilityIdentifier == "num_switch" {
                    if currentPage == .number {
                        currentPage = .kana
                    } else {
                        currentPage = .number
                    }
                    updatePageUI()
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
        guard let keyData = keysMap[button] else { return }
        
        let popup = UIView()
        popup.translatesAutoresizingMaskIntoConstraints = false
        
        // Base sizes
        let keyWidth: CGFloat = 50
        let keyHeight: CGFloat = 50
        let spacing: CGFloat = 2
        
        let directions: [FlickDirection] = [.center, .left, .up, .right, .down]
        
        for dir in directions {
            if dir != .center && textForDirection(dir, key: keyData) == nil { continue }
            
            let label = UILabel()
            label.font = .systemFont(ofSize: 24, weight: .semibold)
            label.textColor = .black
            label.textAlignment = .center
            label.backgroundColor = .white
            label.layer.cornerRadius = 6
            label.layer.masksToBounds = true
            label.layer.shadowColor = UIColor.black.cgColor
            label.layer.shadowOpacity = 0.2
            label.layer.shadowOffset = CGSize(width: 0, height: 1)
            label.layer.shadowRadius = 2
            label.text = textForDirection(dir, key: keyData) ?? ""
            label.translatesAutoresizingMaskIntoConstraints = false
            popup.addSubview(label)
            popupLabels[dir] = label
            
            NSLayoutConstraint.activate([
                label.widthAnchor.constraint(equalToConstant: keyWidth),
                label.heightAnchor.constraint(equalToConstant: keyHeight)
            ])
            
            var centerXOffset: CGFloat = 0
            var centerYOffset: CGFloat = 0
            
            switch dir {
            case .center: break
            case .left: centerXOffset = -(keyWidth + spacing)
            case .right: centerXOffset = keyWidth + spacing
            case .up: centerYOffset = -(keyHeight + spacing)
            case .down: centerYOffset = keyHeight + spacing
            }
            
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: popup.centerXAnchor, constant: centerXOffset),
                label.centerYAnchor.constraint(equalTo: popup.centerYAnchor, constant: centerYOffset)
            ])
        }
        
        addSubview(popup)
        popupView = popup
        
        NSLayoutConstraint.activate([
            popup.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            popup.centerYAnchor.constraint(equalTo: button.centerYAnchor, constant: -10)
        ])
        
        updatePopup(direction: .center, for: button)
    }
    
    private func updatePopup(direction: FlickDirection, for button: UIView) {
        guard popupView != nil else { return }
        
        for (dir, label) in popupLabels {
            if dir == direction {
                label.backgroundColor = UIColor.systemBlue
                label.textColor = .white
                label.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                popupView?.bringSubviewToFront(label)
            } else {
                label.backgroundColor = .white
                label.textColor = .black
                label.transform = .identity
            }
        }
    }
    
    private func hidePopup() {
        popupView?.removeFromSuperview()
        popupView = nil
        popupLabels.removeAll()
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
        
        if let abcLbl = abcButton.subviews.first(where: { $0 is UILabel }) as? UILabel {
            abcLbl.text = (currentPage == .alphabet) ? "a/A" : "ABC"
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
            let isSpecial = (view == globeButton || view == deleteButton || view == returnButton || view.accessibilityIdentifier == "dakuten" || view.subviews.first(where: { ($0 as? UILabel)?.text == "☆123" || ($0 as? UILabel)?.text == "ABC" || ($0 as? UILabel)?.text == "a/A" }) != nil)
            
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
