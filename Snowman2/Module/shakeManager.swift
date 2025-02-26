//
//  shakeManager.swift
//  Snowman2
//
//  Created by 양희태 on 2/27/25.
//

import SwiftUI
import CoreMotion

// 흔들기 감지 및 관리를 위한 클래스
class ShakeManager: ObservableObject {
    // 가속도계 데이터를 얻기 위한 모션 매니저
    private let motionManager = CMMotionManager()
    
    // 흔들기 카운트 (변경 시 뷰 업데이트)
    @Published var shakeCount = 0
    
    // 현재 흔들리고 있는지 상태 (UI 효과용)
    @Published var isShaking = false
    
    // 마지막으로 흔들린 시간
    private var lastShakeTime: TimeInterval = 0
    
    // 흔들림 모니터링 시작
    func startMonitoring() {
        // 가속도계 사용 가능 여부 확인
        guard motionManager.isAccelerometerAvailable else {
            print("가속도계를 사용할 수 없습니다.")
            return
        }
        
        // 업데이트 간격 설정 (초 단위)
        motionManager.accelerometerUpdateInterval = 0.1
        
        // 가속도계 데이터 업데이트 시작
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let accelerometerData = data else { return }
            
            self.processAccelerometerData(accelerometerData)
        }
    }
    
    // 흔들림 모니터링 중지
    func stopMonitoring() {
        motionManager.stopAccelerometerUpdates()
    }
    
    // 가속도계 데이터 처리
    private func processAccelerometerData(_ data: CMAccelerometerData) {
        // 가속도 값 가져오기
        let acceleration = data.acceleration
        
        // 가속도의 합계 계산 (x, y, z 값의 제곱합의 제곱근)
        let totalAcceleration = sqrt(
            pow(acceleration.x, 2) +
            pow(acceleration.y, 2) +
            pow(acceleration.z, 2)
        )
        
        // 흔들림 감지 임계값 (이 값보다 크면 흔들림으로 간주) - 더 낮게 설정하여 민감도 증가
        let threshold: Double = 1.8
        
        // 현재 시간
        let currentTime = Date().timeIntervalSince1970
        
        // 흔들림 감지 쿨다운 (0.2초로 줄여서 더 자주 감지)
        let cooldown: TimeInterval = 0.2
        
        // 임계값을 초과하고 마지막 흔들림 이후 쿨다운 시간이 지났으면
        if totalAcceleration > threshold && (currentTime - lastShakeTime) > cooldown {
            // UI 스레드에서 작업 수행
            DispatchQueue.main.async {
                // 진동 발생
                self.generateHapticFeedback()
                
                // 흔들림 카운트 증가
                self.shakeCount += 1
                
                // 흔들림 상태 활성화
                self.isShaking = true
                
                // 0.5초 후 흔들림 상태 비활성화
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isShaking = false
                }
            }
            
            // 마지막 흔들림 시간 업데이트
            lastShakeTime = currentTime
        }
    }
    
    // 진동 피드백 생성 - 더 강한 진동과 이중 진동 패턴 추가
    private func generateHapticFeedback() {
        // 강한 진동 생성
        let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
        heavyGenerator.prepare()
        heavyGenerator.impactOccurred(intensity: 1.0)
        
        // 0.1초 후 두 번째 진동 (이중 진동 효과)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
            rigidGenerator.prepare()
            rigidGenerator.impactOccurred(intensity: 0.8)
        }
    }
    
    // 카운트 리셋
    func resetCount() {
        shakeCount = 0
        
        // 리셋 시 강한 3단계 진동 피드백
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.notificationOccurred(.success)
        
        // 연속적인 진동 패턴 생성
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
            mediumGenerator.impactOccurred(intensity: 1.0)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
                heavyGenerator.impactOccurred(intensity: 1.0)
            }
        }
    }
}
