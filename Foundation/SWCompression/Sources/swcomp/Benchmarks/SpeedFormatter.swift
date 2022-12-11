// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

struct SpeedFormatter {
    static let `default`: SpeedFormatter = .init()

    enum Units {
        case bytes
        case kB
        case MB
        case GB
        case TB

        init(_ speed: Double) {
            if speed > 1_000_000_000_000 {
                self = .TB
            } else if speed > 1_000_000_000 {
                self = .GB
            } else if speed > 1_000_000 {
                self = .MB
            } else if speed > 1000 {
                self = .kB
            } else {
                self = .bytes
            }
        }

        fileprivate func unitsString() -> String {
            switch self {
            case .bytes:
                return "B/s"
            case .kB:
                return "kB/s"
            case .MB:
                return "MB/s"
            case .GB:
                return "GB/s"
            case .TB:
                return "TB/s"
            }
        }
    }

    var units: Units?
    var hideUnits: Bool
    var fractionDigits: Int

    init() {
        units = nil
        hideUnits = false
        fractionDigits = 3
    }

    func string(from speed: Double, units: Units? = nil, hideUnits: Bool? = nil, fractionDigits: Int? = nil) -> String {
        let actualUnits = units ?? self.units ?? Units(speed)
        let speedInUnits: Double
        switch actualUnits {
        case .bytes:
            speedInUnits = speed
        case .kB:
            speedInUnits = speed / 1000
        case .MB:
            speedInUnits = speed / 1_000_000
        case .GB:
            speedInUnits = speed / 1_000_000_000
        case .TB:
            speedInUnits = speed / 1_000_000_000_000
        }

        var formatString = "%.\(fractionDigits ?? self.fractionDigits)f"
        if !(hideUnits ?? self.hideUnits) {
            formatString += " " + actualUnits.unitsString()
        }
        return String(format: formatString, speedInUnits)
    }
}
