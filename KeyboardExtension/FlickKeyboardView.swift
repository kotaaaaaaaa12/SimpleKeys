import UIKit
import AudioToolbox

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
            FlickKey(center: "゛゜\n小", left: nil, up: nil, right: nil, down: nil),
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

class FlickKeyboardView: UIView, UIInputViewAudioFeedback {
    var enableInputClicksWhenVisible: Bool { return true }

    
    // MARK: - Types
    
    enum FlickDirection {
        case center, left, up, right, down
    }
    
    // MARK: - Properties
    
    weak var delegate: FlickKeyboardDelegate?
    
    private(set) var currentPage: KeyboardPage = .kana
    private var currentTheme: ThemeSettings?
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
            lbl.tag = 100 // Keep as 100 so applyTheme updates it
        }
        place(view: returnButton, row: 2, col: 4, rowSpan: 2) // Spans row 2 and 3
    }
    
    // MARK: - Key Builders
    
    class FlickKeyView: UIView {
        var shape: Int = 0 { didSet { setNeedsLayout() } }
        var blurView: UIVisualEffectView?
        
        var customBorderWidth: CGFloat = 0 { didSet { setNeedsLayout() } }
        var customBorderStyle: Int = 0 { didSet { setNeedsLayout() } }
        var customBorderColor: CGColor? { didSet { setNeedsLayout() } }
        var isFrostedOrClear: Bool = false { didSet { setNeedsLayout() } }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            let radius: CGFloat = shape == 0 ? 6 : (shape == 1 ? min(bounds.width, bounds.height) / 2.0 : 0)
            layer.cornerRadius = radius
            blurView?.layer.cornerRadius = radius
            
            self.applyCustomBorderStyle(width: customBorderWidth, style: customBorderStyle, color: customBorderColor, radius: radius, isFrostedOrClear: isFrostedOrClear)
        }
    }
    
    private func createFlickKey(_ keyData: FlickKey) -> FlickKeyView {
        let view = FlickKeyView()
        view.backgroundColor = .white
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowOpacity = 0.3
        view.layer.shadowRadius = 0
        
        let centerLabel = UILabel()
        centerLabel.numberOfLines = 2
        centerLabel.lineBreakMode = .byWordWrapping
        centerLabel.adjustsFontSizeToFitWidth = true
        centerLabel.minimumScaleFactor = 0.5
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
            subtitleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 12)
        ])
        
        updateHints(for: view, keyData: keyData, isShifted: false)
        keysMap[view] = keyData
        return view
    }
    
    private func updateHints(for btn: UIView, keyData: FlickKey, isShifted: Bool = false) {
        // Determine if this key should actually show a hint
        var shouldShowHint = true
        if currentPage != .number {
            shouldShowHint = false
        }
        
        // Hide hints for non-flickable keys
        if keyData.left == nil && keyData.up == nil && keyData.right == nil && keyData.down == nil {
            shouldShowHint = false
        }
        
        if let lbl = btn.viewWithTag(100) as? UILabel {
            var text = keyData.center
            if currentPage == .alphabet && !isShifted {
                text = text.uppercased()
            }
            lbl.text = text
            let fontSize: CGFloat
            if text.contains("゛゜") && text.contains("小") {
                fontSize = 14
                shouldShowHint = false
            } else if text.count >= 4 {
                fontSize = 16
                shouldShowHint = false // Don't show hints for wide text
            } else if currentPage == .alphabet && text.count >= 3 {
                fontSize = 17
            } else {
                fontSize = 22
            }
            
            if let fontName = currentTheme?.fontName, let customFont = UIFont(name: fontName, size: fontSize) {
                lbl.font = customFont
            } else {
                lbl.font = .systemFont(ofSize: fontSize, weight: .regular)
            }
            
            if text.contains("゛゜") && text.contains("小") {
                lbl.transform = .identity
                let attrStr = NSMutableAttributedString()
                let pStyle = NSMutableParagraphStyle()
                pStyle.lineSpacing = -2
                pStyle.alignment = .center
                attrStr.append(NSAttributedString(string: "゛゜\n", attributes: [
                    .font: lbl.font.withSize(16),
                    .paragraphStyle: pStyle
                ]))
                attrStr.append(NSAttributedString(string: "小", attributes: [
                    .font: lbl.font.withSize(13),
                    .paragraphStyle: pStyle
                ]))
                lbl.attributedText = attrStr
                lbl.numberOfLines = 0
                lbl.adjustsFontSizeToFitWidth = false
                lbl.lineBreakMode = .byWordWrapping
            } else if !shouldShowHint {
                lbl.transform = CGAffineTransform(translationX: 0, y: 5)
                lbl.adjustsFontSizeToFitWidth = true
                lbl.numberOfLines = 2
            } else {
                lbl.transform = .identity
                lbl.adjustsFontSizeToFitWidth = true
                lbl.numberOfLines = 2
            }
        }
        
        if let sub = btn.viewWithTag(105) as? UILabel {
            sub.textColor = .lightGray
            
            if keyData.center.contains("゛゜") && keyData.center.contains("小") {
                sub.text = ""
            } else if !shouldShowHint {
                sub.text = ""
            } else {
                var hints = [String]()
                if let left = keyData.left { hints.append(left) }
                if let up = keyData.up { hints.append(up) }
                if let right = keyData.right { hints.append(right) }
                if let down = keyData.down { hints.append(down) }
                
                var hintStr = hints.joined(separator: " ")
                if currentPage == .alphabet && !isShifted {
                    hintStr = hintStr.uppercased()
                }
                sub.text = hintStr
            }
        }
    }
    
    private func createSpecialKey(title: String) -> FlickKeyView {
        let view = FlickKeyView()
        view.backgroundColor = UIColor(red: 0.68, green: 0.70, blue: 0.74, alpha: 1.0)
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
    
    private func createSpecialImageKey(systemName: String) -> FlickKeyView {
        let view = FlickKeyView()
        view.backgroundColor = UIColor(red: 0.68, green: 0.70, blue: 0.74, alpha: 1.0)
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
    
    func applyTheme(_ theme: ThemeSettings) {
        self.currentTheme = theme
        let isFrosted = theme.keyStyle == 1
        let isFlat = theme.keyStyle == 2
        let isClear = theme.keyStyle == 3
        
        let allKeys = Array(keysMap.keys) + [numButton, abcButton, globeButton, faceButton, deleteButton, returnButton].compactMap { $0 }
        
        let opacity = theme.keyOpacity ?? 1.0
        let defaultBorderCol = UIColor.black.withAlphaComponent(0.3).cgColor
        let borderCol = theme.keyBorderColorHex != nil ? (UIColor(hex: theme.keyBorderColorHex!)?.cgColor ?? defaultBorderCol) : defaultBorderCol
        let clearBgAlpha = 0.15 * opacity
        
        let isDark = self.isDarkMode
        let defaultTextCol = isDark ? UIColor.white : UIColor.black
        let textCol = theme.textColorHex != nil ? (UIColor(hex: theme.textColorHex!) ?? defaultTextCol) : defaultTextCol
        
        let defaultKeyBgCol = isDark ? UIColor(white: 0.35, alpha: 1.0) : .white
        let keyBgCol = theme.keyColorHex != nil ? (UIColor(hex: theme.keyColorHex!) ?? defaultKeyBgCol) : defaultKeyBgCol
        let specialBg = isDark ? UIColor(white: 0.25, alpha: 1.0) : UIColor(red: 0.68, green: 0.70, blue: 0.74, alpha: 1.0)
        
        let shape = theme.buttonShape ?? 0
        
        let bWidth = theme.keyBorderWidth ?? CGFloat(isFrosted || isClear || isFlat ? (isFlat ? 1.0 : 0.5) : 0.0)
        let bStyle = theme.keyBorderStyle ?? 0
        
        for keyView in allKeys {
            if let fkv = keyView as? FlickKeyView {
                fkv.shape = shape
                fkv.customBorderWidth = bWidth
                fkv.customBorderStyle = bStyle
                fkv.customBorderColor = borderCol
                fkv.isFrostedOrClear = (isFrosted || isClear)
            }
            
            let existingBlur = keyView.viewWithTag(8888) as? UIVisualEffectView
            let isSpecial = [numButton, abcButton, globeButton, faceButton, deleteButton, returnButton, spaceButton].contains(keyView)
            
            if isFlat {
                existingBlur?.removeFromSuperview()
                keyView.backgroundColor = .clear
                keyView.layer.shadowOpacity = 0
            } else if isFrosted || isClear {
                keyView.backgroundColor = isClear ? UIColor.white.withAlphaComponent(clearBgAlpha) : .clear
                keyView.layer.shadowOpacity = 0
                
                if isFrosted {
                    if existingBlur == nil {
                        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                        blur.tag = 8888
                        blur.layer.borderWidth = 0
                        blur.layer.borderColor = UIColor.clear.cgColor
                        blur.clipsToBounds = true
                        blur.isUserInteractionEnabled = false
                        blur.translatesAutoresizingMaskIntoConstraints = false
                        blur.alpha = opacity
                        keyView.insertSubview(blur, at: 0)
                        NSLayoutConstraint.activate([
                            blur.leadingAnchor.constraint(equalTo: keyView.leadingAnchor),
                            blur.trailingAnchor.constraint(equalTo: keyView.trailingAnchor),
                            blur.topAnchor.constraint(equalTo: keyView.topAnchor),
                            blur.bottomAnchor.constraint(equalTo: keyView.bottomAnchor)
                        ])
                        if let fkv = keyView as? FlickKeyView {
                            fkv.blurView = blur
                        }
                    } else {
                        existingBlur?.alpha = opacity
                        existingBlur?.layer.borderColor = UIColor.clear.cgColor
                    }
                } else {
                    existingBlur?.removeFromSuperview()
                }
            } else {
                existingBlur?.removeFromSuperview()
                keyView.backgroundColor = isSpecial ? specialBg : keyBgCol
                keyView.layer.shadowOpacity = 0.3
            }
            
            if let lbl = keyView.viewWithTag(100) as? UILabel {
                lbl.textColor = textCol
                if let fontName = theme.fontName, let customFont = UIFont(name: fontName, size: lbl.font.pointSize) {
                    lbl.font = customFont
                }
            }
            if let sub = keyView.viewWithTag(105) as? UILabel {
                if let center = keysMap[keyView]?.center, center.contains("゛゜"), center.contains("小") {
                    sub.textColor = textCol
                } else {
                    sub.textColor = textCol.withAlphaComponent(0.5)
                }
                if let fontName = theme.fontName, let customFont = UIFont(name: fontName, size: sub.font.pointSize) {
                    sub.font = customFont
                }
            }
            for subview in keyView.subviews {
                if let img = subview as? UIImageView {
                    img.tintColor = textCol
                }
            }
        }
        
        // Refresh hints and shifted states according to the current navStyle
        for (btn, keyData) in keysMap {
            updateHints(for: btn, keyData: keyData, isShifted: self.isShifted)
        }
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
                
                let sensitivity = AppGroupHelper.shared.userDefaults?.float(forKey: "cursorSensitivity") ?? 1.0
                let threshold = CGFloat(20.0 / max(0.1, sensitivity))
                
                if isDragging {
                    if dx > threshold {
                        delegate?.flickKeyboardDidSwipeSpace(self, direction: .right)
                        startPoints[touch] = CGPoint(x: start.x + threshold, y: start.y)
                    } else if dx < -threshold {
                        delegate?.flickKeyboardDidSwipeSpace(self, direction: .left)
                        startPoints[touch] = CGPoint(x: start.x - threshold, y: start.y)
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
                self.triggerHaptic(isSpecialKey: true)
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
                        self.triggerHaptic(isSpecialKey: true)
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
        
        if let lbl = button.viewWithTag(100) as? UILabel { lbl.isHidden = true }
        if let sub = button.viewWithTag(105) as? UILabel { sub.isHidden = true }
        
        // Read theme colors
        var popupBg = UIColor.white
        var popupTextCol = UIColor.black
        var themeToUse = self.currentTheme
        if themeToUse == nil {
            if let data = AppGroupHelper.shared.userDefaults?.data(forKey: ThemeSettings.sharedKey),
               let theme = try? JSONDecoder().decode(ThemeSettings.self, from: data) {
                themeToUse = theme
            }
        }
        var popupBorderCol: UIColor? = nil
        var popupBorderWidth: CGFloat = 0.0
        var popupBorderStyle = 0
        if let theme = themeToUse {
            if let hex = theme.flickPopupBgHex { popupBg = UIColor(hex: hex) ?? .white }
            if let hex = theme.flickPopupTextHex { popupTextCol = UIColor(hex: hex) ?? .black }
            if let hex = theme.flickPopupBorderColorHex { popupBorderCol = UIColor(hex: hex) }
            if let width = theme.flickPopupBorderWidth { popupBorderWidth = width }
            if let style = theme.flickPopupBorderStyle { popupBorderStyle = style }
        }
        
        let popup = UIView()
        popup.translatesAutoresizingMaskIntoConstraints = false
        
        let keyWidth = button.bounds.width
        let keyHeight = button.bounds.height
        let spacing: CGFloat = 6.0
        let shape = themeToUse?.flickPopupShape ?? 0
        let radius: CGFloat = shape == 0 ? 6 : (shape == 1 ? min(keyWidth, keyHeight) / 2.0 : 0)
        
        let directions: [FlickDirection] = [.center, .left, .up, .right, .down]
        var labels: [FlickDirection: UILabel] = [:]
        
        for dir in directions {
            if dir != .center && textForDirection(dir, key: keyData) == nil { continue }
            
            let label = UILabel()
            label.numberOfLines = 2
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.5
            label.lineBreakMode = .byWordWrapping
            
            if let fontName = themeToUse?.fontName, let customFont = UIFont(name: fontName, size: 22) {
                label.font = customFont
            } else {
                label.font = .systemFont(ofSize: 22, weight: .semibold)
            }
            label.textColor = popupTextCol
            label.textAlignment = .center
            label.backgroundColor = popupBg
            label.layer.cornerRadius = radius
            label.layer.masksToBounds = true
            label.layer.shadowColor = UIColor.black.cgColor
            
            label.bounds = CGRect(x: 0, y: 0, width: keyWidth, height: keyHeight)
            let finalBorderCol = popupBorderCol ?? popupBg.withAlphaComponent(0.6)
            label.applyCustomBorderStyle(width: popupBorderWidth, style: popupBorderStyle, color: finalBorderCol.cgColor, radius: radius, isFrostedOrClear: false)
            label.layer.shadowOpacity = 0.2
            label.layer.shadowOffset = CGSize(width: 0, height: 1)
            label.layer.shadowRadius = 2
            let dirText = textForDirection(dir, key: keyData) ?? ""
            if dirText.contains("゛゜") && dirText.contains("小") {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = -2
                paragraphStyle.alignment = .center
                let attrStr = NSMutableAttributedString()
                attrStr.append(NSAttributedString(string: "゛゜\n", attributes: [
                    .font: label.font.withSize(16),
                    .paragraphStyle: paragraphStyle
                ]))
                attrStr.append(NSAttributedString(string: "小", attributes: [
                    .font: label.font.withSize(13),
                    .paragraphStyle: paragraphStyle
                ]))
                label.attributedText = attrStr
                label.numberOfLines = 0
                label.adjustsFontSizeToFitWidth = false
            } else {
                label.text = dirText
            }
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
        bgLayer.fillColor = popupBg.cgColor
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
        
        self.layoutIfNeeded()
        
        updatePopup(direction: .center, for: touch)
    }
    
    private func updatePopup(direction: FlickDirection, for touch: UITouch) {
        guard let popup = popupViews[touch], let labels = popupLabelsDict[touch] else { return }
        let isFull = fullPopupModes[touch] ?? false
        let bgLayer = popupBgLayers[touch]
        
        // Read theme colors
        var popupBg = UIColor.white
        var popupTextCol = UIColor.black
        var highlightCol = UIColor.systemBlue
        var themeToUse = self.currentTheme
        if themeToUse == nil {
            if let data = AppGroupHelper.shared.userDefaults?.data(forKey: ThemeSettings.sharedKey),
               let theme = try? JSONDecoder().decode(ThemeSettings.self, from: data) {
                themeToUse = theme
            }
        }
        var popupBorderCol: UIColor? = nil
        var popupBorderWidth: CGFloat = 0.0
        var popupBorderStyle = 0
        if let theme = themeToUse {
            if let hex = theme.flickPopupBgHex { popupBg = UIColor(hex: hex) ?? .white }
            if let hex = theme.flickPopupTextHex { popupTextCol = UIColor(hex: hex) ?? .black }
            if let hex = theme.flickHighlightHex { highlightCol = UIColor(hex: hex) ?? .systemBlue }
            if let hex = theme.flickPopupBorderColorHex { popupBorderCol = UIColor(hex: hex) }
            if let width = theme.flickPopupBorderWidth { popupBorderWidth = width }
            if let style = theme.flickPopupBorderStyle { popupBorderStyle = style }
        }
        
        for (dir, label) in labels {
            let customBorder = label.layer.sublayers?.first(where: { $0.name == "customBorderLayer" })
            if dir == direction {
                label.isHidden = false
                popup.bringSubviewToFront(label)
                if isFull {
                    label.backgroundColor = highlightCol
                    label.textColor = .white
                    label.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                    customBorder?.isHidden = false
                } else {
                    label.backgroundColor = .clear
                    label.textColor = popupTextCol
                    label.transform = .identity
                    customBorder?.isHidden = true
                }
            } else {
                if isFull {
                    label.backgroundColor = popupBg
                    label.textColor = popupTextCol
                    label.transform = .identity
                    label.isHidden = false
                    customBorder?.isHidden = false
                } else {
                    label.isHidden = true
                }
            }
        }
        
        if !isFull && direction != .center {
            guard let label = labels[direction] else { return }
            let f = label.frame.insetBy(dx: -6, dy: -6)
            let shape = themeToUse?.flickPopupShape ?? 0
            let r: CGFloat = shape == 0 ? 8 : (shape == 1 ? min(f.width, f.height) / 2.0 : 0)
            
            let aw: CGFloat = 20
            let ah: CGFloat = 16
            
            func rightX(for y: CGFloat) -> CGFloat {
                if y <= f.minY + r {
                    let dy = y - (f.minY + r)
                    return (f.maxX - r) + sqrt(max(0, r*r - dy*dy))
                } else if y >= f.maxY - r {
                    let dy = y - (f.maxY - r)
                    return (f.maxX - r) + sqrt(max(0, r*r - dy*dy))
                } else { return f.maxX }
            }
            func leftX(for y: CGFloat) -> CGFloat {
                if y <= f.minY + r {
                    let dy = y - (f.minY + r)
                    return (f.minX + r) - sqrt(max(0, r*r - dy*dy))
                } else if y >= f.maxY - r {
                    let dy = y - (f.maxY - r)
                    return (f.minX + r) - sqrt(max(0, r*r - dy*dy))
                } else { return f.minX }
            }
            func topY(for x: CGFloat) -> CGFloat {
                if x <= f.minX + r {
                    let dx = x - (f.minX + r)
                    return (f.minY + r) - sqrt(max(0, r*r - dx*dx))
                } else if x >= f.maxX - r {
                    let dx = x - (f.maxX - r)
                    return (f.minY + r) - sqrt(max(0, r*r - dx*dx))
                } else { return f.minY }
            }
            func bottomY(for x: CGFloat) -> CGFloat {
                if x <= f.minX + r {
                    let dx = x - (f.minX + r)
                    return (f.maxY - r) + sqrt(max(0, r*r - dx*dx))
                } else if x >= f.maxX - r {
                    let dx = x - (f.maxX - r)
                    return (f.maxY - r) + sqrt(max(0, r*r - dx*dx))
                } else { return f.maxY }
            }
            
            var tlStart = CGFloat.pi
            var tlEnd = 3 * CGFloat.pi / 2
            var trStart = -(CGFloat.pi / 2)
            var trEnd = 0.0
            var brStart = 0.0
            var brEnd = CGFloat.pi / 2
            var blStart = CGFloat.pi / 2
            var blEnd = CGFloat.pi
            
            let y1 = f.midY - aw/2
            let y2 = f.midY + aw/2
            let x1 = f.midX - aw/2
            let x2 = f.midX + aw/2
            
            if direction == .left {
                if y1 < f.minY + r { trEnd = asin(max(-1.0, min(1.0, Double(y1 - (f.minY + r)) / Double(r)))) }
                if y2 > f.maxY - r { brStart = asin(max(-1.0, min(1.0, Double(y2 - (f.maxY - r)) / Double(r)))) }
            } else if direction == .right {
                if y2 > f.maxY - r { blEnd = .pi - asin(max(-1.0, min(1.0, Double(y2 - (f.maxY - r)) / Double(r)))) }
                if y1 < f.minY + r { tlStart = .pi - asin(max(-1.0, min(1.0, Double(y1 - (f.minY + r)) / Double(r)))) }
            } else if direction == .down {
                if x1 < f.minX + r { tlEnd = 2 * .pi - acos(max(-1.0, min(1.0, Double(x1 - (f.minX + r)) / Double(r)))) }
                if x2 > f.maxX - r { trStart = -acos(max(-1.0, min(1.0, Double(x2 - (f.maxX - r)) / Double(r)))) }
            } else if direction == .up {
                if x2 > f.maxX - r { brEnd = acos(max(-1.0, min(1.0, Double(x2 - (f.maxX - r)) / Double(r)))) }
                if x1 < f.minX + r { blStart = acos(max(-1.0, min(1.0, Double(x1 - (f.minX + r)) / Double(r)))) }
            }
            
            let path = UIBezierPath()
            path.addArc(withCenter: CGPoint(x: f.minX + r, y: f.minY + r), radius: r, startAngle: tlStart, endAngle: tlEnd, clockwise: true)
            
            if direction == .down {
                path.addLine(to: CGPoint(x: x1, y: topY(for: x1)))
                path.addLine(to: CGPoint(x: f.midX, y: f.minY - ah))
                path.addLine(to: CGPoint(x: x2, y: topY(for: x2)))
            }
            
            path.addArc(withCenter: CGPoint(x: f.maxX - r, y: f.minY + r), radius: r, startAngle: trStart, endAngle: trEnd, clockwise: true)
            
            if direction == .left {
                path.addLine(to: CGPoint(x: rightX(for: y1), y: y1))
                path.addLine(to: CGPoint(x: f.maxX + ah, y: f.midY))
                path.addLine(to: CGPoint(x: rightX(for: y2), y: y2))
            }
            
            path.addArc(withCenter: CGPoint(x: f.maxX - r, y: f.maxY - r), radius: r, startAngle: brStart, endAngle: brEnd, clockwise: true)
            
            if direction == .up {
                path.addLine(to: CGPoint(x: x2, y: bottomY(for: x2)))
                path.addLine(to: CGPoint(x: f.midX, y: f.maxY + ah))
                path.addLine(to: CGPoint(x: x1, y: bottomY(for: x1)))
            }
            
            path.addArc(withCenter: CGPoint(x: f.minX + r, y: f.maxY - r), radius: r, startAngle: blStart, endAngle: blEnd, clockwise: true)
            
            if direction == .right {
                path.addLine(to: CGPoint(x: leftX(for: y2), y: y2))
                path.addLine(to: CGPoint(x: f.minX - ah, y: f.midY))
                path.addLine(to: CGPoint(x: leftX(for: y1), y: y1))
            }
            
            path.close()
            
            bgLayer?.sublayers?.forEach { $0.removeFromSuperlayer() }
            
            let finalBorderCol = popupBorderCol ?? popupBg.withAlphaComponent(0.6)
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            
            bgLayer?.path = path.cgPath
            bgLayer?.fillColor = popupBg.cgColor
            
            if popupBorderWidth > 0 {
                bgLayer?.strokeColor = finalBorderCol.cgColor
                bgLayer?.lineWidth = popupBorderWidth
                bgLayer?.lineCap = .round
                bgLayer?.lineJoin = .round
                
                switch popupBorderStyle {
                case 1:
                    bgLayer?.lineDashPattern = [NSNumber(value: Float(popupBorderWidth * 3)), NSNumber(value: Float(popupBorderWidth * 2))]
                case 2:
                    bgLayer?.lineDashPattern = [NSNumber(value: Float(popupBorderWidth)), NSNumber(value: Float(popupBorderWidth * 2))]
                case 3: // Double
                    bgLayer?.lineDashPattern = nil
                    let inner = CAShapeLayer()
                    inner.path = bgLayer?.path
                    inner.fillColor = UIColor.clear.cgColor
                    inner.strokeColor = popupBg.cgColor
                    inner.lineWidth = popupBorderWidth / 3.0
                    bgLayer?.addSublayer(inner)
                case 4:
                    bgLayer?.lineDashPattern = [NSNumber(value: Float(popupBorderWidth * 4)), NSNumber(value: Float(popupBorderWidth * 2)), NSNumber(value: Float(popupBorderWidth)), NSNumber(value: Float(popupBorderWidth * 2))]
                case 5:
                    bgLayer?.lineDashPattern = [NSNumber(value: Float(popupBorderWidth * 4)), NSNumber(value: Float(popupBorderWidth * 2)), NSNumber(value: Float(popupBorderWidth)), NSNumber(value: Float(popupBorderWidth * 2)), NSNumber(value: Float(popupBorderWidth)), NSNumber(value: Float(popupBorderWidth * 2))]
                default:
                    bgLayer?.lineDashPattern = nil
                }
            } else {
                bgLayer?.lineWidth = 0
                bgLayer?.strokeColor = UIColor.clear.cgColor
            }
            
            CATransaction.commit()
            
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            bgLayer?.path = nil
            CATransaction.commit()
            bgLayer?.sublayers?.forEach { $0.removeFromSuperlayer() }
        }
    }
    
    private func hidePopup(for touch: UITouch) {
        if let btn = activeTouches[touch] {
            if let lbl = btn.viewWithTag(100) as? UILabel { lbl.isHidden = false }
            if let sub = btn.viewWithTag(105) as? UILabel { sub.isHidden = false }
        }
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
                            label.transform = .identity
                        }
                        if let sub = btn.viewWithTag(105) as? UILabel {
                            sub.text = ""
                        }
                        btn.accessibilityIdentifier = "dakuten" // Reuse for shift
                    } else if currentPage == .kana {
                        updateHints(for: btn, keyData: keyData, isShifted: isShifted)
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
        
        // Re-apply theme if one exists
        if let theme = currentTheme {
            applyTheme(theme)
        } else if let data = AppGroupHelper.shared.userDefaults?.data(forKey: ThemeSettings.sharedKey),
           let theme = try? JSONDecoder().decode(ThemeSettings.self, from: data) {
            applyTheme(theme)
        }
    }
    
    // MARK: - Appearance
    
    func updateAppearance(isDark: Bool) {
        self.isDarkMode = isDark
        let bg = isDark ? UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1.0) : UIColor(red: 0.82, green: 0.84, blue: 0.86, alpha: 1.0)
        let keyBg = isDark ? UIColor(white: 0.35, alpha: 1.0) : .white
        let specialBg = isDark ? UIColor(white: 0.25, alpha: 1.0) : UIColor(red: 0.68, green: 0.70, blue: 0.74, alpha: 1.0)
        let textCol = isDark ? UIColor.white : UIColor.black
        
        var hasCustomBg = false
        if let theme = currentTheme {
            hasCustomBg = theme.backgroundImageFileName != nil || theme.backgroundColorHex != nil
        } else if let data = AppGroupHelper.shared.userDefaults?.data(forKey: ThemeSettings.sharedKey),
           let theme = try? JSONDecoder().decode(ThemeSettings.self, from: data) {
            hasCustomBg = theme.backgroundImageFileName != nil || theme.backgroundColorHex != nil
        }
        
        backgroundColor = hasCustomBg ? .clear : bg
        
        spaceButton.backgroundColor = specialBg
        abcButton.backgroundColor = specialBg
        numButton.backgroundColor = specialBg
        faceButton.backgroundColor = specialBg
        globeButton.backgroundColor = specialBg
        deleteButton.backgroundColor = specialBg
        returnButton.backgroundColor = specialBg
        
        func apply(to view: UIView) {
            if view is UIVisualEffectView { return }
            
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
    
    // MARK: - Haptic Feedback
    private func triggerHaptic(isSpecialKey: Bool = false) {
        AppGroupHelper.shared.userDefaults?.synchronize()
        let mode = AppGroupHelper.shared.userDefaults?.integer(forKey: "hapticTriggerMode") ?? 0
        if mode == 1 && isSpecialKey { return }
        if mode == 2 && !isSpecialKey { return }
        
        let customSound = AppGroupHelper.shared.userDefaults?.object(forKey: "customSoundEnabled") as? Bool ?? true
        let customVib = AppGroupHelper.shared.userDefaults?.object(forKey: "customHapticEnabled") as? Bool ?? true
        
        if customSound {
            KeyboardSoundManager.shared.playClick()
        } else {
            UIDevice.current.playInputClick()
        }
        
        if customVib {
            let strength = AppGroupHelper.shared.userDefaults?.object(forKey: "customHapticStrength") as? Float ?? 1.0
            let style: UIImpactFeedbackGenerator.FeedbackStyle = {
                if strength < 0.5 { return .light }
                if strength < 1.5 { return .medium }
                return .heavy
            }()
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
    }
}
