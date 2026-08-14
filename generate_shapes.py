import sys

path = "KeyboardExtension/StringTransformExtensions.swift"
with open(path, "r") as f:
    content = f.read()

shapes_ext = """
import UIKit

extension UIBezierPath {
    static func star(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let rc = r * 0.4
        let pts = 5
        for i in 0..<(pts * 2) {
            let radius = i % 2 == 0 ? r : rc
            let angle = CGFloat(i) * .pi / CGFloat(pts) - .pi / 2
            let p = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
            if i == 0 { path.move(to: p) }
            else { path.addLine(to: p) }
        }
        path.close()
        return path
    }
    
    static func triangle(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.close()
        return path
    }
    
    static func pentagon(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        for i in 0..<5 {
            let angle = CGFloat(i) * 2 * .pi / 5 - .pi / 2
            let p = CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
            if i == 0 { path.move(to: p) }
            else { path.addLine(to: p) }
        }
        path.close()
        return path
    }
    
    static func hexagon(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        for i in 0..<6 {
            let angle = CGFloat(i) * 2 * .pi / 6 - .pi / 2
            let p = CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
            if i == 0 { path.move(to: p) }
            else { path.addLine(to: p) }
        }
        path.close()
        return path
    }
    
    static func speechBubble(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let r: CGFloat = 8
        let tailWidth: CGFloat = 12
        let tailHeight: CGFloat = 8
        let bubbleRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - tailHeight)
        
        path.move(to: CGPoint(x: bubbleRect.minX + r, y: bubbleRect.minY))
        path.addLine(to: CGPoint(x: bubbleRect.maxX - r, y: bubbleRect.minY))
        path.addArc(withCenter: CGPoint(x: bubbleRect.maxX - r, y: bubbleRect.minY + r), radius: r, startAngle: -CGFloat.pi/2, endAngle: 0, clockwise: true)
        path.addLine(to: CGPoint(x: bubbleRect.maxX, y: bubbleRect.maxY - r))
        path.addArc(withCenter: CGPoint(x: bubbleRect.maxX - r, y: bubbleRect.maxY - r), radius: r, startAngle: 0, endAngle: CGFloat.pi/2, clockwise: true)
        
        // Tail
        let tailX = bubbleRect.midX - tailWidth/2
        path.addLine(to: CGPoint(x: tailX + tailWidth, y: bubbleRect.maxY))
        path.addLine(to: CGPoint(x: tailX + tailWidth/2, y: bubbleRect.maxY + tailHeight))
        path.addLine(to: CGPoint(x: tailX, y: bubbleRect.maxY))
        
        path.addLine(to: CGPoint(x: bubbleRect.minX + r, y: bubbleRect.maxY))
        path.addArc(withCenter: CGPoint(x: bubbleRect.minX + r, y: bubbleRect.maxY - r), radius: r, startAngle: CGFloat.pi/2, endAngle: CGFloat.pi, clockwise: true)
        path.addLine(to: CGPoint(x: bubbleRect.minX, y: bubbleRect.minY + r))
        path.addArc(withCenter: CGPoint(x: bubbleRect.minX + r, y: bubbleRect.minY + r), radius: r, startAngle: CGFloat.pi, endAngle: -CGFloat.pi/2, clockwise: true)
        
        return path
    }
    
    static func customShape(type: Int, in rect: CGRect) -> UIBezierPath {
        switch type {
        case 3: return star(in: rect)
        case 4: return triangle(in: rect)
        case 5: return pentagon(in: rect)
        case 6: return hexagon(in: rect)
        case 7: return speechBubble(in: rect)
        default: return UIBezierPath(roundedRect: rect, cornerRadius: 8)
        }
    }
}
"""

if "extension UIBezierPath" not in content:
    content = content + "\n" + shapes_ext
    with open(path, "w") as f:
        f.write(content)
    print("Added UIBezierPath shapes.")
else:
    print("Shapes already exist.")
