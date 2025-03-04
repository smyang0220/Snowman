import SwiftUI
import RealmSwift

struct MainView: View {
    @StateObject private var stepManager = StepManager()
    @State private var showingNewItemAlert = false
    @State private var newItemName = ""
    @State private var navigateToCompletedSnowmen = false
    @State private var showingWardrobe = false
       
    // 집중 모드 관련 상태
    @State private var isRunningModeEnabled = false
    @State private var unlockStartTime: Date? = nil
    @State private var progressValue: Double = 0
    @State private var unlockTimer: Timer? = nil
    @State private var cooldownActive = false
       
    private let requiredHoldTime: Double = 5.0
    private let timerInterval: Double = 0.05
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // 메인 콘텐츠
                    VStack {
                        SnowmanView(
                            currentSpeed: stepManager.currentSpeed,
                            currentSteps: stepManager.currentSteps,
                            visibleItems: stepManager.selectedItems)
                            .frame(width: geometry.size.width, height: geometry.size.width)
                        
                        // WalkProgress 내용 통합
                        VStack(spacing: 5) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("걸음수")
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                
                                Text("\(stepManager.currentSteps) / \(stepManager.targetSteps) 걸음")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.black)
                                
                                Text("현재 속도 \(String(format: "%.1f", stepManager.currentSpeed))")
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(radius: 2)
                            
                            HStack {
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
                                    // 목표를 1000 걸음으로 설정
                                    stepManager.updateTargetSteps(to: 10)
                                }) {
                                    Text("목표 걸음수 줄이기")
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.orange)
                                        .cornerRadius(10)
                                }
                                
                                // 완성된 눈사람 목록 버튼
                                Button(action: {
                                    navigateToCompletedSnowmen = true
                                }) {
                                    VStack {
                                        Image(systemName: "refrigerator.fill")
                                        Text("냉동실")
                                    }
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .padding()
                                
                                // 완성 버튼
                                Button(action: {
                                    stepManager.completeSnowman()
                                }) {
                                    VStack {
                                        Image(systemName: "snow")
                                        Text("완성")
                                    }
                                    .padding()
                                    .background(stepManager.currentSteps >= stepManager.targetSteps ? Color.blue : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .padding()
                                .disabled(stepManager.currentSteps < stepManager.targetSteps)
                            }
                        }.padding()
                        
                        // 숨겨진 네비게이션 링크 (완성된 눈사람 목록으로)
                        NavigationLink(destination: CompletedSnowmenView(), isActive: $navigateToCompletedSnowmen) {
                            EmptyView()
                        }
                        
                        Spacer()
                    }
                    .blur(radius: isRunningModeEnabled ? 1.5 : 0)
                    .onAppear {
                        stepManager.requestMotionPermission()
                        stepManager.calPace()
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
                    .sheet(isPresented: $showingWardrobe) {
                        SnowmanWardrobeView(stepManager: stepManager)
                            .presentationDetents([.large, .height(480)])
                    }
                    
                    // 운동 모드 오버레이 (터치 차단)
                    if isRunningModeEnabled {
                        Color.black.opacity(0.01) // 거의 투명하지만 터치 이벤트는 가로챔
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                            .onTapGesture {} // 빈 탭 제스처로 다른 버튼 터치 방지
                    }
                    
                    // 항상 접근 가능한 운동 모드 버튼
                    VStack {
                        HStack{
                            Spacer()
                            VStack{
                                if isRunningModeEnabled {
                                    Text("잠금 해제")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14, weight: .bold))
                                        .padding(.bottom, 4)
                                    
                                    // 진행 표시기
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 10)
                                            .frame(width: 50, height: 8)
                                            .foregroundColor(.gray.opacity(0.5))
                                        
                                        RoundedRectangle(cornerRadius: 10)
                                            .frame(width: 50 * CGFloat(progressValue), height: 8)
                                            .foregroundColor(.green)
                                    }
                                    .padding(.bottom, 10)
                                }
                                Button(action: {
                                    if !isRunningModeEnabled && !cooldownActive {
                                        // 운동 모드 활성화
                                        isRunningModeEnabled = true
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 60, height: 60)
                                            .shadow(radius: 3)
                                        
                                        Image(systemName: isRunningModeEnabled ? "lock.open.fill" : "figure.run")
                                            .font(.system(size: 22))
                                            .foregroundColor(.white)
                                    }
                                }
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in
                                            if isRunningModeEnabled {
                                                if unlockStartTime == nil {
                                                    // 처음 버튼 누를 때 타이머 시작
                                                    unlockStartTime = Date()
                                                    
                                                    // 정확한 타이머 시작
                                                    startUnlockTimer()
                                                }
                                            }
                                        }
                                        .onEnded { _ in
                                            // 타이머 정지
                                            stopUnlockTimer()
                                            
                                            // 진행 상태 리셋
                                            progressValue = 0
                                            unlockStartTime = nil
                                        }
                                )
                                .padding(.bottom, 30)
                            }
                        }.padding(10)
                        
                        Spacer()
                    }
                }.background(Color.white)
            }
        }
    }
    
    // 타이머 시작 메서드
    private func startUnlockTimer() {
        // 기존 타이머 중지
        stopUnlockTimer()
        
        // 새 타이머 시작
        unlockTimer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { _ in
            guard let startTime = unlockStartTime else { return }
            
            // 경과 시간 계산 (0.0 ~ 1.0 사이의 값)
            let elapsedTime = Date().timeIntervalSince(startTime)
            let newProgress = min(elapsedTime / requiredHoldTime, 1.0)
            
            // 진행 상태 업데이트
            withAnimation {
                progressValue = newProgress
            }
            
            // 완료 시 잠금 해제
            if newProgress >= 1.0 {
                unlockFocusMode()
            }
        }
    }
    
    // 타이머 중지 메서드
    private func stopUnlockTimer() {
        unlockTimer?.invalidate()
        unlockTimer = nil
    }
    
    // 잠금 해제 메서드
    private func unlockFocusMode() {
        // 타이머 중지
        stopUnlockTimer()
        
        // 잠금 해제
        isRunningModeEnabled = false
        progressValue = 0
        unlockStartTime = nil
        
        // 쿨다운 활성화 (해제 후 즉시 다시 잠금이 걸리는 것 방지)
        cooldownActive = true
        
        // 1초 후 쿨다운 해제
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            cooldownActive = false
        }
    }
}
