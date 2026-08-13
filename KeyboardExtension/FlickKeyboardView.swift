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
            FlickKey(center: "､｡?!", left: "。", up: "？", right: "！", down: "…")
        ]
    ]

    static let alphabetKeys: [[FlickKey]] = [
        [
            FlickKey(center: "@#/&_", left: "#", up: "/", right: "&", down: "_"),
            FlickKey(center: "ABC", left: "B", up: "C", right: nil, down: nil),
            FlickKey(center: "DEF", left: "E", up: "F", right: nil, down: nil)
        ],
        [
            FlickKey(center: "GHI", left: "H", up: "I", right: nil, down: nil),
            FlickKey(center: "JKL", left: "K", up: "L", right: nil, down: nil),
            FlickKey(center: "MNO", left: "N", up: "O", right: nil, down: nil)
        ],
        [
            FlickKey(center: "PQRS", left: "Q", up: "R", right: "S", down: nil),
            FlickKey(center: "TUV", left: "U", up: "V", right: nil, down: nil),
            FlickKey(center: "WXYZ", left: "X", up: "Y", right: "Z", down: nil)
        ],
        [
            FlickKey(center: "a/A", left: nil, up: nil, right: nil, down: nil),
            FlickKey(center: "’\"()", left: "’", up: "\"", right: "(", down: ")"),
            FlickKey(center: ".,?!", left: ".", up: ",", right: "?", down: "!")
        ]
    ]

    static let numberKeys: [[FlickKey]] = [
        [
            FlickKey(center: "1", left: "☆", up: "♪", right: "→", down: nil),
            FlickKey(center: "2", left: "¥", up: "$", right: "€", down: nil),
            FlickKey(center: "3", left: "%", up: "°", right: "#", down: nil)
        ],
        [
            FlickKey(center: "4", left: "〇", up: "＊", right: "・", down: nil),
            FlickKey(center: "5", left: "＋", up: "×", right: "÷", down: nil),
            FlickKey(center: "6", left: "＜", up: "＝", right: "＞", down: nil)
        ],
        [
            FlickKey(center: "7", left: "「", up: "」", right: "：", down: nil),
            FlickKey(center: "8", left: "〒", up: "々", right: "〆", down: nil),
            FlickKey(center: "9", left: "＾", up: "｜", right: "＼", down: nil)
        ],
        [
            FlickKey(center: "()[]", left: ")", up: "[", right: "]", down: nil),
            FlickKey(center: "0", left: "～", up: "…", right: nil, down: nil),
            FlickKey(center: ",.-/", left: ".", up: "-", right: "/", down: nil)
        ]
    ]
}

protocol FlickKeyboardDelegate: AnyObject {
    func flickKeyboard(_ keyboard: FlickKeyboardView, didInputText text: String, direction: FlickKeyboardView.FlickDirection)
    func flickKeyboardDidPressDelete(_ keyboard: FlickKeyboardView)
    func flickKeyboardDidPressDakuten(_ keyboard: FlickKeyboardView)
    func flickKeyboardDidPressReturn(_ keyboard: FlickKeyboardView)
    func flickKeyboardDidPressSpace(_ keyboard: FlickKeyboardView)
    func flickKeyboardDidPressABC(_ keyboard: FlickKeyboardView)
    func flickKeyboardDidFlickDeleteLeft(_ keyboard: FlickKeyboardView)
    func flickKeyboardDidFlickDeleteUp(_ keyboard: FlickKeyboardView)
    func flickKeyboardDidSwipeSpace(_ keyboard: FlickKeyboardView, direction: FlickKeyboardView.FlickDirection)
    func flickKeyboardDidBeginSpaceDrag(_ keyboard: FlickKeyboardView)
    func flickKeyboardDidEndSpaceDrag(_ keyboard: FlickKeyboardView)
    func flickKeyboardDidPressGlobe(_ keyboard: FlickKeyboardView)
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
    
    private var activeTouches: [UITouch: UIView] = [:]
    private var startPoints: [UITouch: CGPoint] = [:]
    private var popupViews: [UITouch: UIView] = [:]
    private var popupLabelsDict: [UITouch: [FlickDirection: UILabel]] = [:]
    private var popupBgLayers: [UITouch: CAShapeLayer] = [:]
    private var popupTimers: [UITouch: Timer] = [:]
    private var fullPopupModes: [UITouch: Bool] = [:]
    
    private var spaceTimers: [UITouch: Timer] = [:]
    private var isSpaceDragging: [UITouch: Bool] = [:]
    
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
    private var faceButton: UIView!
    
    private var deleteTimer: Timer?
    
    // Center grid buttons to update text
    private var gridButtons: [[UIView]] = []
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        isMultipleTouchEnabled = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        isMultipleTouchEnabled = true
    }
    
    // MARK: - Setup
    
    private var allButtons: [UIView] = []
    
    private func setupView() {
        self.clipsToBounds = false
        containerView = UIView()
        containerView.clipsToBounds = false
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
        
        for _ in 0..<4 {
            let rg = UILayoutGuide()
            containerView.addLayoutGuide(rg)
            rowGuides.append(rg)
        }
        
        for _ in 0..<5 {
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
        
        globeButton = createSpecialImageKey(systemName: "globe")
        globeButton.accessibilityIdentifier = "globe"
        place(view: globeButton, row: 3, col: 0)
        
        faceButton = createSpecialKey(title: "^_^")
        faceButton.accessibilityIdentifier = "face_mark"
        place(view: faceButton, row: 2, col: 0)
        
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
        deleteButton = createSpecialImageKey(systemName: "delete.left")
        deleteButton.accessibilityIdentifier = "delete"
        keysMap[deleteButton] = FlickKey(center: "⌫", left: "文消", up: "全消", right: nil, down: nil)
        place(view: deleteButton, row: 0, col: 4)
        
        spaceButton = createFlickKey(FlickKey(center: "空白", left: nil, up: nil, right: nil, down: nil))
        spaceButton.accessibilityIdentifier = "space"
        if let lbl = spaceButton.viewWithTag(100) as? UILabel { lbl.font = .systemFont(ofSize: 16) }
        place(view: spaceButton, row: 1, col: 4)
        
        returnButton = createSpecialKey(title: "改行")
        returnButton.accessibilityIdentifier = "return"
        if let lbl = returnButton.subviews.first as? UILabel { 
            lbl.font = .systemFont(ofSize: 16)
            lbl.tag = 999 // Tag to identify the label easily
        }
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
        
        let centerLabel = UILabel()
        centerLabel.tag = 100
        centerLabel.font = .systemFont(ofSize: 22, weight: .regular)
        centerLabel.textAlignment = .center
        centerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(centerLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.tag = 105
        subtitleLabel.font = .systemFont(ofSize: 10, weight: .medium)
        subtitleLabel.textColor = .lightGray
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            centerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -5),
            
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4)
        ])
        
        updateHints(for: view, keyData: keyData, isShifted: isShifted)
        keysMap[view] = keyData
        return view
    }
    
    private func updateHints(for btn: UIView, keyData: FlickKey, isShifted: Bool) {
        if let lbl = btn.viewWithTag(100) as? UILabel {
            var text = keyData.center
            if currentPage == .alphabet && !isShifted {
                text = text.uppercased() // User wants uppercase
            }
            lbl.text = text
            if text.count >= 4 {
                lbl.font = .systemFont(ofSize: 16, weight: .regular)
            } else if currentPage == .alphabet && text.count >= 3 {
                lbl.font = .systemFont(ofSize: 17, weight: .regular)
            } else {
                lbl.font = .systemFont(ofSize: 22, weight: .regular)
            }
            // Center the label if there is no subtitle
            if currentPage == .kana || text.count >= 4 || (currentPage == .alphabet && keyData.center.count >= 3 && keyData.center.first?.isLetter == true) {
                lbl.transform = CGAffineTransform(translationX: 0, y: 5)
            } else {
                lbl.transform = .identity
            }
        }
        
        if let sub = btn.viewWithTag(105) as? UILabel {
            if currentPage == .kana {
                sub.text = ""
            } else {
                // If it's alphabet mode and it's a letter key (ABC, DEF, etc), hide the hint
                if currentPage == .alphabet && (keyData.center.count >= 3 && keyData.center.first?.isLetter == true) {
                    sub.text = ""
                } else if keyData.center.count >= 4 {
                    sub.text = ""
                } else {
                    var hints = [String]()
                    if let left = keyData.left { hints.append(left) }
                    if let up = keyData.up { hints.append(up) }
                    if let right = keyData.right { hints.append(right) }
                    
                    var hintStr = hints.joined(separator: " ")
                    if currentPage == .alphabet && !isShifted {
                        hintStr = hintStr.uppercased()
                    }
                    sub.text = hintStr
                }
            }
        }
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
        label.tag = 100
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
    
    private func createSpecialImageKey(systemName: String) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.68, green: 0.70, blue: 0.74, alpha: 1.0)
        view.layer.cornerRadius = 6
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowOpacity = 0.3
        view.layer.shadowRadius = 0
        
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
        let imageView = UIImageView(image: UIImage(systemName: systemName, withConfiguration: config))
        imageView.tintColor = .black
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
    }
    
    func getGlobeButton() -> UIView {
        return globeButton
    }
    
    // MARK: - Label Fade (Blur)
    
    func setKeysAlpha(_ alpha: CGFloat) {
        for btn in allButtons {
            if btn.accessibilityIdentifier == "space" { continue }
            for subview in btn.subviews {
                if let label = subview as? UILabel {
                    label.alpha = alpha
                } else if let imageView = subview as? UIImageView {
                    imageView.alpha = alpha
                }
            }
        }
    }
    
    // MARK: - Touch Handling (Responsive)
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let point = touch.location(in: containerView)
            var bestBtn: UIView? = nil
            var minDistance: CGFloat = 10000
            for btn in allButtons {
                if btn.frame.contains(point) {
                    bestBtn = btn
                    minDistance = 0
                    break
                }
                let cx = btn.frame.midX
                let cy = btn.frame.midY
                let dist = (cx - point.x) * (cx - point.x) + (cy - point.y) * (cy - point.y)
                if dist < minDistance {
                    minDistance = dist
                    bestBtn = btn
                }
            }
            if let btn = bestBtn, minDistance < 4000 {
                activeTouches[touch] = btn
                startPoints[touch] = point
                animateKeyDown(btn)
                if keysMap[btn] != nil {
                    let timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
                        guard let self = self else { return }
                        if self.activeTouches[touch] == btn {
                            self.popupTimers.removeValue(forKey: touch)
                            self.showPopup(for: touch, button: btn, isFull: true)
                        }
                    }
                    popupTimers[touch] = timer
                } else if btn.accessibilityIdentifier == "delete" {
                    startDeleteTimer()
                } else if btn.accessibilityIdentifier == "space" {
                    let timer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { [weak self] _ in
                        guard let self = self else { return }
                        if self.activeTouches[touch] == btn {
                            self.isSpaceDragging[touch] = true
                            self.delegate?.flickKeyboardDidBeginSpaceDrag(self)
                        }
                    }
                    spaceTimers[touch] = timer
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            guard let btn = activeTouches[touch], let start = startPoints[touch] else { continue }
            let currentPoint = touch.location(in: containerView)
            
            if btn.accessibilityIdentifier == "space" {
                let isDragging = isSpaceDragging[touch] ?? false
                let dx = currentPoint.x - start.x
                
                if isDragging {
                    if dx > 20 {
                        delegate?.flickKeyboardDidSwipeSpace(self, direction: .right)
                        startPoints[touch] = CGPoint(x: start.x + 20, y: start.y)
                    } else if dx < -20 {
                        delegate?.flickKeyboardDidSwipeSpace(self, direction: .left)
                        startPoints[touch] = CGPoint(x: start.x - 20, y: start.y)
                    }
                } else {
                    if abs(dx) > 15 {
                        spaceTimers[touch]?.invalidate()
                        spaceTimers.removeValue(forKey: touch)
                        isSpaceDragging[touch] = true
                        startPoints[touch] = currentPoint
                        delegate?.flickKeyboardDidBeginSpaceDrag(self)
                    }
                }
                continue
            }
            
            if keysMap[btn] != nil {
                let dx = currentPoint.x - start.x
                let dy = currentPoint.y - start.y
                let direction = detectDirection(dx: dx, dy: dy)
                
                if popupViews[touch] == nil && direction != .center {
                    popupTimers[touch]?.invalidate()
                    popupTimers.removeValue(forKey: touch)
                    showPopup(for: touch, button: btn, isFull: false)
                }
                
                updatePopup(direction: direction, for: touch)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            popupTimers[touch]?.invalidate()
            popupTimers.removeValue(forKey: touch)
            spaceTimers[touch]?.invalidate()
            spaceTimers.removeValue(forKey: touch)
            
            if activeTouches[touch]?.accessibilityIdentifier == "delete" {
                stopDeleteTimer()
            }
            
            var cancelled = false
            if activeTouches[touch]?.accessibilityIdentifier == "space", let isDragging = isSpaceDragging[touch], isDragging {
                cancelled = true
                isSpaceDragging.removeValue(forKey: touch)
                delegate?.flickKeyboardDidEndSpaceDrag(self)
            }
            
            finishTouch(touch: touch, cancelled: cancelled)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            popupTimers[touch]?.invalidate()
            popupTimers.removeValue(forKey: touch)
            spaceTimers[touch]?.invalidate()
            spaceTimers.removeValue(forKey: touch)
            
            if activeTouches[touch]?.accessibilityIdentifier == "delete" {
                stopDeleteTimer()
            }
            
            if activeTouches[touch]?.accessibilityIdentifier == "space", let isDragging = isSpaceDragging[touch], isDragging {
                isSpaceDragging.removeValue(forKey: touch)
                delegate?.flickKeyboardDidEndSpaceDrag(self)
            }
            
            finishTouch(touch: touch, cancelled: true)
        }
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
    
    private func finishTouch(touch: UITouch, cancelled: Bool = false) {
        guard let btn = activeTouches[touch] else { return }
        
        animateKeyUp(btn)
        hidePopup(for: touch)
        
        if !cancelled || (cancelled && btn.accessibilityIdentifier != "delete" && btn.accessibilityIdentifier != "return" && btn.accessibilityIdentifier != "globe" && btn.accessibilityIdentifier != "abc_switch" && btn.accessibilityIdentifier != "num_switch" && btn.accessibilityIdentifier != "face_mark" && btn.accessibilityIdentifier != "space") {
            if btn.accessibilityIdentifier == "dakuten" {
                if !cancelled {
                    delegate?.flickKeyboardDidPressDakuten(self)
                }
            } else if let keyData = keysMap[btn] {
                let point = touch.location(in: containerView)
                let startPoint = startPoints[touch] ?? point
                let dx = point.x - startPoint.x
                let dy = point.y - startPoint.y
                let direction = detectDirection(dx: dx, dy: dy)
                if !cancelled || direction != .center {
                    if btn.accessibilityIdentifier == "delete" {
                        if direction == .left {
                            delegate?.flickKeyboardDidFlickDeleteLeft(self)
                        } else if direction == .up {
                            delegate?.flickKeyboardDidFlickDeleteUp(self)
                        } else {
                            delegate?.flickKeyboardDidPressDelete(self)
                        }
                    } else if let text = textForDirection(direction, key: keyData) {
                        if text == "空白" {
                            delegate?.flickKeyboardDidPressSpace(self)
                        } else {
                            delegate?.flickKeyboard(self, didInputText: text, direction: direction)
                        }
                    }
                }
            } else {
                if !cancelled {
                    if btn.accessibilityIdentifier == "return" {
                        delegate?.flickKeyboardDidPressReturn(self)
                    } else if btn.accessibilityIdentifier == "globe" {
                        delegate?.flickKeyboardDidPressGlobe(self)
                    } else if btn.accessibilityIdentifier == "abc_switch" {
                        delegate?.flickKeyboardDidPressABC(self)
                    } else if btn.accessibilityIdentifier == "num_switch" {
                        if currentPage == .number {
                            currentPage = .kana
                        } else {
                            currentPage = .number
                        }
                        updatePageUI()
                    } else if btn.accessibilityIdentifier == "face_mark" {
                        delegate?.flickKeyboard(self, didInputText: "^_^", direction: .center)
                    } else if btn.accessibilityIdentifier == "space" {
                        delegate?.flickKeyboardDidPressSpace(self)
                    }
                }
            }
        }
        
        activeTouches.removeValue(forKey: touch)
        startPoints.removeValue(forKey: touch)
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
        case .center:
            if currentPage == .alphabet && key.center.count > 1 && key.center != "a/A" {
                text = String(key.center.first!)
            } else if currentPage == .kana && key.center == "､｡?!" {
                text = "、"
            } else if currentPage == .number && key.center == "()[]" {
                text = "("
            } else if currentPage == .number && key.center == ",.-/" {
                text = ","
            } else {
                text = key.center
            }
        case .left: text = key.left
        case .up: text = key.up
        case .right: text = key.right
        case .down: text = key.down
        }
        
        if currentPage == .alphabet && !isShifted {
            text = text?.lowercased()
        }
        
        return text
    }
    
    // MARK: - Popup
    
    private func showPopup(for touch: UITouch, button: UIView, isFull: Bool) {
        guard let keyData = keysMap[button] else { return }
        
        fullPopupModes[touch] = isFull
        
        let popup = UIView()
        popup.translatesAutoresizingMaskIntoConstraints = false
        
        let keyWidth = button.bounds.width
        let keyHeight = button.bounds.height
        let spacing: CGFloat = 6.0
        
        let directions: [FlickDirection] = [.center, .left, .up, .right, .down]
        var labels: [FlickDirection: UILabel] = [:]
        
        for dir in directions {
            if dir != .center && textForDirection(dir, key: keyData) == nil { continue }
            
            let label = UILabel()
            label.font = .systemFont(ofSize: 22, weight: .semibold)
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
            labels[dir] = label
            
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
        
        let bgLayer = CAShapeLayer()
        bgLayer.fillColor = UIColor.white.cgColor
        bgLayer.shadowColor = UIColor.black.cgColor
        bgLayer.shadowOpacity = 0.2
        bgLayer.shadowOffset = CGSize(width: 0, height: 1)
        bgLayer.shadowRadius = 2
        popup.layer.insertSublayer(bgLayer, at: 0)
        popupBgLayers[touch] = bgLayer
        
        addSubview(popup)
        popupViews[touch] = popup
        popupLabelsDict[touch] = labels
        
        NSLayoutConstraint.activate([
            popup.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            popup.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
        
        updatePopup(direction: .center, for: touch)
    }
    
    private func updatePopup(direction: FlickDirection, for touch: UITouch) {
        guard let popup = popupViews[touch], let labels = popupLabelsDict[touch] else { return }
        let isFull = fullPopupModes[touch] ?? false
        let bgLayer = popupBgLayers[touch]
        
        for (dir, label) in labels {
            if dir == direction {
                label.isHidden = false
                popup.bringSubviewToFront(label)
                if isFull {
                    label.backgroundColor = UIColor.systemBlue
                    label.textColor = .white
                    label.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                } else {
                    label.backgroundColor = .clear
                    label.textColor = .black
                    label.transform = .identity
                }
            } else {
                if isFull {
                    label.backgroundColor = .white
                    label.textColor = .black
                    label.transform = .identity
                    label.isHidden = false
                } else {
                    label.isHidden = true
                }
            }
        }
        
        if !isFull && direction != .center {
            guard let label = labels[direction] else { return }
            let f = label.frame.insetBy(dx: -6, dy: -6)
            let path = UIBezierPath(roundedRect: f, cornerRadius: 8)
            let arrow = UIBezierPath()
            let aw: CGFloat = 20 // arrow width
            let ah: CGFloat = 16 // arrow height pointing inward
            
            switch direction {
            case .left:
                arrow.move(to: CGPoint(x: f.maxX, y: f.midY - aw/2))
                arrow.addLine(to: CGPoint(x: f.maxX + ah, y: f.midY))
                arrow.addLine(to: CGPoint(x: f.maxX, y: f.midY + aw/2))
            case .right:
                arrow.move(to: CGPoint(x: f.minX, y: f.midY - aw/2))
                arrow.addLine(to: CGPoint(x: f.minX - ah, y: f.midY))
                arrow.addLine(to: CGPoint(x: f.minX, y: f.midY + aw/2))
            case .up:
                arrow.move(to: CGPoint(x: f.midX - aw/2, y: f.maxY))
                arrow.addLine(to: CGPoint(x: f.midX, y: f.maxY + ah))
                arrow.addLine(to: CGPoint(x: f.midX + aw/2, y: f.maxY))
            case .down:
                arrow.move(to: CGPoint(x: f.midX - aw/2, y: f.minY))
                arrow.addLine(to: CGPoint(x: f.midX, y: f.minY - ah))
                arrow.addLine(to: CGPoint(x: f.midX + aw/2, y: f.minY))
            default: break
            }
            arrow.close()
            path.append(arrow)
            bgLayer?.path = path.cgPath
            bgLayer?.fillColor = UIColor.white.cgColor
            bgLayer?.strokeColor = UIColor(white: 0.8, alpha: 1.0).cgColor
            bgLayer?.lineWidth = 0.5
        } else {
            bgLayer?.path = nil
        }
    }
    
    private func hidePopup(for touch: UITouch) {
        popupViews[touch]?.removeFromSuperview()
        popupViews.removeValue(forKey: touch)
        popupLabelsDict.removeValue(forKey: touch)
        popupBgLayers.removeValue(forKey: touch)
        fullPopupModes.removeValue(forKey: touch)
    }
    
    // MARK: - Animations
    
    private func animateKeyDown(_ view: UIView) {
        UIView.animate(withDuration: 0.05, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            view.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            if view.backgroundColor == .white {
                view.backgroundColor = UIColor(white: 0.85, alpha: 1.0)
            }
        }
    }
    
    private func animateKeyUp(_ view: UIView) {
        UIView.animate(withDuration: 0.1, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            view.transform = .identity
            if view.backgroundColor == UIColor(white: 0.85, alpha: 1.0) {
                view.backgroundColor = .white
            }
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
        let keyBg = isDark ? UIColor(white: 0.35, alpha: 1.0) : .white
        let specialBg = isDark ? UIColor(white: 0.25, alpha: 1.0) : UIColor(red: 0.68, green: 0.70, blue: 0.74, alpha: 1.0)
        
        abcButton.backgroundColor = specialBg
        numButton.backgroundColor = specialBg
        
        if let abcLbl = abcButton.subviews.first(where: { $0 is UILabel }) as? UILabel {
            abcLbl.text = (currentPage == .alphabet) ? "あいう" : "ABC"
        }
        
        if let numLbl = numButton.subviews.first(where: { $0 is UILabel }) as? UILabel {
            numLbl.text = (currentPage == .number) ? "あいう" : "☆123"
        }
        
        // Update grid keys
        for rowIndex in 0..<4 {
            for colIndex in 0..<3 {
                let btn = gridButtons[rowIndex][colIndex]
                let keyData = keys[rowIndex][colIndex]
                keysMap[btn] = keyData
                
                if rowIndex == 3 && colIndex == 0 {
                    // The dakuten / shift button
                    if currentPage == .alphabet {
                        if let label = btn.viewWithTag(100) as? UILabel {
                            label.text = "a/A"
                        }
                        btn.accessibilityIdentifier = "dakuten" // Reuse for shift
                    } else if currentPage == .kana {
                        if let label = btn.viewWithTag(100) as? UILabel {
                            label.text = "゛゜小"
                        }
                        btn.accessibilityIdentifier = "dakuten"
                    } else {
                        updateHints(for: btn, keyData: keyData, isShifted: isShifted)
                        btn.accessibilityIdentifier = nil
                    }
                    // Change styling for the special button
                    btn.backgroundColor = keyBg
                } else {
                    updateHints(for: btn, keyData: keyData, isShifted: isShifted)
                    btn.backgroundColor = keyBg
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
        
        spaceButton.backgroundColor = specialBg
        abcButton.backgroundColor = specialBg
        numButton.backgroundColor = specialBg
        faceButton.backgroundColor = specialBg
        globeButton.backgroundColor = specialBg
        deleteButton.backgroundColor = specialBg
        returnButton.backgroundColor = specialBg
        
        func apply(to view: UIView) {
            let isSpecial = (view == globeButton || view == deleteButton || view == returnButton || view == faceButton || view == spaceButton || view.subviews.first(where: { ($0 as? UILabel)?.text == "☆123" || ($0 as? UILabel)?.text == "ABC" || ($0 as? UILabel)?.text == "あいう" || ($0 as? UILabel)?.text == "^_^" || ($0 as? UILabel)?.text == "空白" }) != nil)
            
            if view.layer.cornerRadius > 0 && view != containerView && view.superview != nil {
                view.backgroundColor = isSpecial ? specialBg : keyBg
                if let lbl = view.subviews.first(where: { $0 is UILabel }) as? UILabel {
                    lbl.textColor = textCol
                }
            }
            for sub in view.subviews { apply(to: sub) }
        }
        apply(to: self)
        updatePageUI()
    }
    
    func setReturnKeyTitle(_ title: String) {
        if let lbl = returnButton?.viewWithTag(999) as? UILabel {
            lbl.text = title
        }
    }
}
