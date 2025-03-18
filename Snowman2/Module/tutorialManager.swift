//
//  tutorialManager.swift
//  Snowman2
//
//  Created by 양희태 on 3/18/25.
//
import SwiftUI

class TutorialManager: ObservableObject {
    @Published var isShowingTutorial = false
    @Published var currentStep = 0
    
    // 튜토리얼 단계 정의
    let tutorialSteps: [TutorialStep] = [
        TutorialStep(
            position: .topCenter,
            text: "눈사람을 만들기 위해 걸어보세요!",
            highlightRect: CGRect(x: 0.25, y: 0.1, width: 0.5, height: 0.3)
        ),
        TutorialStep(
            position: .center,
            text: "현재 걸음수와 목표를 확인하세요",
            highlightRect: CGRect(x: 0.05, y: 0.5, width: 0.93, height: 0.28)
        ),
        TutorialStep(
            position: .middleRight,
            text: "목표를 달성하면 눈사람 완성 버튼이 활성화되고 새로운 눈사람을 만듭니다",
            highlightRect: CGRect(x: 0.71, y: 0.49, width: 0.22, height: 0.05)
        ),
        TutorialStep(
            position: .bottomCenter,
            text: "옷장에서 눈사람에게 아이템을 입힐 수 있어요",
            highlightRect: CGRect(x: 0.03, y: 0.79, width: 0.32, height: 0.12)
        ),
        TutorialStep(
            position: .bottomCenter,
            text: "새로운 눈사람의 목표 걸음수를 설정해보세요",
            highlightRect: CGRect(x: 0.34, y: 0.79, width: 0.32, height: 0.12)
        ),
        TutorialStep(
            position: .bottomCenter,
            text: "냉동실에서 완성된 눈사람들을 볼 수 있어요",
            highlightRect: CGRect(x: 0.66, y: 0.79, width: 0.32, height: 0.12)
        ),
        TutorialStep(
            position: .center,
            text: "이제 멋진 눈사람을 만들어볼까요?",
            highlightRect: CGRect(x: 0.3, y: 0.4, width: 0, height: 0)
        )
    ]
    
    func startTutorial() {
        currentStep = 0
        isShowingTutorial = true
    }
    
    func nextStep() {
        if currentStep < tutorialSteps.count - 1 {
            currentStep += 1
        } else {
            // 튜토리얼 종료
            isShowingTutorial = false
            
            // 튜토리얼 완료 상태 저장
            UserDefaults.standard.set(true, forKey: "tutorialCompleted")
        }
    }
    
    // 이미 완료된 튜토리얼인지 확인
    func shouldShowTutorial() -> Bool {
        return !UserDefaults.standard.bool(forKey: "tutorialCompleted")
    }
}
