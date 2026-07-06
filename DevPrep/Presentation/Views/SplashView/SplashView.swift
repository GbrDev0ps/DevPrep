//
//  SplashView.swift
//  DevPrep
//
//  Created by Gabriel Monte Olivio Martins on 07/06/26.
//

import SwiftUI

struct SplashView: View {

    @State private var showHome = false
    @State private var scale: CGFloat = 1

    var body: some View {

        ZStack {

            HomeView()
                .opacity(showHome ? 1 : 0)

            if !showHome {

                ZStack {

                    Color.black
                        .ignoresSafeArea()

                    Image("logoDevPrep")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 600, height: 600)
                        .scaleEffect(scale)
                }
            }
        }
        .task {

            try? await Task.sleep(for: .seconds(1.5))

            withAnimation(.easeInOut(duration: 0.6)) {
                scale = 1.2
                showHome = true
            }
        }
    }
}
