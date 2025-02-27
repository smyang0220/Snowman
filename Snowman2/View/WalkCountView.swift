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
    private let stepCounter = StepManager()
    
    var todaySteps: Int {
            dailySteps.last?.steps ?? 0
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
        
    // ,.
    var body: some View {
//        ShakeCountView()
        VStack {
            Text(snowmanName)
            Text("현재 걸음수 \(todaySteps)")
            Text("현재 속도 \(nowSpeed)")
            Text("목표 걸은수 \(targetSteps)")
            
            
            // 빠른속도 27.5
            // 전속력. 10
            
            Button("완성하기") {
                stepCounter.startNewCount()  // 새로운 시작 함수 호출
            }
            .disabled(todaySteps < targetSteps)
            .padding()
            SnowmanView(currentSpeed: nowSpeed, currentSteps: todaySteps)
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
            stepCounter.calPace()
        }
        .padding()
    }
}
