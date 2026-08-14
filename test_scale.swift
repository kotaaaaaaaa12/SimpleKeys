import Foundation
import CoreGraphics

func scaleToFit(path: CGMutablePath, in rect: CGRect) -> CGMutablePath {
    let bounds = path.boundingBox
    let scaleX = rect.width / bounds.width
    let scaleY = rect.height / bounds.height
    let scaleTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)
    
    // Create scaled path
    let scaledPath = CGMutablePath()
    scaledPath.addPath(path, transform: scaleTransform)
    
    let newBounds = scaledPath.boundingBox
    let translation = CGAffineTransform(translationX: rect.midX - newBounds.midX, y: rect.midY - newBounds.midY)
    
    let finalPath = CGMutablePath()
    finalPath.addPath(scaledPath, transform: translation)
    return finalPath
}

let p = CGMutablePath()
p.move(to: CGPoint(x: -1, y: -1))
p.addLine(to: CGPoint(x: 1, y: 1))

let rect = CGRect(x: 10, y: 10, width: 50, height: 50)
let res = scaleToFit(path: p, in: rect)
print(res.boundingBox)
