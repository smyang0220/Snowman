//
//  ShakeCountView.swift
//  Snowman2
//
//  Created by 양희태 on 2/27/25.
//

import SwiftUI
import CoreMotion

struct ShakeCountView: View {
    // 상태 관리를 위한 ObservableObject
       @StateObject private var shakeManager = ShakeManager()
       
       var body: some View {
           VStack(spacing: 30) {
               Text("핸드폰을 흔들어보세요!")
                   .font(.title3)
                   .foregroundColor(shakeManager.isShaking ? .blue : .primary)
                   .animation(.easeInOut(duration: 0.5), value: shakeManager.isShaking)
               
               Spacer()
               
               // 흔들기 카운트 표시
               Text("\(shakeManager.shakeCount)")
                   .font(.system(size: 80, weight: .bold))
                   .foregroundColor(.primary)
                   .frame(width: 200, height: 100)
                   .contentTransition(.numericText())
               
               // 리셋 버튼
               Button("리셋") {
                   shakeManager.resetCount()
               }
               .font(.title3)
               .padding()
               .background(Color.blue.opacity(0.1))
               .cornerRadius(10)
               
               Spacer()
           }
           .padding()
           .frame(maxWidth: .infinity, maxHeight: .infinity)
           .background(Color(UIColor.systemBackground))
           .onAppear {
               shakeManager.startMonitoring()
           }
           .onDisappear {
               shakeManager.stopMonitoring()
           }
       }
   }

  
