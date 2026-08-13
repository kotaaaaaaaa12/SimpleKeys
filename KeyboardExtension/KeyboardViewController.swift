import UIKit

class KeyboardViewController: UIInputViewController {
    
    // MARK: - Properties
    
    private var isShifted = false
    private var shiftButton: UIButton?
    
    private let letterRows: [[String]] = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"]
    ]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboard()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateAppearance()
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        updateAppearance()
    }
    
    // MARK: - Setup
    
    private func setupKeyboard() {
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            mainStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 3),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -3),
        ])
        
        // Row 1: Q W E R T Y U I O P
        let row1 = createLetterRow(letters: letterRows[0])
        mainStack.addArrangedSubview(row1)
        
        // Row 2: A S D F G H J K L (with side padding)
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
        mainStack.addArrangedSubview(row2Container)
        
        // Row 3: Shift Z X C V B N M Delete
        let row3 = createThirdRow()
        mainStack.addArrangedSubview(row3)
        
        // Row 4: Globe Space Return
        let row4 = createBottomRow()
        mainStack.addArrangedSubview(row4)
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
        
        // Shift button
        let shift = createSpecialKeyButton(title: "⇧")
        shift.addTarget(self, action: #selector(shiftPressed), for: .touchUpInside)
        shift.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
        shift.addTarget(self, action: #selector(keyTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        shift.widthAnchor.constraint(equalToConstant: 42).isActive = true
        self.shiftButton = shift
        stack.addArrangedSubview(shift)
        
        // Letter keys
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
        
        // Delete button
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
        
        // Globe / Next Keyboard button
        let globe = createSpecialKeyButton(title: "🌐")
        globe.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        globe.widthAnchor.constraint(equalToConstant: 42).isActive = true
        stack.addArrangedSubview(globe)
        
        // Space bar
        let space = createKeyButton(title: "space")
        space.titleLabel?.font = .systemFont(ofSize: 15)
        space.addTarget(self, action: #selector(spacePressed), for: .touchUpInside)
        space.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
        space.addTarget(self, action: #selector(keyTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        stack.addArrangedSubview(space)
        
        // Return button
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
            updateButtonColors(
                letterBg: UIColor(white: 0.35, alpha: 1.0),
                specialBg: UIColor(white: 0.25, alpha: 1.0),
                textColor: .white,
                shadowColor: UIColor.black.cgColor
            )
        } else {
            view.backgroundColor = UIColor(red: 0.82, green: 0.84, blue: 0.86, alpha: 1.0)
            updateButtonColors(
                letterBg: .white,
                specialBg: UIColor(red: 0.68, green: 0.70, blue: 0.74, alpha: 1.0),
                textColor: .black,
                shadowColor: UIColor(white: 0.5, alpha: 1.0).cgColor
            )
        }
    }
    
    private func updateButtonColors(letterBg: UIColor, specialBg: UIColor, textColor: UIColor, shadowColor: CGColor) {
        func applyStyle(to v: UIView) {
            if let button = v as? UIButton {
                button.setTitleColor(textColor, for: .normal)
                button.layer.shadowColor = shadowColor
                
                // Determine if it's a special key
                let title = button.titleLabel?.text ?? ""
                let isSpecialKey = ["⇧", "⌫", "🌐", "return"].contains(title)
                button.backgroundColor = isSpecialKey ? specialBg : letterBg
            }
            for sub in v.subviews {
                applyStyle(to: sub)
            }
        }
        applyStyle(to: view)
    }
    
    // MARK: - Actions
    
    @objc private func letterKeyPressed(_ sender: UIButton) {
        guard let title = sender.titleLabel?.text else { return }
        let text = isShifted ? title.uppercased() : title.lowercased()
        textDocumentProxy.insertText(text)
        
        if isShifted {
            isShifted = false
            updateShiftState()
        }
    }
    
    @objc private func shiftPressed() {
        isShifted.toggle()
        updateShiftState()
    }
    
    @objc private func deletePressed() {
        textDocumentProxy.deleteBackward()
    }
    
    @objc private func spacePressed() {
        textDocumentProxy.insertText(" ")
    }
    
    @objc private func returnPressed() {
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
        shiftButton?.backgroundColor = isShifted
            ? .white
            : UIColor(red: 0.68, green: 0.70, blue: 0.74, alpha: 1.0)
        
        // Update letter labels
        func updateLetters(in v: UIView) {
            if let button = v as? UIButton,
               let title = button.titleLabel?.text,
               title.count == 1,
               title.rangeOfCharacter(from: .letters) != nil {
                let newTitle = isShifted ? title.uppercased() : title.lowercased()
                button.setTitle(newTitle, for: .normal)
            }
            for sub in v.subviews {
                updateLetters(in: sub)
            }
        }
        updateLetters(in: view)
    }
}
