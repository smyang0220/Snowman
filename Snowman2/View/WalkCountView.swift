//
//  ContentView.swift
//  Snowman2
//
//  Created by 양희태 on 2/13/25.
//

import SwiftUI
import RealmSwift

struct WalkCountView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedResults(DailySteps.self) var dailySteps
    @StateObject var stepManager : StepManager
    
        
    var body: some View {
                List {
                    ForEach(dailySteps.sorted(by: { $0.date > $1.date })) { step in
                        VStack(alignment: .leading) {
                            Text("이름: \(step.snowmanName)")
                            Text("걸음수: \(step.steps)")
                            Text("날짜: \(step.date.formatted())")
                            Text("측정시간 : \(step.measurementStartTime)")
                            Text("최고 가속도")
                            Text("만드는데 걸린 날짜 : \(step.daysSpent)")
                            Text("목표 걸음수 : \(step.targetSteps)")
                        }
                    }
                }
            }
    }
