//
//  TutorialView.swift
//  Snowman2
//
//  Created by 양희태 on 3/18/25.
//

import SwiftUI

// MARK: 튜토리얼
struct TutorialStep {
    enum Position {
        case topLeft, topCenter, topRight
        case middleLeft, center, middleRight
        case bottomLeft, bottomCenter, bottomRight
    }
    
    
    let position: Position
    let text: String
    let highlightRect: CGRect // x, y, width, height는 0.0~1.0 사이의 비율값
}

struct TutorialOverlayView: View {
    @ObservedObject var tutorialManager: TutorialManager
    let geometryProxy: GeometryProxy
    
    var body: some View {
        ZStack {
            // 반투명 배경 (터치 가능)
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    tutorialManager.nextStep()
                }
            
            // 현재 단계 하이라이트 영역
            let step = tutorialManager.tutorialSteps[tutorialManager.currentStep]
            let highlightFrame = getHighlightFrame(for: step.highlightRect)
            
            // 하이라이트 영역 (터치 허용)
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white, lineWidth: 3)
                .frame(width: highlightFrame.width, height: highlightFrame.height)
                .position(x: highlightFrame.midX, y: highlightFrame.midY)
                .allowsHitTesting(false)
            
            // 텍스트와 화살표
            TutorialBubbleView(
                text: step.text
            )
            .frame(width: min(geometryProxy.size.width * 0.7, 300))
            .position(getPosition(for: step.position))
            .allowsHitTesting(false)
        }
    }
    
    // 하이라이트 프레임 계산
    private func getHighlightFrame(for rect: CGRect) -> CGRect {
        return CGRect(
            x: rect.origin.x * geometryProxy.size.width,
            y: rect.origin.y * geometryProxy.size.height,
            width: rect.width * geometryProxy.size.width,
            height: rect.height * geometryProxy.size.height
        )
    }
    
    // 위치 계산
    private func getPosition(for position: TutorialStep.Position) -> CGPoint {
        let width = geometryProxy.size.width
        let height = geometryProxy.size.height
        
        switch position {
        case .topLeft:
            return CGPoint(x: width * 0.25, y: height * 0.1)
        case .topCenter:
            return CGPoint(x: width * 0.5, y: height * 0.05)
        case .topRight:
            return CGPoint(x: width * 0.75, y: height * 0.1)
        case .middleLeft:
            return CGPoint(x: width * 0.25, y: height * 0.5)
        case .center:
            return CGPoint(x: width * 0.5, y: height * 0.45)
        case .middleRight:
            return CGPoint(x: width * 0.6, y: height * 0.45)
        case .bottomLeft:
            return CGPoint(x: width * 0.25, y: height * 0.7)
        case .bottomCenter:
            return CGPoint(x: width * 0.5, y: height * 0.7)
        case .bottomRight:
            return CGPoint(x: width * 0.75, y: height * 0.7)
        }
    }
}

// 말풍선 뷰
struct TutorialBubbleView: View {
    let text: String
    
    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .foregroundStyle(Color.black)
                .font(.system(size: 16, weight: .medium))
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            
        }
    }
}

// 화살표 모양
struct Arrow: Shape {
    enum Direction {
        case up, down, left, right
    }
    
    let direction: Direction
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        switch direction {
        case .up:
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        case .down:
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.closeSubpath()
        case .left:
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
        case .right:
            path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
        
        return path
    }
}
