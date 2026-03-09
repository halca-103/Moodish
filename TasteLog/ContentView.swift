//
//  ContentView.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/04.
//



//
//import SwiftUI
//
//struct ContentView: View {
//    var body: some View {
//        TabView {
//            HomeView()
//                .tabItem {
//                    Label("ホーム", systemImage: "house")
//                }
//
//            Text("レシピ一覧（近日実装）")
//                .tabItem {
//                    Label("レシピ", systemImage: "books.vertical")
//                }
//
//            Text("マイページ（近日実装）")
//                .tabItem {
//                    Label("マイ", systemImage: "person.crop.circle")
//                }
//        }
//    }
//}


import SwiftUI

struct ContentView: View {
    @AppStorage("selectedTab") private var selectedTab = 0
    @AppStorage("recipeTabResetID") private var recipeTabResetID = 0

    init() {
        // タブバーを下部に固定・背景を白に
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tag(0)
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }

            RecipeListView()
                .id(recipeTabResetID)
                .tag(1)
                .tabItem {
                    Label("レシピ", systemImage: "books.vertical.fill")
                }

            MyPageView()
                .tag(2)
                .tabItem {
                    Label("マイ", systemImage: "person.crop.circle.fill")
                }
        }
        .tint(AppTheme.accent)
    }
}
