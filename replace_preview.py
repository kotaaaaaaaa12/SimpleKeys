import re

file_path = "SimpleKeys/SimpleKeys/ViewController.swift"
with open(file_path, "r") as f:
    content = f.read()

start_str = "    private func buildGrid(isQwerty: Bool) {"
end_str = "    @objc private func nameChanged() {"

start_idx = content.find(start_str)
end_idx = content.find(end_str)

if start_idx == -1 or end_idx == -1:
    print("Could not find buildGrid")
    exit(1)

new_func = r"""    private func buildGrid(isQwerty: Bool) {
        previewGrid.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if isQwerty {
            previewGrid.axis = .vertical
            
            let row0 = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
            let row1 = ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
            let row2 = ["Z", "X", "C", "V", "B", "N", "M"]
            
            let r0Stack = UIStackView()
            r0Stack.axis = .horizontal; r0Stack.distribution = .fillEqually; r0Stack.spacing = 6
            for k in row0 { r0Stack.addArrangedSubview(createPreviewKey(k)) }
            
            let r1Stack = UIStackView()
            r1Stack.axis = .horizontal; r1Stack.distribution = .fillEqually; r1Stack.spacing = 6
            let r1SpacerL = UIView(); let r1SpacerR = UIView()
            r1Stack.addArrangedSubview(r1SpacerL)
            for k in row1 { r1Stack.addArrangedSubview(createPreviewKey(k)) }
            r1Stack.addArrangedSubview(r1SpacerR)
            
            let r2Stack = UIStackView()
            r2Stack.axis = .horizontal; r2Stack.distribution = .fillEqually; r2Stack.spacing = 6
            let shiftKey = createPreviewKey("⇧", isSpecial: true)
            r2Stack.addArrangedSubview(shiftKey)
            for k in row2 { r2Stack.addArrangedSubview(createPreviewKey(k)) }
            let delKey = createPreviewKey("⌫", isSpecial: true)
            r2Stack.addArrangedSubview(delKey)
            
            let r3Stack = UIStackView()
            r3Stack.axis = .horizontal; r3Stack.distribution = .fill; r3Stack.spacing = 6
            let numKey = createPreviewKey("123", isSpecial: true)
            let globeKey = createPreviewKey("🌐", isSpecial: true)
            let spaceKey = createPreviewKey("space")
            let returnKey = createPreviewKey("return", isSpecial: true)
            r3Stack.addArrangedSubview(numKey)
            r3Stack.addArrangedSubview(globeKey)
            r3Stack.addArrangedSubview(spaceKey)
            r3Stack.addArrangedSubview(returnKey)
            
            previewGrid.addArrangedSubview(r0Stack)
            previewGrid.addArrangedSubview(r1Stack)
            previewGrid.addArrangedSubview(r2Stack)
            previewGrid.addArrangedSubview(r3Stack)
            
            if let firstKey = r0Stack.arrangedSubviews.first {
                r1SpacerL.widthAnchor.constraint(equalTo: firstKey.widthAnchor, multiplier: 0.5).isActive = true
                r1SpacerR.widthAnchor.constraint(equalTo: firstKey.widthAnchor, multiplier: 0.5).isActive = true
                shiftKey.widthAnchor.constraint(equalTo: firstKey.widthAnchor, multiplier: 1.3).isActive = true
                delKey.widthAnchor.constraint(equalTo: firstKey.widthAnchor, multiplier: 1.3).isActive = true
                numKey.widthAnchor.constraint(equalTo: firstKey.widthAnchor, multiplier: 1.3).isActive = true
                globeKey.widthAnchor.constraint(equalTo: firstKey.widthAnchor, multiplier: 1.0).isActive = true
                returnKey.widthAnchor.constraint(equalTo: firstKey.widthAnchor, multiplier: 2.0).isActive = true
            }
            
        } else {
            previewGrid.axis = .horizontal
            
            let cols = [
                ["☆123", "ABC", "^_^", "🌐"],
                ["あ", "た", "ま", "小/濁"],
                ["か", "な", "や", "わ"],
                ["さ", "は", "ら", "、"]
            ]
            
            for (i, col) in cols.enumerated() {
                let colStack = UIStackView()
                colStack.axis = .vertical; colStack.distribution = .fillEqually; colStack.spacing = 8
                for k in col {
                    colStack.addArrangedSubview(createPreviewKey(k, isSpecial: i == 0 || (i == 1 && k == "小/濁")))
                }
                previewGrid.addArrangedSubview(colStack)
            }
            
            let rightCol = UIStackView()
            rightCol.axis = .vertical; rightCol.distribution = .fill; rightCol.spacing = 8
            let delKey = createPreviewKey("⌫", isSpecial: true)
            let spcKey = createPreviewKey("空白")
            let retKey = createPreviewKey("改行", isSpecial: true)
            rightCol.addArrangedSubview(delKey)
            rightCol.addArrangedSubview(spcKey)
            rightCol.addArrangedSubview(retKey)
            previewGrid.addArrangedSubview(rightCol)
            
            delKey.heightAnchor.constraint(equalTo: spcKey.heightAnchor).isActive = true
            retKey.heightAnchor.constraint(equalTo: spcKey.heightAnchor, multiplier: 2.0, constant: 8).isActive = true
        }
    }
    
    private func createPreviewKey(_ title: String, isSpecial: Bool = false) -> PreviewKeyView {
        let key = PreviewKeyView()
        key.isSpecial = isSpecial
        let label = UILabel()
        label.text = title
        label.textAlignment = .center
        label.font = .systemFont(ofSize: title.count > 1 ? 14 : 18)
        label.tag = 777
        label.translatesAutoresizingMaskIntoConstraints = false
        key.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: key.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: key.centerYAnchor)
        ])
        return key
    }
    
"""

new_content = content[:start_idx] + new_func + content[end_idx:]

with open(file_path, "w") as f:
    f.write(new_content)
