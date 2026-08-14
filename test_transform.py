def test_transform():
    # P = (-1, -1)
    x = -1
    y = -1
    
    # midX = 0, midY = 0
    # translationX: 0, y: 0
    # scaledBy: 25, 25
    # translatedBy: 35, 35
    
    # Let's see what Swift does:
    # var t = CGAffineTransform(translationX: tx, y: ty)
    # t = t.scaledBy(x: sx, y: sy)
    # t = t.translatedBy(x: tx2, y: ty2)
    # In Swift, CGAffineTransform translates, then scales in the local coordinate system!
    
    # Let's emulate CGAffineTransform math:
    # Matrix multiplication:
    # A * B means applying A first, then B.
    # In CGAffineTransform, `t.scaledBy(sx, sy)` means `t * Scale`.
    pass
