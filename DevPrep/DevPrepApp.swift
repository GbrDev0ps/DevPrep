//
//  DevPrepApp.swift
//  DevPrep
//
//  Created by Gabriel Monte Olivio Martins on 07/06/26.
//

import SwiftUI

@main
struct DevPrepApp: App {

    @State
    private var favoritesStore = FavoritesStore()

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environment(favoritesStore)
        }
    }
}
