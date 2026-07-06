//
//  HomeActionCard.swift
//  DevPrep
//
//  Created by Gabriel Monte Olivio Martins on 07/06/26.
//

import SwiftUI

struct HomeActionCard: View {

    let icon: String
    let title: String

    var body: some View {

        HStack {

            Image(systemName: icon)
                .font(.title3)

            Text(title)
                .fontWeight(.semibold)

            Spacer()

            Image(systemName: "chevron.right")
        }
        .padding()
        .background(.gray.opacity(0.12))
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
    }
}

#Preview {
    HomeActionCard(
        icon: "star.fill",
        title: "Favoritos"
    )
    .padding()
}
