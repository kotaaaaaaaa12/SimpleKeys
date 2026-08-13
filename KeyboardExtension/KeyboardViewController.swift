import UIKit

class KeyboardViewController: UIInputViewController, FlickKeyboardDelegate {
    
    // MARK: - Types
    
    enum KeyboardMode {
        case qwertyEnglish
        case qwertyJapanese
        case flick
    }
    
    // MARK: - Properties
    
    private var currentMode: KeyboardMode = .qwertyEnglish
    private var isShifted = false
    private var shiftButton: UIButton?
    private var modeButton: UIButton?
    private var nextKeyboardButton: UIButton?
    
    private let romajiConverter = RomajiConverter()
    
    private var qwertyContainer: UIView!
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
        
        setupConversionBar()
        setupQWERTYKeyboard()
        setupFlickKeyboard()
        applyMode()
        
        // Add a default height constraint with low priority to prevent 0-height crashes
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
        
        let qwertyBottom = qwertyContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4)
        qwertyBottom.priority = .defaultHigh
        
        NSLayoutConstraint.activate([
            qwertyContainer.topAnchor.constraint(equalTo: conversionBar.bottomAnchor, constant: 2),
            qwertyBottom,
            qwertyContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 3),
            qwertyContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -3),
        ])
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        qwertyContainer.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: qwertyContainer.topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: qwertyContainer.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: qwertyContainer.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: qwertyContainer.trailingAnchor),
        ])
        
        // Row 1
        stack.addArrangedSubview(createLetterRow(letters: letterRows[0]))
        
        // Row 2 (with padding)
        let row2Container = UIView()
        let row2 = createLetterRow(letters: letterRows[1])
        row2.translatesAutoresizingMaskIntoConstraints = false
        row2Container.addSubview(row2)
        NSLayoutConstraint.activate([
            row2.topAnchor.constraint(equalTo: row2Container.topAnchor),
            row2.bottomAnchor.constraint(equalTo: row2Container.bottomAnchor),
            row2.leadingAnchor.constraint(equalTo: row2Container.leadingAnchor, constant: 16),
            row2.trailingAnchor.constraint(equalTo: row2Container.trailingAnchor, constant: -16),
        ])
        stack.addArrangedSubview(row2Container)
        
        // Row 3 (with shift + delete)
        stack.addArrangedSubview(createThirdRow())
        
        // Row 4 (bottom)
        stack.addArrangedSubview(createBottomRow())
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
        
        if let globeBtn = flickKeyboard.getGlobeButton() {
            globeBtn.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        }
    }
    
    // MARK: - Next Keyboard Button Visibility
    
    private func updateNextKeyboardButtonVisibility() {
        let showGlobe = needsInputModeSwitchKey
        nextKeyboardButton?.isHidden = !showGlobe
        
        if let flickGlobe = flickKeyboard?.getGlobeButton() {
            flickGlobe.isHidden = !showGlobe
        }
    }
    
    // MARK: - Mode Switching
    
    private func applyMode() {
        switch currentMode {
        case .qwertyEnglish:
            qwertyContainer.isHidden = false
            flickKeyboard.isHidden = true
            conversionBar.isHidden = true
            romajiConverter.clear()
            
        case .qwertyJapanese:
            qwertyContainer.isHidden = false
            flickKeyboard.isHidden = true
            conversionBar.isHidden = false
            updateConversionBar()
            
        case .flick:
            qwertyContainer.isHidden = true
            flickKeyboard.isHidden = false
            conversionBar.isHidden = true
            romajiConverter.clear()
        }
        
        updateModeButtonLabel()
        updateAppearance()
    }
    
    @objc private func cycleModePressed() {
        if currentMode == .qwertyJapanese && !romajiConverter.displayText.isEmpty {
            let text = romajiConverter.commit()
            textDocumentProxy.insertText(text)
        }
        
        switch currentMode {
        case .qwertyEnglish: currentMode = .qwertyJapanese
        case .qwertyJapanese: currentMode = .flick
        case .flick: currentMode = .qwertyEnglish
        }
        
        applyMode()
    }
    
    private func updateModeButtonLabel() {
        switch currentMode {
        case .qwertyEnglish: modeButton?.setTitle("EN", for: .normal)
        case .qwertyJapanese: modeButton?.setTitle("JA", for: .normal)
        case .flick: modeButton?.setTitle("FL", for: .normal)
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
        stack.spacing = 4
        
        for letter in letters {
            let button = createKeyButton(title: letter)
            button.addTarget(self, action: #selector(letterKeyPressed(_:)), for: .touchUpInside)
            button.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(keyTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
            stack.addArrangedSubview(button)
        }
        
        stack.heightAnchor.constraint(equalToConstant: 42).isActive = true
        return stack
    }
    
    private func createThirdRow() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        
        let shift = createSpecialKeyButton(title: "⇧")
        shift.addTarget(self, action: #selector(shiftPressed), for: .touchUpInside)
        shift.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
        shift.addTarget(self, action: #selector(keyTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        shift.widthAnchor.constraint(equalToConstant: 42).isActive = true
        self.shiftButton = shift
        stack.addArrangedSubview(shift)
        
        let lettersStack = UIStackView()
        lettersStack.axis = .horizontal
        lettersStack.distribution = .fillEqually
        lettersStack.spacing = 4
        
        for letter in letterRows[2] {
            let button = createKeyButton(title: letter)
            button.addTarget(self, action: #selector(letterKeyPressed(_:)), for: .touchUpInside)
            button.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(keyTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
            lettersStack.addArrangedSubview(button)
        }
        stack.addArrangedSubview(lettersStack)
        
        let delete = createSpecialKeyButton(title: "⌫")
        delete.addTarget(self, action: #selector(deletePressed), for: .touchUpInside)
        delete.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
        delete.addTarget(self, action: #selector(keyTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        delete.widthAnchor.constraint(equalToConstant: 42).isActive = true
        stack.addArrangedSubview(delete)
        
        stack.heightAnchor.constraint(equalToConstant: 42).isActive = true
        return stack
    }
    
    private func createBottomRow() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        
        // Next Keyboard (globe) - only if needed
        let globe = UIButton(type: .system)
        if #available(iOS 16.0, *) {
            globe.setImage(UIImage(systemName: "globe"), for: .normal)
        } else {
            globe.setTitle("🌐", for: .normal)
        }
        globe.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        globe.backgroundColor = UIColor(red: 0.68, green: 0.70, blue: 0.74, alpha: 1.0)
        globe.layer.cornerRadius = 5
        globe.layer.shadowOffset = CGSize(width: 0, height: 1)
        globe.layer.shadowRadius = 0
        globe.layer.shadowOpacity = 0.3
        globe.widthAnchor.constraint(equalToConstant: 40).isActive = true
        self.nextKeyboardButton = globe
        stack.addArrangedSubview(globe)
        
        // Mode toggle
        let mode = createSpecialKeyButton(title: "EN")
        mode.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        mode.addTarget(self, action: #selector(cycleModePressed), for: .touchUpInside)
        mode.widthAnchor.constraint(equalToConstant: 40).isActive = true
        self.modeButton = mode
        stack.addArrangedSubview(mode)
        
        // Space
        let space = createKeyButton(title: "space")
        space.titleLabel?.font = .systemFont(ofSize: 15)
        space.addTarget(self, action: #selector(spacePressed), for: .touchUpInside)
        space.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
        space.addTarget(self, action: #selector(keyTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        stack.addArrangedSubview(space)
        
        // Return
        let returnKey = createSpecialKeyButton(title: "return")
        returnKey.titleLabel?.font = .systemFont(ofSize: 15)
        returnKey.addTarget(self, action: #selector(returnPressed), for: .touchUpInside)
        returnKey.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
        returnKey.addTarget(self, action: #selector(keyTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        returnKey.widthAnchor.constraint(equalToConstant: 84).isActive = true
        stack.addArrangedSubview(returnKey)
        
        stack.heightAnchor.constraint(equalToConstant: 42).isActive = true
        return stack
    }
    
    // MARK: - Key Button Factory
    
    private func createKeyButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 22, weight: .regular)
        button.layer.cornerRadius = 5
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowRadius = 0
        button.layer.shadowOpacity = 0.3
        button.clipsToBounds = false
        return button
    }
    
    private func createSpecialKeyButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        button.layer.cornerRadius = 5
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowRadius = 0
        button.layer.shadowOpacity = 0.3
        button.clipsToBounds = false
        return button
    }
    
    // MARK: - Appearance
    
    private func updateAppearance() {
        let isDark = textDocumentProxy.keyboardAppearance == .dark || traitCollection.userInterfaceStyle == .dark
        
        if isDark {
            view.backgroundColor = UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1.0)
            conversionBar.backgroundColor = UIColor(white: 0.22, alpha: 1.0)
            updateButtonColors(
                letterBg: UIColor(white: 0.35, alpha: 1.0),
                specialBg: UIColor(white: 0.25, alpha: 1.0),
                textColor: .white,
                shadowColor: UIColor.black.cgColor
            )
        } else {
            view.backgroundColor = UIColor(red: 0.82, green: 0.84, blue: 0.86, alpha: 1.0)
            conversionBar.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
            updateButtonColors(
                letterBg: .white,
                specialBg: UIColor(red: 0.68, green: 0.70, blue: 0.74, alpha: 1.0),
                textColor: .black,
                shadowColor: UIColor(white: 0.5, alpha: 1.0).cgColor
            )
        }
        
        flickKeyboard?.updateAppearance(isDark: isDark)
    }
    
    private func updateButtonColors(letterBg: UIColor, specialBg: UIColor, textColor: UIColor, shadowColor: CGColor) {
        func applyStyle(to v: UIView) {
            if v === flickKeyboard { return }
            
            if let button = v as? UIButton {
                button.setTitleColor(textColor, for: .normal)
                button.tintColor = textColor
                button.layer.shadowColor = shadowColor
                let title = button.titleLabel?.text ?? ""
                let isSpecialKey = ["⇧", "⌫", "return", "EN", "JA", "FL"].contains(title)
                let isGlobe = button === nextKeyboardButton
                button.backgroundColor = (isSpecialKey || isGlobe) ? specialBg : letterBg
            }
            for sub in v.subviews {
                applyStyle(to: sub)
            }
        }
        applyStyle(to: qwertyContainer)
    }
    
    // MARK: - Actions (QWERTY)
    
    @objc private func letterKeyPressed(_ sender: UIButton) {
        guard let title = sender.titleLabel?.text else { return }
        
        switch currentMode {
        case .qwertyEnglish:
            let text = isShifted ? title.uppercased() : title.lowercased()
            textDocumentProxy.insertText(text)
            if isShifted {
                isShifted = false
                updateShiftState()
            }
            
        case .qwertyJapanese:
            let char = Character(title.lowercased())
            let result = romajiConverter.input(char)
            if let converted = result.justConverted {
                textDocumentProxy.insertText(converted)
            }
            updateConversionBar()
            
        case .flick:
            break
        }
    }
    
    @objc private func shiftPressed() {
        isShifted.toggle()
        updateShiftState()
    }
    
    @objc private func deletePressed() {
        if currentMode == .qwertyJapanese && !romajiConverter.buffer.isEmpty {
            let _ = romajiConverter.deleteBackward()
            updateConversionBar()
        } else {
            textDocumentProxy.deleteBackward()
        }
    }
    
    @objc private func spacePressed() {
        if currentMode == .qwertyJapanese && !romajiConverter.displayText.isEmpty {
            commitConversion()
        } else {
            textDocumentProxy.insertText(" ")
        }
    }
    
    @objc private func returnPressed() {
        if currentMode == .qwertyJapanese && !romajiConverter.displayText.isEmpty {
            commitConversion()
        }
        textDocumentProxy.insertText("\n")
    }
    
    // MARK: - Key Press Animation
    
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
    }
    
    // MARK: - Shift State
    
    private func updateShiftState() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        shiftButton?.backgroundColor = isShifted
            ? (isDark ? UIColor(white: 0.5, alpha: 1.0) : .white)
            : (isDark ? UIColor(white: 0.25, alpha: 1.0) : UIColor(red: 0.68, green: 0.70, blue: 0.74, alpha: 1.0))
        
        func updateLetters(in v: UIView) {
            if v === flickKeyboard { return }
            if let button = v as? UIButton,
               let title = button.titleLabel?.text,
               title.count == 1,
               title.rangeOfCharacter(from: .letters) != nil {
                let newTitle = isShifted ? title.uppercased() : title.lowercased()
                button.setTitle(newTitle, for: .normal)
            }
            for sub in v.subviews { updateLetters(in: sub) }
        }
        updateLetters(in: qwertyContainer)
    }
    
    // MARK: - FlickKeyboardDelegate
    
    func flickKeyboard(_ keyboard: FlickKeyboardView, didInputText text: String) {
        textDocumentProxy.insertText(text)
    }
    
    func flickKeyboardDidPressDelete(_ keyboard: FlickKeyboardView) {
        textDocumentProxy.deleteBackward()
    }
    
    func flickKeyboardDidPressDakuten(_ keyboard: FlickKeyboardView) {
        guard let before = textDocumentProxy.documentContextBeforeInput,
              let lastChar = before.last else { return }
        
        let dakutenMap: [Character: Character] = [
            "か": "が", "き": "ぎ", "く": "ぐ", "け": "げ", "こ": "ご",
            "さ": "ざ", "し": "じ", "す": "ず", "せ": "ぜ", "そ": "ぞ",
            "た": "だ", "ち": "ぢ", "つ": "づ", "て": "で", "と": "ど",
            "は": "ば", "ひ": "び", "ふ": "ぶ", "へ": "べ", "ほ": "ぼ",
            "う": "ゔ",
        ]
        
        let handakutenMap: [Character: Character] = [
            "は": "ぱ", "ひ": "ぴ", "ふ": "ぷ", "へ": "ぺ", "ほ": "ぽ",
            "ば": "ぱ", "び": "ぴ", "ぶ": "ぷ", "べ": "ぺ", "ぼ": "ぽ",
        ]
        
        let smallMap: [Character: Character] = [
            "あ": "ぁ", "い": "ぃ", "う": "ぅ", "え": "ぇ", "お": "ぉ",
            "つ": "っ", "や": "ゃ", "ゆ": "ゅ", "よ": "ょ", "わ": "ゎ",
        ]
        
        let reverseDakuten: [Character: Character] = Dictionary(uniqueKeysWithValues: dakutenMap.map { ($0.value, $0.key) })
        let reverseHandakuten: [Character: Character] = Dictionary(uniqueKeysWithValues:
            [("ぱ","は"),("ぴ","ひ"),("ぷ","ふ"),("ぺ","へ"),("ぽ","ほ")].map { (Character($0.0), Character($0.1)) }
        )
        let reverseSmall: [Character: Character] = Dictionary(uniqueKeysWithValues: smallMap.map { ($0.value, $0.key) })
        
        var newChar: Character? = nil
        
        if let dakuten = dakutenMap[lastChar] {
            newChar = dakuten
        } else if let handakuten = handakutenMap[lastChar] {
            newChar = handakuten
        } else if let small = smallMap[lastChar] {
            newChar = small
        } else if let original = reverseDakuten[lastChar] {
            if let handakuten = handakutenMap[lastChar] {
                newChar = handakuten
            } else {
                newChar = original
            }
        } else if let original = reverseHandakuten[lastChar] {
            newChar = original
        } else if let original = reverseSmall[lastChar] {
            newChar = original
        }
        
        if let newChar = newChar {
            textDocumentProxy.deleteBackward()
            textDocumentProxy.insertText(String(newChar))
        }
    }
}
