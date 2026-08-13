import UIKit

@objc(KeyboardViewController)
class KeyboardViewController: UIInputViewController, FlickKeyboardDelegate {
    private var alternateKeysPopup: UIView?
    private var alternateLabels: [UILabel] = []
    private var currentLongPressButton: UIButton?

    
    // MARK: - Types
    
    enum InputMode {
        case flickKana
        case flickAlphabet
        case flickNumber
        case qwertyEnglish
        case qwertyNumbers
        case qwertySymbols
        case qwertyRomaji
    }
    
    enum ShiftState {
        case off
        case shifted
        case capsLock
    }
    
    // MARK: - Properties
    
    private var currentMode: InputMode = .qwertyEnglish
    private var qwertyShifted = false
    private var shiftState: ShiftState = .off
    private var lastShiftPressTime: Date = Date.distantPast
    private var qwertyContainer: UIView!
    private var qwertyStack: UIStackView!
    private var qwertyDeleteTimer: Timer?
    private var nextKeyboardButton: UIButton?
    
    private let romajiConverter = RomajiConverter()
    
    private var flickKeyboard: FlickKeyboardView!
    private var conversionBar: UIView!
    private var conversionLabel: UILabel!
    private var candidateScrollView: UIScrollView!
    private var candidateStack: UIStackView!
    private var expandButton: UIButton!
    private var currentCandidates: [String] = []
    
    // Expanded candidates
    private var expandedCandidateView: UIView!
    private var expandedCandidateScrollView: UIScrollView!
    private var expandedCandidateStack: UIStackView! // Better to use a wrapping layout or a collection view. A wrapping Custom Flow Layout with UICollectionView is best, but a simple UIScrollView with a wrapping logic or just a vertical stack of horizontal stacks works. For simplicity, we'll use a wrapping Custom View or a Flow Layout. Let's use a UICollectionView.
    private var candidateCollectionView: UICollectionView!
    private var isExpanded: Bool = false
    private var expandedStartIndex: Int = 0
    
    // One-handed mode constraints
    private var flickLeadingConstraint: NSLayoutConstraint!
    private var flickTrailingConstraint: NSLayoutConstraint!
    private var qwertyLeadingConstraint: NSLayoutConstraint!
    private var qwertyTrailingConstraint: NSLayoutConstraint!
    
    private var englishBuffer: String = ""
    private var qwertyReturnButton: UIButton?
    
    private var qwertySpaceDragStart: CGPoint = .zero
    
    // UI Elements
    private var geminiDebounceTimer: Timer?
    
    private let kanjiConverter = KanjiConverter.shared
    
    private let letterRows: [[String]] = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"]
    ]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Read default keyboard mode
        let defaults = AppGroupHelper.shared.userDefaults
        defaults?.synchronize()
        
        // Mark that the keyboard has been activated at least once
        defaults?.set(true, forKey: "keyboardHasLaunched")
        defaults?.synchronize()
        let enableFlick = defaults?.object(forKey: "enableFlick") == nil ? true : defaults!.bool(forKey: "enableFlick")
        let enableQwertyEn = defaults?.object(forKey: "enableQwertyEnglish") == nil ? true : defaults!.bool(forKey: "enableQwertyEnglish")
        let enableQwertyJa = defaults?.object(forKey: "enableQwertyRomaji") == nil ? true : defaults!.bool(forKey: "enableQwertyRomaji")
        
        if enableFlick {
            currentMode = .flickKana
        } else if enableQwertyEn {
            currentMode = .qwertyEnglish
        } else {
            currentMode = .qwertyRomaji
        }
        
        setupConversionBar()
        setupQWERTYKeyboard()
        setupFlickKeyboard()
        applyMode()
        
        let heightConstraint = view.heightAnchor.constraint(equalToConstant: 260)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let defaults = AppGroupHelper.shared.userDefaults
        defaults?.synchronize()
        let enableFlick = defaults?.object(forKey: "enableFlick") == nil ? true : defaults!.bool(forKey: "enableFlick")
        let enableQwertyEn = defaults?.object(forKey: "enableQwertyEnglish") == nil ? true : defaults!.bool(forKey: "enableQwertyEnglish")
        
        if enableFlick {
            currentMode = .flickKana
        } else if enableQwertyEn {
            currentMode = .qwertyEnglish
        } else {
            currentMode = .qwertyRomaji
        }
        applyMode()
        
        updateNextKeyboardButtonVisibility()
        updateAppearance()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateAppearance()
        updateOneHandedMode()
    }
    
    private func updateOneHandedMode() {
        guard flickLeadingConstraint != nil else { return }
        
        let mode = AppGroupHelper.shared.userDefaults?.string(forKey: "oneHandedMode") ?? "off"
        let screenWidth = UIScreen.main.bounds.width
        let offset = screenWidth * 0.25 // Shrink to 75% width
        
        if mode == "left" {
            flickLeadingConstraint.constant = 0
            flickTrailingConstraint.constant = -offset
            qwertyLeadingConstraint.constant = 0
            qwertyTrailingConstraint.constant = -offset
        } else if mode == "right" {
            flickLeadingConstraint.constant = offset
            flickTrailingConstraint.constant = 0
            qwertyLeadingConstraint.constant = offset
            qwertyTrailingConstraint.constant = 0
        } else {
            flickLeadingConstraint.constant = 0
            flickTrailingConstraint.constant = 0
            qwertyLeadingConstraint.constant = 0
            qwertyTrailingConstraint.constant = 0
        }
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        updateAppearance()
        
        // If text was externally cleared (e.g., sent in LINE), clear our buffers
        if !textDocumentProxy.hasText {
            if romajiConverter.hasPendingInput || !englishBuffer.isEmpty {
                _ = romajiConverter.commit()
                englishBuffer = ""
                updateConversionBar()
            }
        }
    }
    
    // MARK: - Conversion Bar
    
    private func setupConversionBar() {
        conversionBar = UIView()
        conversionBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(conversionBar)
        
        conversionLabel = UILabel()
        conversionLabel.font = .systemFont(ofSize: 14, weight: .regular)
        conversionLabel.textColor = .placeholderText
        conversionLabel.translatesAutoresizingMaskIntoConstraints = false
        conversionBar.addSubview(conversionLabel)
        
        candidateScrollView = UIScrollView()
        candidateScrollView.showsHorizontalScrollIndicator = false
        candidateScrollView.translatesAutoresizingMaskIntoConstraints = false
        conversionBar.addSubview(candidateScrollView)
        
        candidateStack = UIStackView()
        candidateStack.axis = .horizontal
        candidateStack.spacing = 8
        candidateStack.distribution = .fillProportionally
        candidateStack.translatesAutoresizingMaskIntoConstraints = false
        candidateScrollView.addSubview(candidateStack)
        
        setupExpandedCandidateView()
        
        expandButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(weight: .bold)
        expandButton.setImage(UIImage(systemName: "chevron.down", withConfiguration: config), for: .normal)
        expandButton.tintColor = .label
        expandButton.translatesAutoresizingMaskIntoConstraints = false
        expandButton.addTarget(self, action: #selector(expandButtonTapped), for: .touchUpInside)
        conversionBar.addSubview(expandButton)
        
        NSLayoutConstraint.activate([
            conversionBar.topAnchor.constraint(equalTo: view.topAnchor),
            conversionBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            conversionBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            conversionBar.heightAnchor.constraint(equalToConstant: 46),
            
            conversionLabel.leadingAnchor.constraint(equalTo: conversionBar.leadingAnchor, constant: 12),
            conversionLabel.centerYAnchor.constraint(equalTo: conversionBar.centerYAnchor),
            conversionLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 80),
            
            expandButton.trailingAnchor.constraint(equalTo: conversionBar.trailingAnchor),
            expandButton.centerYAnchor.constraint(equalTo: conversionBar.centerYAnchor),
            expandButton.widthAnchor.constraint(equalToConstant: 44),
            expandButton.heightAnchor.constraint(equalToConstant: 46),
            
            candidateScrollView.leadingAnchor.constraint(equalTo: conversionLabel.trailingAnchor, constant: 8),
            candidateScrollView.trailingAnchor.constraint(equalTo: expandButton.leadingAnchor),
            candidateScrollView.topAnchor.constraint(equalTo: conversionBar.topAnchor),
            candidateScrollView.bottomAnchor.constraint(equalTo: conversionBar.bottomAnchor),
            
            candidateStack.leadingAnchor.constraint(equalTo: candidateScrollView.contentLayoutGuide.leadingAnchor),
            candidateStack.trailingAnchor.constraint(equalTo: candidateScrollView.contentLayoutGuide.trailingAnchor),
            candidateStack.topAnchor.constraint(equalTo: candidateScrollView.contentLayoutGuide.topAnchor),
            candidateStack.bottomAnchor.constraint(equalTo: candidateScrollView.contentLayoutGuide.bottomAnchor),
            candidateStack.heightAnchor.constraint(equalTo: candidateScrollView.frameLayoutGuide.heightAnchor)
        ])
    }
    
    private func setupExpandedCandidateView() {
        expandedCandidateView = UIView()
        expandedCandidateView.backgroundColor = UIColor.systemBackground
        expandedCandidateView.translatesAutoresizingMaskIntoConstraints = false
        expandedCandidateView.isHidden = true
        view.addSubview(expandedCandidateView)
        
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = CGSize(width: 80, height: 44)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        candidateCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        candidateCollectionView.backgroundColor = .clear
        candidateCollectionView.translatesAutoresizingMaskIntoConstraints = false
        candidateCollectionView.register(CandidateCell.self, forCellWithReuseIdentifier: "CandidateCell")
        candidateCollectionView.dataSource = self
        candidateCollectionView.delegate = self
        expandedCandidateView.addSubview(candidateCollectionView)
        
        NSLayoutConstraint.activate([
            expandedCandidateView.topAnchor.constraint(equalTo: conversionBar.bottomAnchor),
            expandedCandidateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            expandedCandidateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            expandedCandidateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            candidateCollectionView.topAnchor.constraint(equalTo: expandedCandidateView.topAnchor),
            candidateCollectionView.leadingAnchor.constraint(equalTo: expandedCandidateView.leadingAnchor),
            candidateCollectionView.trailingAnchor.constraint(equalTo: expandedCandidateView.trailingAnchor),
            candidateCollectionView.bottomAnchor.constraint(equalTo: expandedCandidateView.bottomAnchor)
        ])
    }
    
    @objc private func expandButtonTapped() {
        if !isExpanded {
            // Calculate how many items are visible in the scroll view
            var visibleCount = 0
            for view in candidateStack.arrangedSubviews {
                // If the right edge of the button is within the scroll view's visible width
                if view.frame.maxX <= candidateScrollView.bounds.width {
                    visibleCount += 1
                } else {
                    break
                }
            }
            // If none are fully visible (very long word), at least skip 1
            expandedStartIndex = max(visibleCount, 1)
            // If expandedStartIndex is >= currentCandidates.count, cap it
            expandedStartIndex = min(expandedStartIndex, max(0, currentCandidates.count - 1))
        }
        
        isExpanded.toggle()
        updateExpandUI()
    }
    
    private func updateExpandUI() {
        let config = UIImage.SymbolConfiguration(weight: .bold)
        let iconName = isExpanded ? "chevron.up" : "chevron.down"
        expandButton.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
        
        expandedCandidateView.isHidden = !isExpanded
        if isExpanded {
            candidateCollectionView.reloadData()
            view.bringSubviewToFront(expandedCandidateView)
            expandedCandidateView.layer.zPosition = 2000
        } else {
            expandedCandidateView.layer.zPosition = 0
        }
    }
    
    private func updateConversionBar() {
        let displayRomaji = romajiConverter.displayText
        let displayEnglish = englishBuffer
        
        let display = !displayRomaji.isEmpty ? displayRomaji : displayEnglish
        
        // Update Return Key Title
        let flickReturnTitle = display.isEmpty ? "改行" : "確定"
        flickKeyboard?.setReturnKeyTitle(flickReturnTitle)
        let qwertyReturnTitle = display.isEmpty ? "return" : "確定"
        qwertyReturnButton?.setTitle(qwertyReturnTitle, for: .normal)
        
        // Clear previous candidates
        for subview in candidateStack.arrangedSubviews {
            subview.removeFromSuperview()
        }
        
        if display.isEmpty {
            conversionLabel.text = " "
            conversionLabel.textColor = .placeholderText
            currentCandidates = []
        } else {
            conversionLabel.text = display
            conversionLabel.textColor = .label
            
            if !displayRomaji.isEmpty {
                currentCandidates = kanjiConverter.convert(displayRomaji)
            } else {
                currentCandidates = EnglishConverter.shared.candidates(for: displayEnglish)
            }
            
            if currentCandidates.isEmpty {
                currentCandidates = [display]
            }
            
            let defaults = AppGroupHelper.shared.userDefaults
            let enableGemini = defaults?.bool(forKey: "enableGemini") ?? false
            let apiKey = defaults?.string(forKey: "geminiApiKey") ?? ""
            
            if displayRomaji == "あぷり" {
                currentCandidates.insert("Grp: \(AppGroupHelper.shared.appGroupID) Key:\(apiKey.isEmpty ? "無" : "有") On:\(enableGemini)", at: 0)
            }
            
            // User Dictionary
            if let data = defaults?.data(forKey: "userDictionary"),
               let dictItems = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] {
                let userMatches = dictItems.filter { $0["yomi"] == display }.compactMap { $0["kaki"] }
                if !userMatches.isEmpty {
                    currentCandidates.insert(contentsOf: userMatches, at: 0)
                }
            }
            
            for (index, candidate) in currentCandidates.enumerated() {
                let button = UIButton(type: .system)
                button.setTitle(candidate, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 20)
                button.setTitleColor(.label, for: .normal)
                button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
                button.tag = index
                button.addTarget(self, action: #selector(candidateTapped(_:)), for: .touchUpInside)
                candidateStack.addArrangedSubview(button)
            }
            
            if isExpanded {
                candidateCollectionView.reloadData()
            }
            
            // Trigger Gemini Conversion if enabled
            geminiDebounceTimer?.invalidate()
            if enableGemini && !apiKey.isEmpty && !displayRomaji.isEmpty {
                let currentText = displayRomaji
                let modelName = defaults?.string(forKey: "geminiModel") ?? "gemini-3.5-flash"
                let actualModelName = modelName.isEmpty ? "gemini-3.5-flash" : modelName
                
                geminiDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
                    GeminiConverter.shared.convert(text: currentText, apiKey: apiKey, model: actualModelName) { [weak self] geminiCandidates in
                        guard let self = self, self.romajiConverter.displayText == currentText, !geminiCandidates.isEmpty else { return }
                        
                        // Prepended Gemini candidates
                        var newCandidates = geminiCandidates
                        
                        if let data = AppGroupHelper.shared.userDefaults?.data(forKey: "userDictionary"),
                           let dictItems = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] {
                            let userMatches = dictItems.filter { $0["yomi"] == currentText }.compactMap { $0["kaki"] }
                            if !userMatches.isEmpty {
                                newCandidates.insert(contentsOf: userMatches, at: 0)
                            }
                        }
                        
                        newCandidates.append(contentsOf: self.currentCandidates)
                        
                        // Deduplicate keeping order
                        var unique = [String]()
                        for c in newCandidates {
                            if !unique.contains(c) { unique.append(c) }
                        }
                        self.currentCandidates = unique
                        
                        // Re-render
                        for subview in self.candidateStack.arrangedSubviews {
                            subview.removeFromSuperview()
                        }
                        for (index, candidate) in self.currentCandidates.enumerated() {
                            let button = UIButton(type: .system)
                            button.setTitle(candidate, for: .normal)
                            button.titleLabel?.font = .systemFont(ofSize: 20)
                            button.setTitleColor(.label, for: .normal)
                            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
                            button.tag = index
                            button.addTarget(self, action: #selector(self.candidateTapped(_:)), for: .touchUpInside)
                            self.candidateStack.addArrangedSubview(button)
                        }
                        if self.isExpanded {
                            self.candidateCollectionView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    @objc private func candidateTapped(_ sender: UIButton) {
        commitCandidate(at: sender.tag)
    }
    
    private func commitCandidate(at index: Int) {
        guard index >= 0 && index < currentCandidates.count else { return }
        let text = currentCandidates[index]
        
        textDocumentProxy.insertText(text)
        if romajiConverter.hasPendingInput {
            _ = romajiConverter.commit()
        } else {
            englishBuffer = ""
        }
        
        textDocumentProxy.setMarkedText("", selectedRange: NSRange(location: 0, length: 0))
        
        if isExpanded {
            isExpanded = false
            updateExpandUI()
        }
        
        updateConversionBar()
    }
    
    @objc private func commitConversion() {
        let text = romajiConverter.commit()
        if !text.isEmpty {
            textDocumentProxy.insertText(text)
            textDocumentProxy.setMarkedText("", selectedRange: NSRange(location: 0, length: 0))
        }
        updateConversionBar()
    }
    
    // MARK: - QWERTY Setup
    
    private func setupQWERTYKeyboard() {
        qwertyContainer = UIView()
        qwertyContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(qwertyContainer)
        
        let qwertyBottom = qwertyContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        qwertyBottom.priority = .defaultHigh
        
        qwertyLeadingConstraint = qwertyContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        qwertyTrailingConstraint = qwertyContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        
        NSLayoutConstraint.activate([
            qwertyContainer.topAnchor.constraint(equalTo: conversionBar.bottomAnchor, constant: 2),
            qwertyBottom,
            qwertyLeadingConstraint,
            qwertyTrailingConstraint
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
            bottomRow = ["123", "globe", "space", "return"]
        case .qwertySymbols:
            rows = [
                ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="],
                ["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"],
                [".", ",", "?", "!", "'"]
            ]
            thirdRowSpecials = ("123", "⌫")
            bottomRow = ["123", "globe", "space", "return"]
        case .qwertyEnglish, .qwertyRomaji:
            rows = qwertyShifted ? letterRows.map { $0.map { $0.uppercased() } } : letterRows.map { $0.map { $0.lowercased() } }
            thirdRowSpecials = ("⇧", "⌫")
            bottomRow = ["123", "globe", "space", "return"]
        default:
            return
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
        let leftSpecial: UIButton
        if thirdRowSpecials.left == "⇧" {
            let imgName: String
            switch shiftState {
            case .off: imgName = "shift"
            case .shifted: imgName = "shift.fill"
            case .capsLock: imgName = "capslock.fill"
            }
            leftSpecial = createSpecialImageKeyButton(systemName: imgName)
            leftSpecial.addTarget(self, action: #selector(shiftPressed), for: .touchUpInside)
        } else {
            leftSpecial = createSpecialKeyButton(title: thirdRowSpecials.left)
            if thirdRowSpecials.left == "#+=" {
                leftSpecial.addTarget(self, action: #selector(switchToSymbols), for: .touchUpInside)
            } else if thirdRowSpecials.left == "123" {
                leftSpecial.addTarget(self, action: #selector(switchToNumbers), for: .touchUpInside)
            }
        }
        
        let rightSpecial: UIButton
        if thirdRowSpecials.right == "⌫" {
            rightSpecial = createSpecialImageKeyButton(systemName: "delete.left")
            rightSpecial.addTarget(self, action: #selector(deleteTouchDown), for: .touchDown)
            rightSpecial.addTarget(self, action: #selector(deleteTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        } else {
            rightSpecial = createSpecialKeyButton(title: thirdRowSpecials.right)
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
                let globe = createSpecialImageKeyButton(systemName: "globe")
                globe.addTarget(self, action: #selector(toggleMainMode), for: .touchUpInside)
                globe.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
                globe.addTarget(self, action: #selector(keyTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
                globe.widthAnchor.constraint(equalToConstant: 42).isActive = true
                bottomStack.addArrangedSubview(globe)
            } else if key == "space" {
                let spaceBtn = createKeyButton(title: currentMode == .qwertyRomaji ? "空白" : "space")
                spaceBtn.titleLabel?.font = .systemFont(ofSize: 20, weight: .regular)
                spaceBtn.addTarget(self, action: #selector(spacePressed), for: .touchUpInside)
                spaceBtn.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
                spaceBtn.addTarget(self, action: #selector(keyTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
                let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleQwertySpaceLongPress(_:)))
                longPress.minimumPressDuration = 0.35
                spaceBtn.addGestureRecognizer(longPress)
                bottomStack.addArrangedSubview(spaceBtn)
            } else if key == "return" {
                let retBtn = createSpecialKeyButton(title: "return")
                retBtn.addTarget(self, action: #selector(returnPressed), for: .touchUpInside)
                retBtn.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
                retBtn.addTarget(self, action: #selector(keyTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
                retBtn.widthAnchor.constraint(equalToConstant: 80).isActive = true
                qwertyReturnButton = retBtn
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
        flickKeyboard.clipsToBounds = false
        flickKeyboard.translatesAutoresizingMaskIntoConstraints = false
        flickKeyboard.isHidden = true
        view.clipsToBounds = false
        view.addSubview(flickKeyboard)
        
        let flickBottom = flickKeyboard.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4)
        flickBottom.priority = .defaultHigh
        
        flickLeadingConstraint = flickKeyboard.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        flickTrailingConstraint = flickKeyboard.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        
        NSLayoutConstraint.activate([
            flickKeyboard.topAnchor.constraint(equalTo: conversionBar.bottomAnchor, constant: 2),
            flickBottom,
            flickLeadingConstraint,
            flickTrailingConstraint
        ])
        
        flickKeyboard.layer.zPosition = 1000
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
        
        if title.count == 1 && title.first?.isLetter == true {
            let lp = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            lp.minimumPressDuration = 0.4
            button.addGestureRecognizer(lp)
        }
        
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
    
    private func createSpecialImageKeyButton(systemName: String) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
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
                    btn.tintColor = textColor
                    let title = btn.titleLabel?.text ?? ""
                    let isSpecialKey = btn.image(for: .normal) != nil || ["return", "123", "ABC", "#+="].contains(title)
                    btn.backgroundColor = isSpecialKey ? specialBg : letterBg
                } else if let nestedStack = sub as? UIStackView {
                    nestedStack.arrangedSubviews.forEach { btn in
                        if let b = btn as? UIButton {
                            b.setTitleColor(textColor, for: .normal)
                            b.tintColor = textColor
                            let title = b.titleLabel?.text ?? ""
                            let isSpecialKey = b.image(for: .normal) != nil || ["return", "123", "ABC", "#+="].contains(title)
                            b.backgroundColor = isSpecialKey ? specialBg : letterBg
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Long Press Alternates
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let button = gesture.view as? UIButton, let title = button.titleLabel?.text else { return }
        
        let alternatesMap: [String: [String]] = [
            "e": ["e", "è", "é", "ê", "ë", "ē", "ė", "ę"],
            "y": ["y", "ÿ", "ý"],
            "u": ["u", "û", "ü", "ù", "ú", "ū"],
            "i": ["i", "î", "ï", "í", "ī", "į", "ì"],
            "o": ["o", "ô", "ö", "ò", "ó", "œ", "ø", "ō", "õ"],
            "a": ["a", "à", "á", "â", "ä", "æ", "ã", "å", "ā"],
            "s": ["s", "ß", "ś", "š"],
            "l": ["l", "ł"],
            "z": ["z", "ž", "ź", "ż"],
            "c": ["c", "ç", "ć", "č"],
            "n": ["n", "ñ", "ń"]
        ]
        
        let lower = title.lowercased()
        guard let alternates = alternatesMap[lower] else { return }
        let isUpper = title != lower
        let displayAlts = isUpper ? alternates.map { $0.uppercased() } : alternates
        
        let point = gesture.location(in: view)
        
        switch gesture.state {
        case .began:
            currentLongPressButton = button
            showAlternatePopup(for: button, alternates: displayAlts)
            updateAlternateHighlight(at: point)
        case .changed:
            updateAlternateHighlight(at: point)
        case .ended, .cancelled:
            if let popup = alternateKeysPopup {
                var selected: String? = nil
                for lbl in alternateLabels {
                    if lbl.backgroundColor == .systemBlue {
                        selected = lbl.text
                        break
                    }
                }
                if let sel = selected, gesture.state == .ended {
                    textDocumentProxy.insertText(sel)
                    UIDevice.current.playInputClick()
                    
                    if shiftState == .shifted {
                        shiftState = .off
                        qwertyShifted = false
                        rebuildQWERTYLayout()
                        updateButtonColors()
                    }
                }
                popup.removeFromSuperview()
                alternateKeysPopup = nil
                alternateLabels.removeAll()
            }
            currentLongPressButton = nil
        default:
            break
        }
    }
    
    private func showAlternatePopup(for button: UIButton, alternates: [String]) {
        let popup = UIView()
        popup.backgroundColor = (textDocumentProxy.keyboardAppearance == .dark || traitCollection.userInterfaceStyle == .dark) ? UIColor(white: 0.25, alpha: 1.0) : .white
        popup.layer.cornerRadius = 8
        popup.layer.shadowColor = UIColor.black.cgColor
        popup.layer.shadowOpacity = 0.3
        popup.layer.shadowOffset = CGSize(width: 0, height: 2)
        popup.layer.shadowRadius = 4
        
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        popup.addSubview(stack)
        
        for alt in alternates {
            let lbl = UILabel()
            lbl.text = alt
            lbl.textAlignment = .center
            lbl.font = .systemFont(ofSize: 22, weight: .regular)
            lbl.textColor = (textDocumentProxy.keyboardAppearance == .dark || traitCollection.userInterfaceStyle == .dark) ? .white : .black
            lbl.layer.cornerRadius = 6
            lbl.layer.masksToBounds = true
            stack.addArrangedSubview(lbl)
            alternateLabels.append(lbl)
            lbl.widthAnchor.constraint(equalToConstant: 36).isActive = true
        }
        
        view.addSubview(popup)
        popup.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: popup.topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: popup.bottomAnchor, constant: -4),
            stack.leadingAnchor.constraint(equalTo: popup.leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: popup.trailingAnchor, constant: -4),
            
            popup.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -8),
            popup.centerXAnchor.constraint(equalTo: button.centerXAnchor)
        ])
        
        alternateKeysPopup = popup
    }
    
    private func updateAlternateHighlight(at point: CGPoint) {
        guard let popup = alternateKeysPopup, let stack = popup.subviews.first as? UIStackView else { return }
        let localPoint = view.convert(point, to: stack)
        
        for lbl in alternateLabels {
            lbl.backgroundColor = .clear
            lbl.textColor = (textDocumentProxy.keyboardAppearance == .dark || traitCollection.userInterfaceStyle == .dark) ? .white : .black
        }
        
        if !alternateLabels.isEmpty {
            var closestLabel = alternateLabels[0]
            var minDistance = CGFloat.greatestFiniteMagnitude
            
            for lbl in alternateLabels {
                let midX = lbl.frame.midX
                let dist = abs(localPoint.x - midX)
                if dist < minDistance {
                    minDistance = dist
                    closestLabel = lbl
                }
            }
            
            closestLabel.backgroundColor = .systemBlue
            closestLabel.textColor = .white
        }
    }
    
    // MARK: - Actions
    
    @objc private func letterKeyPressed(_ sender: UIButton) {
        guard let title = sender.titleLabel?.text else { return }
        if currentMode == .qwertyRomaji {
            if let char = title.lowercased().first {
                _ = romajiConverter.input(char)
            }
            let display = romajiConverter.displayText
            textDocumentProxy.setMarkedText(display, selectedRange: NSRange(location: display.utf16.count, length: 0))
            updateConversionBar()
        } else {
            englishBuffer += title
            textDocumentProxy.setMarkedText(englishBuffer, selectedRange: NSRange(location: englishBuffer.utf16.count, length: 0))
            updateConversionBar()
        }
        
        if shiftState == .shifted {
            shiftState = .off
            qwertyShifted = false
            rebuildQWERTYLayout()
            updateButtonColors()
        }
        
        UIDevice.current.playInputClick()
    }
    
    @objc private func shiftPressed() {
        let now = Date()
        if now.timeIntervalSince(lastShiftPressTime) < 0.3 {
            shiftState = .capsLock
        } else {
            if shiftState == .off {
                shiftState = .shifted
            } else {
                shiftState = .off
            }
        }
        lastShiftPressTime = now
        qwertyShifted = (shiftState != .off)
        rebuildQWERTYLayout()
        updateButtonColors()
        UIDevice.current.playInputClick()
    }
    
    @objc private func switchToNumbers() {
        let defaults = AppGroupHelper.shared.userDefaults
        let flickAlphabetIsQwerty = defaults?.bool(forKey: "flickAlphabetIsQwerty") ?? false
        
        if flickAlphabetIsQwerty && (currentMode == .qwertyEnglish) {
            currentMode = .flickNumber
        } else {
            currentMode = .qwertyNumbers
        }
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
        if (romajiConverter.hasPendingInput || !englishBuffer.isEmpty) && !currentCandidates.isEmpty {
            commitCandidate(at: 0)
        } else {
            textDocumentProxy.insertText(" ")
        }
        UIDevice.current.playInputClick()
    }
    
    @objc private func returnPressed() {
        if romajiConverter.hasPendingInput || !englishBuffer.isEmpty {
            textDocumentProxy.setMarkedText("", selectedRange: NSRange(location: 0, length: 0))
            textDocumentProxy.unmarkText()
            let text = romajiConverter.hasPendingInput ? romajiConverter.commit() : englishBuffer
            if !text.isEmpty { textDocumentProxy.insertText(text) }
            englishBuffer = ""
            updateConversionBar()
            UIDevice.current.playInputClick()
            return
        }
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
        if romajiConverter.hasPendingInput {
            _ = romajiConverter.deleteBackward()
            let display = romajiConverter.displayText
            if display.isEmpty {
                textDocumentProxy.setMarkedText("", selectedRange: NSRange(location: 0, length: 0))
                textDocumentProxy.unmarkText()
            } else {
                textDocumentProxy.setMarkedText(display, selectedRange: NSRange(location: display.utf16.count, length: 0))
            }
            updateConversionBar()
        } else if !englishBuffer.isEmpty {
            englishBuffer.removeLast()
            if englishBuffer.isEmpty {
                textDocumentProxy.setMarkedText("", selectedRange: NSRange(location: 0, length: 0))
                textDocumentProxy.unmarkText()
            } else {
                textDocumentProxy.setMarkedText(englishBuffer, selectedRange: NSRange(location: englishBuffer.utf16.count, length: 0))
            }
            updateConversionBar()
        } else {
            textDocumentProxy.deleteBackward()
        }
        UIDevice.current.playInputClick()
    }
    
    @objc private func keyTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.05, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            sender.alpha = 0.8
        }
    }
    
    @objc private func keyTouchUp(_ sender: UIButton) {
        lastFlickTapBaseChar = nil
        UIDevice.current.playInputClick()
        UIView.animate(withDuration: 0.1, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
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
        flickKeyboard.updateAppearance(isDark: textDocumentProxy.keyboardAppearance == .dark)
    }
    
    // MARK: - QWERTY Space Drag
    
    @objc private func handleQwertySpaceLongPress(_ gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: view)
        
        if gesture.state == .began {
            qwertySpaceDragStart = point
            setKeyboardLabelsAlpha(0.0)
            UIDevice.current.playInputClick()
        } else if gesture.state == .changed {
            let dx = point.x - qwertySpaceDragStart.x
            if dx > 20 {
                textDocumentProxy.adjustTextPosition(byCharacterOffset: 1)
                qwertySpaceDragStart = CGPoint(x: qwertySpaceDragStart.x + 20, y: qwertySpaceDragStart.y)
                UIDevice.current.playInputClick()
            } else if dx < -20 {
                textDocumentProxy.adjustTextPosition(byCharacterOffset: -1)
                qwertySpaceDragStart = CGPoint(x: qwertySpaceDragStart.x - 20, y: qwertySpaceDragStart.y)
                UIDevice.current.playInputClick()
            }
        } else if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
            setKeyboardLabelsAlpha(1.0)
            // Normal space press is handled by spacePressed since touchUpInside might trigger.
            // But actually touchUpInside is cancelled by long press.
        }
    }
    
    // MARK: - Label Fade (Blur)
    
    private func setKeyboardLabelsAlpha(_ alpha: CGFloat) {
        UIView.animate(withDuration: 0.15) {
            // For QWERTY
            self.qwertyStack.arrangedSubviews.forEach { row in
                if let stackRow = row as? UIStackView {
                    stackRow.arrangedSubviews.forEach { btn in
                        if let btn = btn as? UIButton, btn.accessibilityIdentifier != "space" {
                            btn.titleLabel?.alpha = alpha
                            btn.imageView?.alpha = alpha
                        }
                    }
                }
            }
            // For Flick
            self.flickKeyboard.setKeysAlpha(alpha)
        }
    }
    
    // MARK: - FlickKeyboardDelegate
    
    @objc private func handleQWERTYGlobeTap(_ gesture: UITapGestureRecognizer) {
        toggleMainMode()
    }
    
    private var lastFlickTapTime: Date?
    private var lastFlickTapBaseChar: String?
    private var toggleIndex = 0
    
    private func getToggleChar(baseChar: String, index: Int) -> String? {
        let groups = [
            ["あ", "い", "う", "え", "お", "ぁ", "ぃ", "ぅ", "ぇ", "ぉ"],
            ["か", "き", "く", "け", "こ"],
            ["さ", "し", "す", "せ", "そ"],
            ["た", "ち", "つ", "て", "と", "っ"],
            ["な", "に", "ぬ", "ね", "の"],
            ["は", "ひ", "ふ", "へ", "ほ"],
            ["ま", "み", "む", "め", "も"],
            ["や", "ゆ", "よ", "ゃ", "ゅ", "ょ"],
            ["ら", "り", "る", "れ", "ろ"],
            ["わ", "を", "ん", "ー", "ゎ"],
            ["、", "。", "？", "！"],
            ["a", "b", "c", "A", "B", "C"],
            ["d", "e", "f", "D", "E", "F"],
            ["g", "h", "i", "G", "H", "I"],
            ["j", "k", "l", "J", "K", "L"],
            ["m", "n", "o", "M", "N", "O"],
            ["p", "q", "r", "s", "P", "Q", "R", "S"],
            ["t", "u", "v", "T", "U", "V"],
            ["w", "x", "y", "z", "W", "X", "Y", "Z"],
            ["@", "#", "/", "&", "_"],
            ["’", "\"", "(", ")"],
            [".", ",", "?", "!"],
            ["(", ")", "[", "]"],
            [",", ".", "-", "/"],
            ["0", "～", "…"]
        ]
        
        for group in groups {
            if group.first == baseChar {
                return group[index % group.count]
            }
        }
        return nil
    }
    
    func flickKeyboard(_ keyboard: FlickKeyboardView, didInputText text: String, direction: FlickKeyboardView.FlickDirection) {
        let flickOnly = AppGroupHelper.shared.userDefaults?.bool(forKey: "flickOnly") ?? false
        var isToggle = false
        var newChar = text
        
        if !flickOnly && direction == .center {
            if let baseChar = lastFlickTapBaseChar, text == baseChar, let lastTime = lastFlickTapTime, Date().timeIntervalSince(lastTime) < 1.0 {
                toggleIndex += 1
                if let toggleChar = getToggleChar(baseChar: baseChar, index: toggleIndex) {
                    newChar = toggleChar
                    isToggle = true
                    lastFlickTapTime = Date()
                } else {
                    lastFlickTapBaseChar = text
                    lastFlickTapTime = Date()
                    toggleIndex = 0
                }
            } else {
                lastFlickTapBaseChar = text
                lastFlickTapTime = Date()
                toggleIndex = 0
            }
        } else {
            lastFlickTapBaseChar = nil
            toggleIndex = 0
        }
        
        if keyboard.currentPage == .kana {
            if isToggle {
                romajiConverter.replaceLastKana(with: newChar)
            } else {
                romajiConverter.inputKana(newChar)
            }
            let display = romajiConverter.displayText
            textDocumentProxy.setMarkedText(display, selectedRange: NSRange(location: display.utf16.count, length: 0))
            updateConversionBar()
        } else {
            // English / Number
            if isToggle {
                if !englishBuffer.isEmpty {
                    englishBuffer.removeLast()
                } else {
                    textDocumentProxy.deleteBackward()
                }
            }
            englishBuffer += newChar
            textDocumentProxy.setMarkedText(englishBuffer, selectedRange: NSRange(location: englishBuffer.utf16.count, length: 0))
            updateConversionBar()
        }
    }
    
    @objc private func toggleMainMode() {
        let defaults = AppGroupHelper.shared.userDefaults
        let enableFlick = defaults?.object(forKey: "enableFlick") == nil ? true : defaults!.bool(forKey: "enableFlick")
        let enableQwertyEn = defaults?.object(forKey: "enableQwertyEnglish") == nil ? true : defaults!.bool(forKey: "enableQwertyEnglish")
        let enableQwertyJa = defaults?.object(forKey: "enableQwertyRomaji") == nil ? true : defaults!.bool(forKey: "enableQwertyRomaji")
        
        var sequence: [InputMode] = []
        if enableFlick { sequence.append(.flickKana) }
        if enableQwertyEn { sequence.append(.qwertyEnglish) }
        if enableQwertyJa { sequence.append(.qwertyRomaji) }
        if sequence.isEmpty { sequence = [.flickKana] }
        
        var nextMode = sequence[0]
        if let index = sequence.firstIndex(where: {
            if currentMode == .flickKana || currentMode == .flickAlphabet || currentMode == .flickNumber { return $0 == .flickKana }
            return $0 == currentMode
        }) {
            nextMode = sequence[(index + 1) % sequence.count]
        }
        
        currentMode = nextMode
        applyMode()
        UIDevice.current.playInputClick()
    }
    
    func flickKeyboardDidPressGlobe(_ keyboard: FlickKeyboardView) {
        lastFlickTapBaseChar = nil
        toggleMainMode()
    }
    
    func flickKeyboardDidPressDelete(_ keyboard: FlickKeyboardView) {
        lastFlickTapBaseChar = nil
        deletePressed()
    }
    
    func flickKeyboardDidFlickDeleteLeft(_ keyboard: FlickKeyboardView) {
        lastFlickTapBaseChar = nil
        UIDevice.current.playInputClick()
        
        if romajiConverter.hasPendingInput || !englishBuffer.isEmpty {
            _ = romajiConverter.commit()
            englishBuffer = ""
            textDocumentProxy.setMarkedText("", selectedRange: NSRange(location: 0, length: 0))
            updateConversionBar()
            return
        }
        
        if let context = textDocumentProxy.documentContextBeforeInput {
            let punctuations: Set<Character> = ["、", "。", "！", "？", ".", ",", "!", "?", " ", "\n"]
            var charsToDelete = 0
            var foundNonPunctuation = false
            for char in context.reversed() {
                if foundNonPunctuation && punctuations.contains(char) { break }
                if !punctuations.contains(char) { foundNonPunctuation = true }
                charsToDelete += 1
            }
            for _ in 0..<charsToDelete {
                textDocumentProxy.deleteBackward()
            }
        }
    }
    
    func flickKeyboardDidFlickDeleteUp(_ keyboard: FlickKeyboardView) {
        lastFlickTapBaseChar = nil
        UIDevice.current.playInputClick()
        
        if romajiConverter.hasPendingInput || !englishBuffer.isEmpty {
            _ = romajiConverter.commit()
            englishBuffer = ""
            textDocumentProxy.setMarkedText("", selectedRange: NSRange(location: 0, length: 0))
            updateConversionBar()
            return
        }
        
        if let context = textDocumentProxy.documentContextBeforeInput {
            var charsToDelete = 0
            for char in context.reversed() {
                if char == "\n" && charsToDelete > 0 { break }
                charsToDelete += 1
            }
            for _ in 0..<charsToDelete {
                textDocumentProxy.deleteBackward()
            }
        }
    }
    
    func flickKeyboardDidSwipeSpace(_ keyboard: FlickKeyboardView, direction: FlickKeyboardView.FlickDirection) {
        lastFlickTapBaseChar = nil
        if direction == .right {
            textDocumentProxy.adjustTextPosition(byCharacterOffset: 1)
            UIDevice.current.playInputClick()
        } else if direction == .left {
            textDocumentProxy.adjustTextPosition(byCharacterOffset: -1)
            UIDevice.current.playInputClick()
        }
    }
    
    func flickKeyboardDidBeginSpaceDrag(_ keyboard: FlickKeyboardView) {
        setKeyboardLabelsAlpha(0.0)
        UIDevice.current.playInputClick()
    }
    
    func flickKeyboardDidEndSpaceDrag(_ keyboard: FlickKeyboardView) {
        setKeyboardLabelsAlpha(1.0)
    }
    
    func flickKeyboardDidPressReturn(_ keyboard: FlickKeyboardView) {
        lastFlickTapBaseChar = nil
        returnPressed()
    }
    
    func flickKeyboardDidPressSpace(_ keyboard: FlickKeyboardView) {
        lastFlickTapBaseChar = nil
        spacePressed()
    }
    
    func flickKeyboardDidPressABC(_ keyboard: FlickKeyboardView) {
        lastFlickTapBaseChar = nil
        let defaults = AppGroupHelper.shared.userDefaults
        let flickAlphabetIsQwerty = defaults?.bool(forKey: "flickAlphabetIsQwerty") ?? false
        
        if flickAlphabetIsQwerty {
            currentMode = .qwertyEnglish
            applyMode()
        } else {
            if keyboard.currentPage == .alphabet {
                keyboard.switchToPage(.kana)
            } else {
                keyboard.switchToPage(.alphabet)
            }
        }
    }
    
    func flickKeyboardDidPressDakuten(_ keyboard: FlickKeyboardView) {
        lastFlickTapBaseChar = nil
        if keyboard.currentPage == .kana && romajiConverter.hasPendingInput {
            guard let lastChar = romajiConverter.displayText.last else { return }
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
                "わ": "ゎ", "ゎ": "わ", "ん": "ん" // ん is not modified
            ]
            
            if let newChar = map[charString] {
                romajiConverter.replaceLastKana(with: newChar)
                let display = romajiConverter.displayText
                textDocumentProxy.setMarkedText(display, selectedRange: NSRange(location: display.utf16.count, length: 0))
                updateConversionBar()
            }
            UIDevice.current.playInputClick()
            return
        }
        
        if keyboard.currentPage == .alphabet && !englishBuffer.isEmpty {
            guard let lastChar = englishBuffer.last else { return }
            if lastChar.isLowercase {
                englishBuffer.removeLast()
                englishBuffer.append(lastChar.uppercased())
                textDocumentProxy.setMarkedText(englishBuffer, selectedRange: NSRange(location: englishBuffer.utf16.count, length: 0))
                updateConversionBar()
            } else if lastChar.isUppercase {
                englishBuffer.removeLast()
                englishBuffer.append(lastChar.lowercased())
                textDocumentProxy.setMarkedText(englishBuffer, selectedRange: NSRange(location: englishBuffer.utf16.count, length: 0))
                updateConversionBar()
            }
            return
        }
        
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

class AppGroupHelper {
    static let shared = AppGroupHelper()
    
    private(set) var appGroupID: String = "group.com.simplekeys.app"
    private(set) var userDefaults: UserDefaults?
    
    private init() {
        if let group = resolveAppGroup() {
            self.appGroupID = group
        }
        self.userDefaults = UserDefaults(suiteName: self.appGroupID)
    }
    
    private func resolveAppGroup() -> String? {
        guard let path = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let string = String(data: data, encoding: .isoLatin1) else {
            return nil
        }
        
        if let startRange = string.range(of: "<?xml"),
           let endRange = string.range(of: "</plist>") {
            let plistString = String(string[startRange.lowerBound...endRange.upperBound])
            if let plistData = plistString.data(using: .utf8),
               let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any],
               let entitlements = plist["Entitlements"] as? [String: Any],
               let appGroups = entitlements["com.apple.security.application-groups"] as? [String],
               let firstGroup = appGroups.first {
                return firstGroup
            }
        }
        return nil
    }
    
    func containerURL() -> URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }
    
    func saveImage(_ image: UIImage, fileName: String) -> Bool {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return false }
        guard let url = containerURL()?.appendingPathComponent(fileName) else { return false }
        do {
            try data.write(to: url)
            return true
        } catch {
            print("Failed to save image: \(error)")
            return false
        }
    }
    
    func loadImage(fileName: String) -> UIImage? {
        guard let url = containerURL()?.appendingPathComponent(fileName) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    
    func removeImage(fileName: String) {
        guard let url = containerURL()?.appendingPathComponent(fileName) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - Theme Models
struct ThemeSettings: Codable {
    var backgroundImageFileName: String?
    var backgroundColorHex: String?
    var keyStyle: Int // 0: standard, 1: glass, 2: flat
    var keyColorHex: String?
    var textColorHex: String?
    
    static let sharedKey = "customThemeSettings"
}

// MARK: - Expanded Candidate View CollectionView
extension KeyboardViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return max(0, currentCandidates.count - expandedStartIndex)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CandidateCell", for: indexPath) as! CandidateCell
        let index = indexPath.item + expandedStartIndex
        if index < currentCandidates.count {
            cell.titleLabel.text = currentCandidates[index]
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        commitCandidate(at: indexPath.item + expandedStartIndex)
    }
}

class CandidateCell: UICollectionViewCell {
    let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor.systemGray5
        contentView.layer.cornerRadius = 8
        
        titleLabel.font = .systemFont(ofSize: 18)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
