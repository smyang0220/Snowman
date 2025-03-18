import SwiftUI
import RealmSwift

struct MainView: View {
    @StateObject private var stepManager = StepManager()
    @StateObject private var itemManager = ItemManager()
    @State private var showingNewItemAlert = false
    @State private var newItemName = ""
    @State private var navigateToCompletedSnowmen = false
    @State private var showingWardrobe = false
    @State private var rewardedItems: [(name: String, displayName: String)] = []

    // 눈사람 완성 팝업 관련 상태
    @State private var showingCompletionPopup = false
    
    // 목표 걸음수
    @State private var showingTargetPicker = false
    @State private var selectedTargetSteps = 1000 // 기본값 설정
    
    // 집중 모드 관련 상태
    @State private var isRunningModeEnabled = false
    @State private var unlockStartTime: Date? = nil
    @State private var progressValue: Double = 0
    @State private var unlockTimer: Timer? = nil
    @State private var cooldownActive = false
    
    private let requiredHoldTime: Double = 5.0
    private let timerInterval: Double = 0.05
    
    @State private var completedSnowmanRecord: SnowmanRecord?
    
    // 랜덤 걸음수 설정 함수
    private func setRandomSteps(range: ClosedRange<Int>) {
        // 범위 내 랜덤 값 생성 (100 단위로 반올림)
        let randomSteps = (Int.random(in: range) / 100) * 100
        print("랜덤 목표 걸음수: \(randomSteps)")
        
        // 목표 걸음수 업데이트
        stepManager.updateNextTargetSteps(to: randomSteps)
        
        // 시트 닫기
        showingTargetPicker = false
    }
    
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // 배경색 설정
                    Color(UIColor.white)
                        .ignoresSafeArea()
                    
                    // 메인 콘텐츠
                        VStack(spacing: 0) {
                            // 눈사람 뷰
                            SnowmanView(
                                currentSpeed: stepManager.currentSpeed,
                                currentSteps: stepManager.currentSteps,
                                visibleItems: stepManager.selectedItems)
                            .frame(width: geometry.size.width, height: geometry.size.width)
                            .background(Color.white)
                            
                            // 걸음수 정보 카드
                            VStack(spacing: 0) {
                                // 상단 헤더 섹션
                                HStack {
                                    Text("눈사람 운동량")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                    Spacer()
                                    
                                    // 완성 버튼
                                    Button(action: {
                                        // 눈사람 합치기 애니메이션과 함께 완성 처리
                                        completeSnowmanWithAnimation()
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "snow")
                                            Text("완성")
                                                .fontWeight(.semibold)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(stepManager.currentSteps >= stepManager.targetSteps ?
                                                    Color.blue : Color.gray.opacity(0.5))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                    }
                                    .disabled(stepManager.currentSteps < stepManager.targetSteps)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white
                                )
                                .cornerRadius(16, corners: [.topLeft, .topRight])
                                
                                // MARK: 운동 정보 컴포넌트
                                VStack(spacing: 16) {
                                    // 현재/목표 걸음수
                                    HStack(alignment: .bottom) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("현재 걸음수")
                                                .font(.footnote)
                                                .foregroundColor(.gray)
                                            
                                            Text("\(stepManager.currentSteps)")
                                                .font(.system(size: 32, weight: .bold))
                                                .foregroundColor(.black)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("목표")
                                                .font(.footnote)
                                                .foregroundColor(.gray)
                                            
                                            Text("\(stepManager.targetSteps)")
                                                .font(.title2)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    
                                    // 프로그레스 바
                                    ZStack(alignment: .leading) {
                                        // 배경
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 10)
                                            .cornerRadius(5)
                                        
                                        // 진행도
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: stepManager.targetSteps > 0
                                                   ? min(CGFloat(stepManager.currentSteps) / CGFloat(stepManager.targetSteps), 1.0) * max(0, geometry.size.width - 64)
                                                   : 0,
                                                   height: 10)
                                            .cornerRadius(5)
                                    }
                                    
                                    // 추가 정보 섹션
                                    HStack(spacing: 12) {
                                        // 현재 속도
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("현재 속도")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            
                                            HStack {
                                                Image(systemName: "figure.walk")
                                                    .foregroundColor(.blue)
                                                Text("\(String(format: "%.1f", stepManager.currentSpeed / 1000)) km/h")
                                                    .font(.subheadline)
                                                    .foregroundColor(.black)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(10)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(10)
                                        
                                        // 다음 목표
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("다음 목표")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            
                                            HStack {
                                                Image(systemName: "flag.fill")
                                                    .foregroundColor(.orange)
                                                
                                                if let nextTarget = getNextTargetSteps() {
                                                    Text("\(nextTarget) 걸음")
                                                        .font(.subheadline)
                                                        .foregroundColor(.black)
                                                } else {
                                                    Text("\(stepManager.targetSteps) 걸음")
                                                        .font(.subheadline)
                                                        .foregroundColor(.black)
                                                }
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(10)
                                        .background(Color.orange.opacity(0.1))
                                        .cornerRadius(10)
                                    }
                                }
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
                            }
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            .padding(.vertical).padding(.horizontal)
                            
                            // 액션 버튼 섹션
                            HStack(spacing: 12) {
                                // 옷장 버튼
                                ActionButton(
                                    title: "옷장",
                                    icon: "bag.fill",
                                    color: Color.brown,
                                    action: { showingWardrobe = true }
                                )
                                
                                // 다음 목표 걸음수 설정 버튼
                                ActionButton(
                                    title: "목표 설정",
                                    icon: "figure.walk.motion",
                                    color: Color.orange,
                                    action: { showingTargetPicker = true }
                                )
                                
                                // 완성된 눈사람 목록 버튼
                                ActionButton(
                                    title: "냉동실",
                                    icon: "refrigerator.fill",
                                    color: Color.blue,
                                    action: { navigateToCompletedSnowmen = true }
                                )
                            }
                            .padding(.horizontal)
                            
                            // 숨겨진 네비게이션 링크 (완성된 눈사람 목록으로)
                            NavigationLink(destination: CompletedSnowmenView(), isActive: $navigateToCompletedSnowmen) {
                                EmptyView()
                            }
                            
                            Spacer(minLength: 80)
                        }
                    
                    .blur(radius: isRunningModeEnabled ? 1.5 : 0)
                    .onAppear {
                        // onAppear에서 기본 selectedTargetSteps 값을 현재 목표로 설정
                        selectedTargetSteps = stepManager.targetSteps
                        
                        stepManager.requestMotionPermission()
                        stepManager.calPace()
                    }
                    .sheet(isPresented: $showingWardrobe) {
                        SnowmanWardrobeView(stepManager: stepManager)
                            .presentationDetents([.large, .height(480)])
                    }
                    .sheet(isPresented: $showingTargetPicker) {
                        VStack(spacing: 20) {
                                HStack(spacing: 12) {
                                    RangeButton(
                                        title: "편의점",
                                        subtitle: "100~1000걸음",
                                        range: 100...1000,
                                        icon: "storefront.fill",
                                        color: .green,
                                        onSelect: setRandomSteps
                                    )
                                    
                                    RangeButton(
                                        title: "공원",
                                        subtitle: "1000~5000걸음",
                                        range: 1000...5000,
                                        icon: "leaf.fill",
                                        color: .blue,
                                        onSelect: setRandomSteps
                                    )
                                    
                                    RangeButton(
                                        title: "시내",
                                        subtitle: "5000~10000걸음",
                                        range: 5000...10000,
                                        icon: "bus.fill",
                                        color: .orange,
                                        onSelect: setRandomSteps
                                    )
                                }
                            
                                HStack(spacing: 12) {
                                    RangeButton(
                                        title: "국내여행",
                                        subtitle: "10000~15000걸음",
                                        range: 10000...15000,
                                        icon: "car.fill",
                                        color: .red,
                                        onSelect: setRandomSteps
                                    )
                                    
                                    RangeButton(
                                        title: "해외여행",
                                        subtitle: "15000~30000걸음",
                                        range: 15000...30000,
                                        icon: "airplane.departure",
                                        color: .purple,
                                        onSelect: setRandomSteps
                                    )
                                    
                                    RangeButton(
                                        title: "스-노우맨",
                                        subtitle: "30000걸음 이상",
                                        range: 30000...100000,
                                        icon: "snowflake",
                                        color: .red,
                                        onSelect: setRandomSteps
                                    )
                                }
                        }
                        .padding()
                        .presentationDetents([.height(280)])
                    }
                    
                    // 눈사람 완성 팝업 오버레이
                    if showingCompletionPopup {
                        SnowmanCompletionPopup(
                            isShowing: $showingCompletionPopup,
                            showTargetPicker: $showingTargetPicker,
                            snowmanName: stepManager.snowmanName,
                            snowmanItems: completedSnowmanRecord?.usedItems.map { $0 } ?? [], rewardedItems: rewardedItems
                        )
                        .transition(.opacity)
                        .zIndex(100) // 운동 모드 오버레이보다 위에 표시
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
                                        .foregroundColor(.black)
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
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
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
                }
            }
        }
        
        
    }
    
    // 완성 버튼 클릭 시 호출되는 메서드
    func completeSnowmanWithAnimation() {
      
        // 팝업 표시
        withAnimation {
            showingCompletionPopup = true
        }
        
        // 2초 후에 실제 완성 처리 (프로그레스 바가 찰 때까지 대기)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // 눈사람 레코드 생성 및 완성 처리
            let snowmanRecord = stepManager.completeSnowman()
            let getItem = itemManager.rewardItemsForCompletedSnowman(steps: stepManager.currentSteps)
            
            // 레코드가 생성된 후 팝업 데이터 업데이트
            DispatchQueue.main.async {
                self.rewardedItems = getItem
                self.completedSnowmanRecord = snowmanRecord
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

// 액션 버튼 컴포넌트
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color(.darkGray))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: 눈사람 완성 팝업 뷰
struct SnowmanCompletionPopup: View {
    @Binding var isShowing: Bool
    @Binding var showTargetPicker: Bool
    @State private var animationProgress: Double = 0.0
    @State private var showCompletionView = false
    @State private var dotOffset: CGFloat = -50
    
    let snowmanName: String
    let snowmanItems: [String]
    let rewardedItems: [(name: String, displayName: String)] // 추가: 보상으로 얻은 아이템 목록
    let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // 배경 오버레이
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    if showCompletionView {
                        withAnimation {
                            isShowing = false
                        }
                    }
                }
            
            VStack(spacing: 20) {
                if !showCompletionView {
                    // 로딩 뷰 (기존 코드 유지)
                    VStack(spacing: 24) {
                        Text("눈사람 만드는중...")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ZStack(alignment: .leading) {
                            // 배경 프로그레스 바
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 240, height: 16)
                            
                            // 프로그레스 바
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 240 * CGFloat(animationProgress), height: 16)
                        }
                    }
                    .padding(24)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(16)
                    .onReceive(timer) { _ in
                        if animationProgress < 1.0 {
                            animationProgress += 0.01
                        } else {
                            timer.upstream.connect().cancel()
                            withAnimation {
                                showCompletionView = true
                            }
                        }
                    }
                } else {
                    // 완성된 눈사람 뷰
                    ScrollView {
                        VStack(spacing: 24) {
                            Text("눈사람 완성!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            // 눈사람 이미지와 아이템 (ZStack으로 겹쳐서 표시)
                            ZStack {
                                Image("snow")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                
                                // 아이템이 있는 경우에만 표시
                                if !snowmanItems.isEmpty {
                                    ForEach(snowmanItems, id: \.self) { itemName in
                                        Image(itemName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 100, height: 100)
                                    }
                                }
                            }
                            .frame(width: 100, height: 100)
                            
                            Text(snowmanName)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.top, 8)
                            
                            // 보상 아이템 섹션 추가
                            if !rewardedItems.isEmpty {
                                Divider()
                                    .background(Color.white.opacity(0.3))
                                    .padding(.vertical, 8)
                                
                                Text("획득한 아이템")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.bottom, 8)
                                
                                // 보상 아이템 그리드로 표시
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 16) {
                                    ForEach(rewardedItems, id: \.name) { item in
                                        VStack {
                                            Image(item.name)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 50, height: 50)
                                                .background(Color.white.opacity(0.1))
                                                .cornerRadius(8)
                                            
                                            Text(item.displayName)
                                                .font(.caption)
                                                .foregroundColor(.white)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                                .frame(width: 70)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // 닫기 버튼
                            Button(action: {
                                isShowing = false
                            }) {
                                Text("닫기")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.top, 4)
                        }
                        .padding(32)
                    }
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(16)
                    .transition(.opacity)
                    .frame(maxWidth: min(UIScreen.main.bounds.width - 40, 360))
                    .frame(maxHeight: min(UIScreen.main.bounds.height - 120, 600))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MainView 내부에 추가할 함수
extension MainView {
    // 다음 목표 걸음수 가져오기
    func getNextTargetSteps() -> Int? {
        guard let currentDailySteps = try? Realm().objects(DailySteps.self).first else {
            return nil
        }
        
        // 다음 목표 걸음수가 설정되어 있는지 확인
        return currentDailySteps.nextTargetSteps > 0 ? currentDailySteps.nextTargetSteps : nil
    }
}

// 특정 모서리만 둥글게 만드는 확장
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}


struct RangeButton: View {
    let title: String
    let subtitle: String
    let range: ClosedRange<Int>
    let icon: String
    let color: Color
    let onSelect: (ClosedRange<Int>) -> Void
    
    var body: some View {
        Button(action: {
            onSelect(range)
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
    }
}
