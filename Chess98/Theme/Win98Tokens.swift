import SwiftUI

enum Win98 {
    enum Palette {
        // Classic Windows 98 system colors
        static let face         = Color(red: 0xC0/255.0, green: 0xC0/255.0, blue: 0xC0/255.0) // window/button face
        static let desktop      = Color(red: 0x00/255.0, green: 0x80/255.0, blue: 0x80/255.0) // teal desktop
        static let titleBar     = Color(red: 0x00/255.0, green: 0x00/255.0, blue: 0x80/255.0) // active title bar blue
        static let titleBarText = Color.white
        static let highlight    = Color.white                                                  // outer top/left bevel
        static let light        = Color(red: 0xDF/255.0, green: 0xDF/255.0, blue: 0xDF/255.0) // inner top/left bevel
        static let shadow       = Color(red: 0x80/255.0, green: 0x80/255.0, blue: 0x80/255.0) // inner bottom/right bevel
        static let darkShadow   = Color.black                                                  // outer bottom/right bevel
        static let text         = Color.black
        static let selection    = Color(red: 0x00/255.0, green: 0x00/255.0, blue: 0x80/255.0) // selected text bg

        // Board colors — leaning into the chunky Microsoft Entertainment Pack feel
        static let lightSquare  = Color(red: 0xEF/255.0, green: 0xE0/255.0, blue: 0xC0/255.0)
        static let darkSquare   = Color(red: 0x82/255.0, green: 0x58/255.0, blue: 0x37/255.0)
    }

    enum Metrics {
        static let titleBarHeight: CGFloat = 18
        static let windowPadding: CGFloat = 4
    }
}
