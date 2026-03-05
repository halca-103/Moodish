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
    init() {
        // タブバーを下部に固定・背景を白に
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }

            RecipeListView()
                .tabItem {
                    Label("レシピ", systemImage: "books.vertical.fill")
                }

            MyPageView()
                .tabItem {
                    Label("マイ", systemImage: "person.crop.circle.fill")
                }
        }
        .tint(.primary)
    }
}
