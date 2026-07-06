//
//  CategoryCard.swift
//  DevPrep
//
//  Created by Gabriel Monte Olivio Martins on 07/06/26.
//

import SwiftUI

struct CategoryCard: View {

    let category: Category

    var body: some View {

        RoundedRectangle(cornerRadius: 20)
            .fill(.blue.opacity(0.12))
            .frame(height: 120)
            .overlay {

                VStack(spacing: 12) {

                    Image(systemName: category.icon)
                        .font(.title)

                    Text(category.rawValue)
                        .fontWeight(.semibold)
                }
            }
    }
}

#Preview {
    CategoryCard(category: .swift)
        .padding()
}
