//
//  MainView.swift
//  Snowman2
//
//  Created by 양희태 on 2/28/25.
//

import SwiftUI
import RealmSwift

struct MainView: View {
    @ObservedResults(DailySteps.self) var dailySteps
    @StateObject private var stepManager = StepManager()
    @State private var showingNewItemAlert = false
    @State private var newItemName = ""
    
    var currentSteps: Int {
            dailySteps.last?.steps ?? 0
        }
    var currentSpeed: Double {
        dailySteps.last?.currentSpeed ?? 0
        }
    var snowmanName: String {
            dailySteps.last?.snowmanName ?? "스!노우맨"
        }
    
    var nowSpeed : Double {
        dailySteps.last?.currentSpeed ?? 0
    }
    
    var targetSteps : Int {
        dailySteps.last?.targetSteps ?? 0
    }
    
    var equip : [String] {
        Array(dailySteps.last?.equippedItems ?? List<String>())
    }
    
    
    var body: some View {
        GeometryReader { geometry in
            VStack{
                HStack{
                    WalkProgress(dailySteps: $dailySteps, stepManager: stepManager)
                }
                
                SnowmanView(
                    currentSpeed: currentSpeed,
                    currentSteps: currentSteps,
                    visibleItems: equip).frame(width: geometry.size.width, height: geometry.size.width )
                Spacer()
            }
            .onAppear{
                stepManager.itemManager.resetAllItemsQuantity()
            }
            .alert(isPresented: $showingNewItemAlert) {
                Alert(
                    title: Text("새 아이템 획득!"),
                    message: Text("\(newItemName)을(를) 획득했습니다!"),
                    dismissButton: .default(Text("확인"))
                )
            }
            .onReceive(stepManager.itemManager.$newItemAlert) { show in
                if show {
                    showingNewItemAlert = true
                    newItemName = stepManager.itemManager.newItemName
                    stepManager.itemManager.newItemAlert = false
                }
            }
        }
    }
}
