import Foundation

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
            FlickKey(center: "、", left: "。", up: "？", right: "！", down: "…")
        ]
    ]

    static let alphabetKeys: [[FlickKey]] = [
        [
            FlickKey(center: "@#/", left: "@", up: "#", right: "/", down: "&"),
            FlickKey(center: "ABC", left: "A", up: "B", right: "C", down: nil),
            FlickKey(center: "DEF", left: "D", up: "E", right: "F", down: nil)
        ],
        [
            FlickKey(center: "GHI", left: "G", up: "H", right: "I", down: nil),
            FlickKey(center: "JKL", left: "J", up: "K", right: "L", down: nil),
            FlickKey(center: "MNO", left: "M", up: "N", right: "O", down: nil)
        ],
        [
            FlickKey(center: "PQRS", left: "P", up: "Q", right: "R", down: "S"),
            FlickKey(center: "TUV", left: "T", up: "U", right: "V", down: nil),
            FlickKey(center: "WXYZ", left: "W", up: "X", right: "Y", down: "Z")
        ],
        [
            FlickKey(center: "a/A", left: nil, up: nil, right: nil, down: nil),
            FlickKey(center: "’\"()", left: "’", up: "\"", right: "(", down: ")"),
            FlickKey(center: ".,?!", left: ".", up: ",", right: "?", down: "!")
        ]
    ]

    static let numberKeys: [[FlickKey]] = [
        [
            FlickKey(center: "1", left: nil, up: nil, right: nil, down: nil),
            FlickKey(center: "2", left: nil, up: nil, right: nil, down: nil),
            FlickKey(center: "3", left: nil, up: nil, right: nil, down: nil)
        ],
        [
            FlickKey(center: "4", left: nil, up: nil, right: nil, down: nil),
            FlickKey(center: "5", left: nil, up: nil, right: nil, down: nil),
            FlickKey(center: "6", left: nil, up: nil, right: nil, down: nil)
        ],
        [
            FlickKey(center: "7", left: nil, up: nil, right: nil, down: nil),
            FlickKey(center: "8", left: nil, up: nil, right: nil, down: nil),
            FlickKey(center: "9", left: nil, up: nil, right: nil, down: nil)
        ],
        [
            FlickKey(center: "+-*/", left: "+", up: "-", right: "*", down: "/"),
            FlickKey(center: "0", left: nil, up: nil, right: nil, down: nil),
            FlickKey(center: ".,", left: ".", up: ",", right: nil, down: nil)
        ]
    ]
}
