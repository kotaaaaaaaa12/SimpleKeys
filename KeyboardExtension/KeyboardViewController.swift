import UIKit

@objc(KeyboardViewController)
class KeyboardViewController: UIInputViewController, FlickKeyboardDelegate {
    
    // MARK: - Types
    
    enum InputMode {
        case flickKana
        case flickAlphabet
        case flickNumber
        case qwertyEnglish
        case qwertyNumbers
        case qwertySymbols
    }
    
    // MARK: - Properties
    
    private var currentMode: InputMode = .qwertyEnglish
    private var qwertyShifted = false
    private var qwertyContainer: UIView!
    private var qwertyStack: UIStackView!
    private var qwertyDeleteTimer: Timer?
    private var nextKeyboardButton: UIButton?
    
    private let romajiConverter = RomajiConverter()
    
    private var flickKeyboard: FlickKeyboardView!
    private var conversionBar: UIView!
    private var conversionLabel: UILabel!
    
    private let letterRows: [[String]] = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"]
    ]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Read default keyboard mode
        let defaults = UserDefaults(suiteName: "group.com.simplekeys.app")
        defaults?.synchronize()
        let defaultMode = defaults?.integer(forKey: "defaultKeyboardMode") ?? 0
        currentMode = defaultMode == 0 ? .flickKana : .qwertyEnglish
        
        setupConversionBar()
        setupQWERTYKeyboard()
        setupFlickKeyboard()
        applyMode()
        
        let heightConstraint = view.heightAnchor.constraint(equalToConstant: 216)
        heightConstraint.priority = UILayoutPriority(250)
        heightConstraint.isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNextKeyboardButtonVisibility()
        updateAppearance()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateAppearance()
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        updateAppearance()
    }
    
    // MARK: - Conversion Bar
    
    private func setupConversionBar() {
        conversionBar = UIView()
        conversionBar.translatesAutoresizingMaskIntoConstraints = false
        conversionBar.isHidden = true
        
        conversionLabel = UILabel()
        conversionLabel.font = .systemFont(ofSize: 16, weight: .medium)
        conversionLabel.textAlignment = .left
        conversionLabel.translatesAutoresizingMaskIntoConstraints = false
        conversionBar.addSubview(conversionLabel)
        
        let commitButton = UIButton(type: .system)
        commitButton.setTitle("OK", for: .normal)
        commitButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        commitButton.backgroundColor = UIColor.systemBlue
        commitButton.setTitleColor(.white, for: .normal)
        commitButton.layer.cornerRadius = 4
        commitButton.translatesAutoresizingMaskIntoConstraints = false
        commitButton.addTarget(self, action: #selector(commitConversion), for: .touchUpInside)
        conversionBar.addSubview(commitButton)
        
        NSLayoutConstraint.activate([
            conversionLabel.leadingAnchor.constraint(equalTo: conversionBar.leadingAnchor, constant: 12),
            conversionLabel.centerYAnchor.constraint(equalTo: conversionBar.centerYAnchor),
            conversionLabel.trailingAnchor.constraint(equalTo: commitButton.leadingAnchor, constant: -8),
            commitButton.trailingAnchor.constraint(equalTo: conversionBar.trailingAnchor, constant: -8),
            commitButton.centerYAnchor.constraint(equalTo: conversionBar.centerYAnchor),
            commitButton.widthAnchor.constraint(equalToConstant: 48),
            commitButton.heightAnchor.constraint(equalToConstant: 28),
        ])
        
        view.addSubview(conversionBar)
        
        NSLayoutConstraint.activate([
            conversionBar.topAnchor.constraint(equalTo: view.topAnchor),
            conversionBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            conversionBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            conversionBar.heightAnchor.constraint(equalToConstant: 36),
        ])
    }
    
    // MARK: - QWERTY Setup
    
    private func setupQWERTYKeyboard() {
        qwertyContainer = UIView()
        qwertyContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(qwertyContainer)
        
        let qwertyBottom = qwertyContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        qwertyBottom.priority = .defaultHigh
        
        NSLayoutConstraint.activate([
            qwertyContainer.topAnchor.constraint(equalTo: conversionBar.bottomAnchor, constant: 2),
            qwertyBottom,
            qwertyContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            qwertyContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        qwertyStack = UIStackView()
        qwertyStack.axis = .vertical
        qwertyStack.distribution = .fillEqually
        qwertyStack.spacing = 10
        qwertyStack.translatesAutoresizingMaskIntoConstraints = false
        qwertyContainer.addSubview(qwertyStack)
        
        NSLayoutConstraint.activate([
            qwertyStack.topAnchor.constraint(equalTo: qwertyContainer.topAnchor, constant: 10),
            qwertyStack.bottomAnchor.constraint(equalTo: qwertyContainer.bottomAnchor, constant: -10),
            qwertyStack.leadingAnchor.constraint(equalTo: qwertyContainer.leadingAnchor, constant: 3),
            qwertyStack.trailingAnchor.constraint(equalTo: qwertyContainer.trailingAnchor, constant: -3)
        ])
        
        rebuildQWERTYLayout()
    }
    
    private func rebuildQWERTYLayout() {
        for subview in qwertyStack.arrangedSubviews {
            qwertyStack.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        
        let rows: [[String]]
        var thirdRowSpecials: (left: String, right: String) = ("⇧", "⌫")
        var bottomRow: [String] = ["123", "globe", "space", "return"]
        
        switch currentMode {
        case .qwertyNumbers:
            rows = [
                ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
                ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""],
                [".", ",", "?", "!", "'"]
            ]
            thirdRowSpecials = ("#+=", "⌫")
            bottomRow = ["ABC", "globe", "space", "return"]
        case .qwertySymbols:
            rows = [
                ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="],
                ["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"],
                [".", ",", "?", "!", "'"]
            ]
            thirdRowSpecials = ("123", "⌫")
            bottomRow = ["ABC", "globe", "space", "return"]
        default:
            let letters = qwertyShifted ? [
                ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
                ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
                ["Z", "X", "C", "V", "B", "N", "M"]
            ] : [
                ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
                ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
                ["z", "x", "c", "v", "b", "n", "m"]
            ]
            rows = letters
        }
        
        qwertyStack.addArrangedSubview(createLetterRow(letters: rows[0]))
        
        let row2 = createLetterRow(letters: rows[1])
        let padding2 = UIView()
        let padding2R = UIView()
        padding2.translatesAutoresizingMaskIntoConstraints = false
        padding2R.translatesAutoresizingMaskIntoConstraints = false
        
        let paddedRow2 = UIStackView(arrangedSubviews: [padding2, row2, padding2R])
        paddedRow2.axis = .horizontal
        paddedRow2.spacing = 0
        qwertyStack.addArrangedSubview(paddedRow2)
        
        // Activate constraint after they have a common ancestor (paddedRow2)
        padding2.widthAnchor.constraint(equalTo: padding2R.widthAnchor).isActive = true
        
        let row3 = createLetterRow(letters: rows[2])
        let leftSpecial = createSpecialKeyButton(title: thirdRowSpecials.left)
        if thirdRowSpecials.left == "⇧" {
            leftSpecial.setTitle(qwertyShifted ? "⬆︎" : "⇧", for: .normal)
            leftSpecial.addTarget(self, action: #selector(shiftPressed), for: .touchUpInside)
        } else if thirdRowSpecials.left == "#+=" {
            leftSpecial.addTarget(self, action: #selector(switchToSymbols), for: .touchUpInside)
        } else if thirdRowSpecials.left == "123" {
            leftSpecial.addTarget(self, action: #selector(switchToNumbers), for: .touchUpInside)
        }
        
        let rightSpecial = createSpecialKeyButton(title: thirdRowSpecials.right)
        if thirdRowSpecials.right == "⌫" {
            rightSpecial.addTarget(self, action: #selector(deleteTouchDown), for: .touchDown)
            rightSpecial.addTarget(self, action: #selector(deleteTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        }
        
        leftSpecial.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
        leftSpecial.addTarget(self, action: #selector(keyTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        rightSpecial.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
        rightSpecial.addTarget(self, action: #selector(keyTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        let thirdRowStack = UIStackView(arrangedSubviews: [leftSpecial, row3, rightSpecial])
        thirdRowStack.axis = .horizontal
        thirdRowStack.spacing = 10
        leftSpecial.widthAnchor.constraint(equalTo: rightSpecial.widthAnchor).isActive = true
        leftSpecial.widthAnchor.constraint(equalToConstant: 42).isActive = true
        qwertyStack.addArrangedSubview(thirdRowStack)
        
        let bottomStack = UIStackView()
        bottomStack.axis = .horizontal
        bottomStack.distribution = .fillProportionally
        bottomStack.spacing = 6
        
        for key in bottomRow {
            if key == "globe" {
                if needsInputModeSwitchKey {
                    let globe = createSpecialKeyButton(title: "🌐")
                    globe.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
                    globe.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
                    globe.addTarget(self, action: #selector(keyTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
                    globe.widthAnchor.constraint(equalToConstant: 42).isActive = true
                    bottomStack.addArrangedSubview(globe)
                }
            } else if key == "space" {
                let spaceBtn = createKeyButton(title: "space")
                spaceBtn.addTarget(self, action: #selector(spacePressed), for: .touchUpInside)
                spaceBtn.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
                spaceBtn.addTarget(self, action: #selector(keyTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
                bottomStack.addArrangedSubview(spaceBtn)
            } else if key == "return" {
                let retBtn = createSpecialKeyButton(title: "return")
                retBtn.addTarget(self, action: #selector(returnPressed), for: .touchUpInside)
                retBtn.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
                retBtn.addTarget(self, action: #selector(keyTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
                retBtn.widthAnchor.constraint(equalToConstant: 80).isActive = true
                bottomStack.addArrangedSubview(retBtn)
            } else if key == "ABC" {
                let abcBtn = createSpecialKeyButton(title: "ABC")
                abcBtn.addTarget(self, action: #selector(switchToEnglish), for: .touchUpInside)
                abcBtn.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
                abcBtn.addTarget(self, action: #selector(keyTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
                abcBtn.widthAnchor.constraint(equalToConstant: 42).isActive = true
                bottomStack.addArrangedSubview(abcBtn)
            } else if key == "123" {
                let numBtn = createSpecialKeyButton(title: "123")
                numBtn.addTarget(self, action: #selector(switchToNumbers), for: .touchUpInside)
                numBtn.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
                numBtn.addTarget(self, action: #selector(keyTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
                numBtn.widthAnchor.constraint(equalToConstant: 42).isActive = true
                bottomStack.addArrangedSubview(numBtn)
            }
        }
        qwertyStack.addArrangedSubview(bottomStack)
    }
    
    // MARK: - Flick Setup
    
    private func setupFlickKeyboard() {
        flickKeyboard = FlickKeyboardView()
        flickKeyboard.delegate = self
        flickKeyboard.translatesAutoresizingMaskIntoConstraints = false
        flickKeyboard.isHidden = true
        view.addSubview(flickKeyboard)
        
        let flickBottom = flickKeyboard.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4)
        flickBottom.priority = .defaultHigh
        
        NSLayoutConstraint.activate([
            flickKeyboard.topAnchor.constraint(equalTo: conversionBar.bottomAnchor, constant: 2),
            flickBottom,
            flickKeyboard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            flickKeyboard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    // MARK: - Next Keyboard Button Visibility
    
    private func updateNextKeyboardButtonVisibility() {
        let showGlobe = needsInputModeSwitchKey
        nextKeyboardButton?.isHidden = !showGlobe
    }
    
    // MARK: - Mode Switching
    
    private func applyMode() {
        if currentMode == .flickKana || currentMode == .flickAlphabet || currentMode == .flickNumber {
            qwertyContainer.isHidden = true
            flickKeyboard.isHidden = false
            switch currentMode {
            case .flickKana: flickKeyboard.switchToPage(.kana)
            case .flickAlphabet: flickKeyboard.switchToPage(.alphabet)
            case .flickNumber: flickKeyboard.switchToPage(.number)
            default: break
            }
        } else {
            flickKeyboard.isHidden = true
            qwertyContainer.isHidden = false
            rebuildQWERTYLayout()
            updateButtonColors()
        }
    }
    
    // MARK: - Conversion Bar
    
    private func updateConversionBar() {
        let display = romajiConverter.displayText
        if display.isEmpty {
            conversionLabel.text = " "
            conversionLabel.textColor = .placeholderText
        } else {
            conversionLabel.text = display
            conversionLabel.textColor = .label
        }
    }
    
    @objc private func commitConversion() {
        let text = romajiConverter.commit()
        if !text.isEmpty {
            textDocumentProxy.insertText(text)
        }
        updateConversionBar()
    }
    
    // MARK: - Row Builders
    
    private func createLetterRow(letters: [String]) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 6
        
        for letter in letters {
            let button = createKeyButton(title: letter)
            button.addTarget(self, action: #selector(letterKeyPressed(_:)), for: .touchUpInside)
            button.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(keyTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
            stack.addArrangedSubview(button)
        }
        return stack
    }
    
    // MARK: - Key Button Factory
    
    private func createKeyButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .regular)
        button.layer.cornerRadius = 5
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowRadius = 0
        button.layer.shadowOpacity = 0.3
        return button
    }
    
    private func createSpecialKeyButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        button.layer.cornerRadius = 5
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowRadius = 0
        button.layer.shadowOpacity = 0.3
        return button
    }
    
    // MARK: - Appearance
    
    private func updateAppearance() {
        updateButtonColors()
        let isDark = textDocumentProxy.keyboardAppearance == .dark || traitCollection.userInterfaceStyle == .dark
        view.backgroundColor = isDark ? UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1.0) : UIColor(red: 0.82, green: 0.84, blue: 0.86, alpha: 1.0)
        conversionBar.backgroundColor = isDark ? UIColor(white: 0.22, alpha: 1.0) : UIColor(white: 0.95, alpha: 1.0)
        flickKeyboard?.updateAppearance(isDark: isDark)
    }
    
    private func updateButtonColors() {
        let isDark = textDocumentProxy.keyboardAppearance == .dark || traitCollection.userInterfaceStyle == .dark
        let letterBg = isDark ? UIColor(white: 0.35, alpha: 1.0) : .white
        let specialBg = isDark ? UIColor(white: 0.25, alpha: 1.0) : UIColor(red: 0.68, green: 0.70, blue: 0.74, alpha: 1.0)
        let textColor = isDark ? UIColor.white : UIColor.black
        
        qwertyStack.subviews.forEach { row in
            (row as? UIStackView)?.arrangedSubviews.forEach { sub in
                if let btn = sub as? UIButton {
                    btn.setTitleColor(textColor, for: .normal)
                    let title = btn.titleLabel?.text ?? ""
                    let isSpecialKey = ["⇧", "⬆︎", "⌫", "return", "123", "ABC", "#+="].contains(title)
                    btn.backgroundColor = isSpecialKey ? specialBg : letterBg
                } else if let nestedStack = sub as? UIStackView {
                    nestedStack.arrangedSubviews.forEach { btn in
                        if let b = btn as? UIButton {
                            b.setTitleColor(textColor, for: .normal)
                            let title = b.titleLabel?.text ?? ""
                            let isSpecialKey = ["⇧", "⬆︎", "⌫", "return", "123", "ABC", "#+="].contains(title)
                            b.backgroundColor = isSpecialKey ? specialBg : letterBg
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func letterKeyPressed(_ sender: UIButton) {
        guard let title = sender.titleLabel?.text else { return }
        textDocumentProxy.insertText(title)
        UIDevice.current.playInputClick()
    }
    
    @objc private func shiftPressed() {
        qwertyShifted.toggle()
        rebuildQWERTYLayout()
        updateButtonColors()
        UIDevice.current.playInputClick()
    }
    
    @objc private func switchToNumbers() {
        currentMode = .qwertyNumbers
        applyMode()
        UIDevice.current.playInputClick()
    }
    
    @objc private func switchToSymbols() {
        currentMode = .qwertySymbols
        applyMode()
        UIDevice.current.playInputClick()
    }
    
    @objc private func switchToEnglish() {
        currentMode = .qwertyEnglish
        applyMode()
        UIDevice.current.playInputClick()
    }
    
    @objc private func spacePressed() {
        textDocumentProxy.insertText(" ")
        UIDevice.current.playInputClick()
    }
    
    @objc private func returnPressed() {
        textDocumentProxy.insertText("\n")
        UIDevice.current.playInputClick()
    }
    
    @objc private func deleteTouchDown() {
        deletePressed()
        qwertyDeleteTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { [weak self] _ in
            self?.qwertyDeleteTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.deletePressed()
            }
        }
    }
    
    @objc private func deleteTouchUp() {
        qwertyDeleteTimer?.invalidate()
        qwertyDeleteTimer = nil
    }
    
    @objc private func deletePressed() {
        textDocumentProxy.deleteBackward()
        UIDevice.current.playInputClick()
    }
    
    @objc private func keyTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.05) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            sender.alpha = 0.8
        }
    }
    
    @objc private func keyTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = .identity
            sender.alpha = 1.0
        }
        let isDark = textDocumentProxy.keyboardAppearance == .dark
        sender.backgroundColor = isDark ? UIColor(white: 0.35, alpha: 1.0) : .white
        let title = sender.titleLabel?.text ?? ""
        let isSpecialKey = ["⇧", "⬆︎", "⌫", "return", "123", "ABC", "#+="].contains(title)
        if isSpecialKey {
            sender.backgroundColor = isDark ? UIColor(white: 0.25, alpha: 1.0) : UIColor(red: 0.68, green: 0.70, blue: 0.74, alpha: 1.0)
        }
    }
    
    // MARK: - FlickKeyboardDelegate
    
    @objc private func handleFlickGlobeTap(_ gesture: UITapGestureRecognizer) {
        // Fallback globe toggle if target-action doesn't work well on UIViews
        advanceToNextInputMode()
    }
    
    func flickKeyboard(_ keyboard: FlickKeyboardView, didInputText text: String) {
        textDocumentProxy.insertText(text)
    }
    
    func flickKeyboardDidPressGlobe(_ keyboard: FlickKeyboardView) {
        advanceToNextInputMode()
    }
    
    func flickKeyboardDidPressDelete(_ keyboard: FlickKeyboardView) {
        textDocumentProxy.deleteBackward()
    }
    
    func flickKeyboardDidPressReturn(_ keyboard: FlickKeyboardView) {
        textDocumentProxy.insertText("\n")
    }
    
    func flickKeyboardDidPressSpace(_ keyboard: FlickKeyboardView) {
        textDocumentProxy.insertText(" ")
    }
    
    func flickKeyboardDidPressABC(_ keyboard: FlickKeyboardView) {
        let defaults = UserDefaults(suiteName: "group.com.simplekeys.app")
        defaults?.synchronize()
        let style = defaults?.integer(forKey: "englishInputStyle") ?? 0
        
        if style == 0 {
            // Flick Alphabet
            if keyboard.currentPage == .alphabet {
                keyboard.switchToPage(.kana)
            } else {
                keyboard.switchToPage(.alphabet)
            }
        } else {
            // QWERTY English
            currentMode = .qwertyEnglish
            applyMode()
        }
    }
    
    func flickKeyboardDidPressDakuten(_ keyboard: FlickKeyboardView) {
        guard let before = textDocumentProxy.documentContextBeforeInput,
              let lastChar = before.last else { return }
        
        let charString = String(lastChar)
        let map: [String: String] = [
            "あ": "ぁ", "ぁ": "あ",
            "い": "ぃ", "ぃ": "い",
            "う": "ぅ", "ぅ": "ゔ", "ゔ": "う",
            "え": "ぇ", "ぇ": "え",
            "お": "ぉ", "ぉ": "お",
            "か": "が", "が": "ヵ", "ヵ": "か",
            "き": "ぎ", "ぎ": "き",
            "く": "ぐ", "ぐ": "く",
            "け": "げ", "げ": "ヶ", "ヶ": "け",
            "こ": "ご", "ご": "こ",
            "さ": "ざ", "ざ": "さ",
            "し": "じ", "じ": "し",
            "す": "ず", "ず": "す",
            "せ": "ぜ", "ぜ": "せ",
            "そ": "ぞ", "ぞ": "そ",
            "た": "だ", "だ": "た",
            "ち": "ぢ", "ぢ": "ち",
            "つ": "っ", "っ": "づ", "づ": "つ",
            "て": "で", "で": "て",
            "と": "ど", "ど": "と",
            "は": "ば", "ば": "ぱ", "ぱ": "は",
            "ひ": "び", "び": "ぴ", "ぴ": "ひ",
            "ふ": "ぶ", "ぶ": "ぷ", "ぷ": "ふ",
            "へ": "べ", "べ": "ぺ", "ぺ": "へ",
            "ほ": "ぼ", "ぼ": "ぽ", "ぽ": "ほ",
            "や": "ゃ", "ゃ": "や",
            "ゆ": "ゅ", "ゅ": "ゆ",
            "よ": "ょ", "ょ": "よ",
            "わ": "ゎ", "ゎ": "わ"
        ]
        
        if let newChar = map[charString] {
            textDocumentProxy.deleteBackward()
            textDocumentProxy.insertText(newChar)
        } else {
            textDocumentProxy.insertText("゛")
        }
        UIDevice.current.playInputClick()
    }
}
