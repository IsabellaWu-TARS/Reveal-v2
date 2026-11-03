//
//  CoachAnchors.swift
//  Reveal
//
//  Lets the first-run guide point at the real controls instead of a diagram.
//  Each home control publishes its bounds; the coach overlay reads them and
//  draws its ring and note next to the actual button, wherever the layout puts
//  it on this screen size.
//

import SwiftUI

enum CoachTarget: Hashable, CaseIterable {
    case read
    case calendar
    case share
    case notes
    case settings

    var icon: String {
        switch self {
        case .read:     return "book.fill"
        case .calendar: return "calendar"
        case .share:    return "square.and.arrow.up"
        case .notes:    return "note.text"
        case .settings: return "gearshape.fill"
        }
    }
}

struct CoachAnchorKey: PreferenceKey {
    static var defaultValue: [CoachTarget: Anchor<CGRect>] = [:]

    static func reduce(value: inout [CoachTarget: Anchor<CGRect>],
                       nextValue: () -> [CoachTarget: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    /// Publishes this view's bounds so the guide can point at it.
    func coachAnchor(_ target: CoachTarget) -> some View {
        anchorPreference(key: CoachAnchorKey.self, value: .bounds) { [target: $0] }
    }
}
