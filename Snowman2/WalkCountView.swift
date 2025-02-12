//
//  ContentView.swift
//  Snowman2
//
//  Created by 양희태 on 2/13/25.
//

import SwiftUI
import RealmSwift

struct WalkCountView: View {
    @ObservedResults(DailySteps.self) var dailySteps
    private let stepCounter = StepCounter()
    
    var todaySteps: Int {
            dailySteps.last?.steps ?? 0
        }
        
    var snowmanName: String {
            dailySteps.last?.snowmanName ?? "스!노우맨"
        }
        
    
    var body: some View {
        VStack {
            Text(snowmanName)
            Text("현재 걸음수 \(todaySteps)")
            
            Button("새로운 시작") {
                stepCounter.startNewCount()  // 새로운 시작 함수 호출
            }
            .foregroundColor(.blue)
            .padding()
            
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
        .onAppear {
            stepCounter.startCounting()  // 일반 시작
        }
        .padding()
    }
}
