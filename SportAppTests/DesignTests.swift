import XCTest
@testable import SportApp

final class AccentPaletteTests: XCTestCase {

    func testWhichAccentsCountAsDark() {
        let dark: [AccentID] = [.olive, .viola]
        let light: [AccentID] = [.lime, .mint, .ice, .pink]
        for id in dark {
            XCTAssertLessThan(RGB(hex: id.hex).luminance, AccentPalette.darkThreshold, id.displayName)
        }
        for id in light {
            XCTAssertGreaterThanOrEqual(RGB(hex: id.hex).luminance, AccentPalette.darkThreshold, id.displayName)
        }
    }

    func testLightAccentInDarkMode() {
        let p = AccentPalette.make(accent: .lime, isDarkMode: true)
        XCTAssertEqual(p.onAccent, RGB(hex: 0x0D0E10))
        XCTAssertEqual(p.accentText, RGB(hex: AccentID.lime.hex))
        XCTAssertEqual(p.accentLine, RGB(hex: AccentID.lime.hex))
        XCTAssertEqual(p.accentSoftAlpha, 0.18, accuracy: 0.0001)
    }

    func testLightAccentInLightModeGetsDarkerText() {
        let a = RGB(hex: AccentID.lime.hex)
        let p = AccentPalette.make(accent: .lime, isDarkMode: false)
        XCTAssertEqual(p.onAccent, RGB(hex: 0x121316))
        XCTAssertEqual(p.accentText, a.mixed(toward: .black, fraction: 0.55))
        XCTAssertEqual(p.accentLine, a.mixed(toward: .black, fraction: 0.30))
        XCTAssertEqual(p.accentSoftAlpha, 0.45, accuracy: 0.0001)
    }

    func testDarkAccentInDarkModeGetsLighterText() {
        let a = RGB(hex: AccentID.olive.hex)
        let p = AccentPalette.make(accent: .olive, isDarkMode: true)
        XCTAssertEqual(p.onAccent, .white)
        XCTAssertEqual(p.accentText, a.mixed(toward: .white, fraction: 0.55))
        XCTAssertEqual(p.accentLine, a.mixed(toward: .white, fraction: 0.35))
        XCTAssertEqual(p.accentSoftAlpha, 0.40, accuracy: 0.0001)
    }

    func testDarkAccentInLightMode() {
        let a = RGB(hex: AccentID.viola.hex)
        let p = AccentPalette.make(accent: .viola, isDarkMode: false)
        XCTAssertEqual(p.onAccent, .white)
        XCTAssertEqual(p.accentText, a)
        XCTAssertEqual(p.accentLine, a)
        XCTAssertEqual(p.accentSoftAlpha, 0.22, accuracy: 0.0001)
    }

    /// DESIGN.md 2.1: tekst op een accentvlak haalt altijd minstens 4,5 : 1.
    func testTextOnAccentHasEnoughContrast() {
        for id in AccentID.allCases {
            for dark in [true, false] {
                let p = AccentPalette.make(accent: id, isDarkMode: dark)
                XCTAssertGreaterThanOrEqual(p.onAccent.contrast(with: p.accent), 4.5,
                                            "\(id.displayName), \(dark ? "donker" : "licht")")
            }
        }
    }

    func testContrastReferenceValues() {
        XCTAssertEqual(RGB.white.contrast(with: .black), 21, accuracy: 0.001)
        XCTAssertEqual(RGB.white.contrast(with: .white), 1, accuracy: 0.001)
    }
}

final class FormatTests: XCTestCase {
    func testDutchNumberFormatting() {
        XCTAssertEqual(SAFormat.kilograms(7.5), "7,5 kg")
        XCTAssertEqual(SAFormat.kilograms(55), "55 kg")
        XCTAssertEqual(SAFormat.kilograms(48230), "48.230 kg")
    }

    func testClock() {
        XCTAssertEqual(SAFormat.clock(seconds: 84), "1:24")
        XCTAssertEqual(SAFormat.clock(seconds: 5), "0:05")
        XCTAssertEqual(SAFormat.clock(seconds: -3), "0:00")
    }
}

final class DesignTokenTests: XCTestCase {
    func testTextStylesFollowTheDesign() {
        XCTAssertEqual(SATextStyle.largeTitle.size, 34)
        XCTAssertEqual(SATextStyle.dockValue.size, 26)
        XCTAssertTrue(SATextStyle.dockValue.usesFixedDigitWidth)
        XCTAssertTrue(SATextStyle.sectionLabel.isUppercase)
        XCTAssertFalse(SATextStyle.body.usesFixedDigitWidth)
    }

    func testTouchTargetsAreAtLeast44() {
        XCTAssertGreaterThanOrEqual(Size.minTouch, 44)
        XCTAssertGreaterThanOrEqual(Size.chip, 44)
    }
}
