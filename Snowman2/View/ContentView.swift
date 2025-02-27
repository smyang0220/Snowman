//
//  ContentView.swift
//  Snowman2
//
//  Created by 양희태 on 2/28/25.
//

import SwiftUI
import CoreMotion

struct ContentView: View {
    var body: some View {
        TabView {
            MainView()
            .tabItem {
                Label("홈", systemImage: "house.fill")
            }
            
            WalkCountView()
                .tabItem {
                    Label("냉장고", systemImage: "refrigerator")
                }
        }
    }
}
