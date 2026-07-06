//
//  Category.swift
//  DevPrep
//
//  Created by Gabriel Monte Olivio Martins on 07/06/26.
//

enum Category: String, Codable, CaseIterable {
    case swift = "Swift"
    case uikit = "UIKit"
    case swiftUI = "SwiftUI"
    case architecture = "Architecture"
    case behavioral = "Behavioral"
}

extension Category {

    var icon: String {
        switch self {
        case .swift:
            return "swift"

        case .uikit:
            return "iphone"

        case .swiftUI:
            return "square.stack.3d.up"

        case .architecture:
            return "building.columns"

        case .behavioral:
            return "person.2"
        }
    }
}
