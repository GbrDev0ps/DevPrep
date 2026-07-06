//
//  HomeView.swift
//  DevPrep
//
//  Created by Gabriel Monte Olivio Martins on 07/06/26.
//

import SwiftUI

struct HomeView: View {

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 24
                ) {

                    headerSection

                    categoriesSection

                    actionsSection
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

private extension HomeView {

    var headerSection: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text(AppStrings.Home.welcome)
                .font(.title3)
                .foregroundStyle(.secondary)

            Text(AppStrings.Home.title)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(AppStrings.Home.subtitle)
                .foregroundStyle(.secondary)
        }
    }

    var categoriesSection: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            Text(AppStrings.Home.categories)
                .font(.title2)
                .fontWeight(.semibold)

            LazyVGrid(
                columns: columns,
                spacing: 16
            ) {

                ForEach(Category.allCases, id: \.self) { category in

                    NavigationLink {
                        QuestionListView(category: category)
                    } label: {
                        CategoryCard(category: category)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    var actionsSection: some View {

        VStack(
            spacing: 16
        ) {

            NavigationLink {

                Text("Favoritos")

            } label: {

                HomeActionCard(
                    icon: "star.fill",
                    title: AppStrings.Home.favorites
                )
            }

            NavigationLink {

                Text("Simulados")

            } label: {

                HomeActionCard(
                    icon: "target",
                    title: AppStrings.Home.simulations
                )
            }
        }
    }
}

#Preview {
    HomeView()
}

