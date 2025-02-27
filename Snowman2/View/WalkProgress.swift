//
//  WalkProgress.swift
//  Snowman2
//
//  Created by 양희태 on 2/28/25.
//


import SwiftUI
import RealmSwift

struct WalkProgress: View {
    @ObservedResults(DailySteps.self) var dailySteps
    @StateObject var stepManager : StepManager
    @State private var showingWardrobe = false
    
    var todaySteps: Int {
            dailySteps.last?.steps ?? 0
        }
        
    var targetSteps : Int {
        dailySteps.last?.targetSteps ?? 0
    }
    
    var snowmanName: String {
            dailySteps.last?.snowmanName ?? "스!노우맨"
        }
    
    
    
    var body: some View {
//        ShakeCountView()
        VStack(spacing: 5) {
            VStack(alignment: .leading, spacing: 8) {
                Text("걸음수")
                    .font(.subheadline)
                    .foregroundColor(.black) // secondary 대신 black으로 변경
                
                Text("\(todaySteps) / \(targetSteps) 걸음")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 2)
                
                // 옷장 버튼
                Button(action: {
                    showingWardrobe = true
                }) {
                    VStack {
                        Image(systemName: "bag")
                        Text("옷장")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
                
                Button(action: {
                    stepManager.completeSnowman()
                })
                {
                    VStack {
                        Image(systemName: "snow")
                        Text("완성")
                    }
                    .padding()
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
                .disabled(todaySteps < targetSteps)
            }
            .onAppear {
                stepManager.startCounting()  // 일반 시작
                stepManager.calPace()
            }
            .sheet(isPresented: $showingWardrobe) {
                SnowmanWardrobeView()
                    .presentationDetents([.large, .height(480)])
            }
    }
}

