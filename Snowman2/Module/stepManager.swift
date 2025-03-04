//
//  stepCounter.swift
//  Snowman2
//
//  Created by 양희태 on 2/13/25.
//
import CoreMotion
import RealmSwift

class StepManager: ObservableObject {
    private let pedometer = CMPedometer()
    private let realm: Realm
    private var dailyStepsToken: NotificationToken? = nil  // Realm 관찰 토큰
    
    @Published var currentSteps: Int = 0
    @Published var targetSteps: Int = 0
    @Published var currentSpeed: Double = 0.0
    @Published var snowmanName: String = ""
    @Published var selectedItems: [String] = []
    var itemManager: ItemManager
    
    init() {
        // Realm 초기화 코드
        let config = Realm.Configuration(
            schemaVersion: 8,  // 증가된 버전
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    migration.enumerateObjects(ofType: DailySteps.className()) { oldObject, newObject in
                        newObject!["measurementStartTime"] = Date()
                    }
                }
                if oldSchemaVersion < 2 {
                    migration.enumerateObjects(ofType: DailySteps.className()) { oldObject, newObject in
                        newObject!["targetSteps"] = DailySteps.generateRandomTarget()
                        newObject!["daysSpent"] = 0
                    }
                }
                if oldSchemaVersion < 3 {
                    migration.enumerateObjects(ofType: DailySteps.className()) { oldObject, newObject in
                        newObject?["currentSpeed"] = 0.0
                    }
                }
                if oldSchemaVersion < 4 {
                    migration.enumerateObjects(ofType: DailySteps.className()) { oldObject, newObject in
                        let equippedItems = RealmSwift.List<String>()
                        newObject?["equippedItems"] = equippedItems
                    }
                }
                if oldSchemaVersion < 5 {
                    // 추가 마이그레이션이 필요한 경우
                }
                if oldSchemaVersion < 6 {
                    migration.deleteData(forType: "SnowmanRecord")
                }
                if oldSchemaVersion < 7 {
                    migration.enumerateObjects(ofType: DailySteps.className()) { oldObject, newObject in
                        newObject?["baseStepCount"] = 0  // 기존 데이터에 기본값 설정
                    }
                }
                if oldSchemaVersion < 8 {
                           migration.enumerateObjects(ofType: DailySteps.className()) { oldObject, newObject in
                               newObject?["nextTargetSteps"] = 0  // 기존 데이터에 기본값 설정
                           }
                       }
            }
        )
        
        self.realm = try! Realm(configuration: config)
        self.itemManager = ItemManager(realm: self.realm)
        
        // 시작 시 항상 DailySteps가 하나만 존재하도록 함
        ensureSingleDailySteps()
        
        // 초기 데이터 로드
        loadCurrentData()
        
        // Realm 변경사항 관찰 설정
        setupObservers()
    }
    
    // Realm 관찰자 설정
    private func setupObservers() {
        // DailySteps 관찰
        let dailySteps = realm.objects(DailySteps.self)
        dailyStepsToken = dailySteps.observe { [weak self] changes in
            guard let self = self else { return }
            
            switch changes {
            case .initial, .update:
                // DailySteps 데이터가 변경되면 Published 속성 업데이트
                if let currentDailySteps = dailySteps.first {
                    DispatchQueue.main.async {
                        self.currentSteps = currentDailySteps.steps
                        self.targetSteps = currentDailySteps.targetSteps
                        self.currentSpeed = currentDailySteps.currentSpeed
                        self.snowmanName = currentDailySteps.snowmanName
                        self.selectedItems = Array(currentDailySteps.equippedItems)
                        
                        // 명시적인 UI 업데이트 트리거
                        self.objectWillChange.send()
                    }
                }
            case .error(let error):
                print("Error observing DailySteps: \(error)")
            }
        }
    }
    
    deinit {
        // 관찰 토큰 해제
        dailyStepsToken?.invalidate()
    }
    
    // DailySteps가 항상 하나만 존재하도록 보장
    private func ensureSingleDailySteps() {
        let dailyStepsCount = realm.objects(DailySteps.self).count
        
        try? realm.write {
            // 기존 DailySteps가 없으면 생성
            if dailyStepsCount == 0 {
                let newDailySteps = DailySteps()
                realm.add(newDailySteps)
            }
            // 여러 개가 있으면 하나만 남기고 삭제
            else if dailyStepsCount > 1 {
                let allDailySteps = realm.objects(DailySteps.self).sorted(byKeyPath: "date", ascending: false)
                let newest = allDailySteps.first!
                
                for i in 1..<allDailySteps.count {
                    if i < allDailySteps.count { // 안전 검사 추가
                        realm.delete(allDailySteps[i])
                    }
                }
            }
        }
    }
    
    // 현재 데이터 로드
    private func loadCurrentData() {
        if let currentDailySteps = realm.objects(DailySteps.self).first {
            self.currentSteps = currentDailySteps.steps
            self.targetSteps = currentDailySteps.targetSteps
            self.currentSpeed = currentDailySteps.currentSpeed
            self.snowmanName = currentDailySteps.snowmanName
            self.selectedItems = Array(currentDailySteps.equippedItems)
        }
    }
    
    // StepManager에 추가
    func updateNextTargetSteps(to newTarget: Int) {
        
        print("새로운걸음수\(newTarget)")
        try? realm.write {
            if let currentDailySteps = realm.objects(DailySteps.self).first {
                currentDailySteps.nextTargetSteps = newTarget
                
                // UI 업데이트 트리거
                self.objectWillChange.send()
            }
        }
    }
    // 권한 요청
    func requestMotionPermission() {
        if CMMotionActivityManager.isActivityAvailable() {
            let activityManager = CMMotionActivityManager()
            let today = Date()
            
            // 명시적인 권한 요청
            activityManager.queryActivityStarting(from: today, to: today, to: .main) { _, error in
                // 쿼리 완료 후 활동 관리자 중지
                activityManager.stopActivityUpdates()
                
                if error != nil {
                    print("모션 활동 권한이 거부되었습니다.")
                } else {
                    print("모션 활동 권한이 허용되었습니다.")
                    // 권한이 부여된 후 걸음 수 측정 시작
                    DispatchQueue.main.async {
                        self.startCounting()
                    }
                }
            }
        }
        
        // 걸음 수계 권한 확인
        if CMPedometer.isStepCountingAvailable() {
            let pedometer = CMPedometer()
            let now = Date()
            let startOfDay = Calendar.current.startOfDay(for: now)
            
            // 걸음 수 쿼리를 통한 권한 요청
            pedometer.queryPedometerData(from: startOfDay, to: now) { data, error in
                if error != nil {
                    print("걸음 수계 권한이 거부되었습니다.")
                } else {
                    print("걸음 수계 권한이 허용되었습니다.")
                    // 권한이 부여된 후 걸음 수 측정 시작
                    DispatchQueue.main.async {
                        self.startCounting()
                    }
                }
            }
        } else {
            print("이 기기에서는 걸음 수 측정을 사용할 수 없습니다.")
        }
    }
    
    func calPace() {
        print(CMPedometer.isPaceAvailable())
    }
    
    // 걸음 수 측정 시작
    func startCounting() {
        // 권한 확인
        if CMPedometer.authorizationStatus() != .authorized {
            print("권한이 없습니다. 권한을 요청합니다.")
            requestMotionPermission()
            return
        }
        
        guard CMPedometer.isStepCountingAvailable() else {
            print("이 기기에서는 걸음 수 측정을 사용할 수 없습니다.")
            return
        }
        
        // 현재 DailySteps 객체가 있는지 확인
        if let currentDailySteps = realm.objects(DailySteps.self).first {
            // 경과 일수 업데이트
            updateDaysSpent()
            
            // 걸음 수 업데이트 시작
            startPedometerUpdates(from: currentDailySteps.measurementStartTime)
        } else {
            // DailySteps 객체가 없으면 새로 시작
            startNewCount()
        }
    }
    
    // 경과 일수 업데이트
    private func updateDaysSpent() {
        guard let currentDailySteps = realm.objects(DailySteps.self).first else {
            return
        }
        
        let calendar = Calendar.current
        let daysPassed = calendar.dateComponents([.day],
                                             from: currentDailySteps.measurementStartTime,
                                             to: Date()).day ?? 0
        
        try? realm.write {
            currentDailySteps.daysSpent = daysPassed
        }
    }
    
    // 새 눈사람 시작
    func startNewCount() {
        // 페도미터 중지
        pedometer.stopUpdates()
        
        let now = Date()
        
        // 정확한 현재 걸음 수를 쿼리 - 10초 전부터 현재까지의 데이터로 최근 걸음 수 정확히 파악
        let tenSecondsAgo = now.addingTimeInterval(-10)
        
        pedometer.queryPedometerData(from: tenSecondsAgo, to: now) { [weak self] data, error in
            guard let self = self else { return }
            
            // 현재 정확한 누적 걸음 수
            let currentTotalSteps = data != nil ? Int(truncating: data!.numberOfSteps) : 0
            print("새 눈사람 시작 - 현재 정확한 걸음 수: \(currentTotalSteps)")
            
            DispatchQueue.main.async {
                // 새 DailySteps 생성
                try? self.realm.write {
                    // 기존 DailySteps 모두 제거
                    let existingSteps = self.realm.objects(DailySteps.self)
                    if !existingSteps.isEmpty {
                        self.realm.delete(existingSteps)
                    }
                    
                    // 새 DailySteps 생성
                    let newDailySteps = DailySteps()
                    newDailySteps.steps = 0
                    newDailySteps.baseStepCount = currentTotalSteps
                    newDailySteps.measurementStartTime = now
                    self.realm.add(newDailySteps)
                }
                
                // 상태 업데이트
                self.loadCurrentData()
                
                // 걸음 수 업데이트 시작 - 현재 시간부터
                self.startPedometerUpdates(from: now)
            }
        }
    }
    
    func updateTargetSteps(to newTarget: Int) {
        try? realm.write {
            if let currentDailySteps = realm.objects(DailySteps.self).first {
                currentDailySteps.targetSteps = newTarget
                
                // Published 속성 업데이트
                self.targetSteps = newTarget
                
                // UI 업데이트 트리거
                self.objectWillChange.send()
            }
        }
    }
    
    // 걸음 수 업데이트 시작
    private func startPedometerUpdates(from startDate: Date) {
        print("측정 시작 시간: \(startDate)")
        
        guard let currentDailySteps = realm.objects(DailySteps.self).first else {
            print("현재 DailySteps 객체를 찾을 수 없습니다.")
            return
        }
        
        let baseStepCount = currentDailySteps.baseStepCount
        print("기준 걸음 수: \(baseStepCount)")
        
        pedometer.startUpdates(from: startDate) { [weak self] data, error in
            guard let self = self, let data = data else {
                print("걸음수 업데이트 에러: \(error?.localizedDescription ?? "")")
                return
            }
            
            DispatchQueue.main.async {
                // 건강 앱 누적 걸음 수에서 기준점을 빼서 현재 눈사람의 걸음 수 계산
                let totalSteps = Int(truncating: data.numberOfSteps)
                var newSteps = totalSteps - baseStepCount
                
                // 음수 방지 - 절대 음수가 되지 않도록
                if newSteps < 0 {
                    print("음수 걸음 수 감지: \(newSteps), 0으로 보정")
                    newSteps = 0
                }
                
                print("총 걸음 수: \(totalSteps), 기준점: \(baseStepCount), 현재 눈사람 걸음 수: \(newSteps)")
                
                if let pace = data.currentPace {
                    let speedKmh = 3600 / pace.doubleValue
                    self.updateSteps(newSteps, speed: speedKmh)
                    print("현재 속도: \(speedKmh) km/h")
                } else {
                    self.updateSteps(newSteps, speed: 0.0)
                    print("현재 정지 상태")
                }
            }
        }
    }
    
    // 걸음 수와 속도 업데이트
    private func updateSteps(_ newSteps: Int, speed: Double) {
        // Realm 업데이트
        try? realm.write {
            if let currentDailySteps = realm.objects(DailySteps.self).first {
                currentDailySteps.steps = newSteps
                currentDailySteps.currentSpeed = speed
            }
        }
        
        // 아이템 획득 확인
        itemManager.checkItemDrop(currentSteps: newSteps)
    }
    
    // 아이템 선택 업데이트
    func updateSelectedItems(_ items: [String]) {
        // 명시적인 객체 변경 알림
        self.objectWillChange.send()
        self.selectedItems = items
        
        // Realm 업데이트
        try? realm.write {
            if let currentDailySteps = realm.objects(DailySteps.self).first {
                // 기존 아이템 목록 비우기
                currentDailySteps.equippedItems.removeAll()
                
                // 새 아이템 목록 추가
                for item in items {
                    currentDailySteps.equippedItems.append(item)
                }
            }
        }
    }
    
    // 눈사람 완성 처리

    func completeSnowman() -> SnowmanRecord {
        
        let snowmanRecord = SnowmanRecord()
        // 현재 DailySteps 객체와 필요한 정보를 먼저 가져옴
        guard let currentDailySteps = realm.objects(DailySteps.self).first else {
            print("현재 DailySteps 객체를 찾을 수 없습니다.")
            
            return snowmanRecord
        }
        
        // 목표 달성 확인
        if currentDailySteps.steps < currentDailySteps.targetSteps {
            print("목표 걸음수를 달성해야 새로운 눈사람을 만들 수 있습니다!")
            return snowmanRecord
        }
        
        // 필요한 정보 복사
        let currentName = currentDailySteps.snowmanName
        let currentStepsCount = currentDailySteps.steps
        let currentTargetSteps = currentDailySteps.targetSteps
        let currentCreationDate = currentDailySteps.measurementStartTime
        let currentDaysSpent = currentDailySteps.daysSpent
        let currentSpeed = currentDailySteps.currentSpeed
        let itemsList = self.selectedItems
        
        // 다음 목표 걸음수 설정
        // nextTargetSteps가 0이면 현재 목표 걸음수를 사용
        let nextTarget = currentDailySteps.nextTargetSteps > 0 ?
                         currentDailySteps.nextTargetSteps :
                         currentDailySteps.targetSteps
        
        // 페도미터 업데이트 중지
        pedometer.stopUpdates()
        
        // SnowmanRecord 생성 (완성된 눈사람 저장)
        snowmanRecord.name = currentName
        snowmanRecord.steps = currentStepsCount
        snowmanRecord.targetSteps = currentTargetSteps
        snowmanRecord.creationDate = currentCreationDate
        snowmanRecord.completionDate = Date()
        snowmanRecord.daysSpent = currentDaysSpent
        snowmanRecord.averageSpeed = currentSpeed
        
        // Realm에 저장하고 아이템 사용 처리
        try? realm.write {
            // 선택된 아이템 저장
            for item in itemsList {
                snowmanRecord.usedItems.append(item)
                
                // 아이템 사용 (수량 감소)
                if let item = realm.objects(SnowmanItem.self).filter("name == %@", item).first, item.quantity > 0 {
                    item.quantity -= 1
                }
            }
            
            // 완성된 눈사람 저장
            realm.add(snowmanRecord)
            
            // 기존 DailySteps 삭제
            realm.delete(currentDailySteps)
        }
        
        // 저장된 nextTarget 값을 직접 전달하여 새 눈사람 시작
        print("다음 눈사람 시작 - 목표 걸음수: \(nextTarget)")
        startNewCountWithTargetSteps(nextTarget)
        
        return snowmanRecord
    }
    
    // 특정 목표 걸음수로 새 눈사람 시작하는 메서드 추가
    func startNewCountWithTargetSteps(_ targetSteps: Int) {
        // 페도미터 중지
        pedometer.stopUpdates()
        
        let now = Date()
        
        // 정확한 현재 걸음 수를 쿼리 - 10초 전부터 현재까지의 데이터로 최근 걸음 수 정확히 파악
        let tenSecondsAgo = now.addingTimeInterval(-10)
        
        pedometer.queryPedometerData(from: tenSecondsAgo, to: now) { [weak self] data, error in
            guard let self = self else { return }
            
            // 현재 정확한 누적 걸음 수
            let currentTotalSteps = data != nil ? Int(truncating: data!.numberOfSteps) : 0
            print("새 눈사람 시작 - 현재 정확한 걸음 수: \(currentTotalSteps)")
            print("설정된 목표 걸음수: \(targetSteps)")
            
            DispatchQueue.main.async {
                // 새 DailySteps 생성
                try? self.realm.write {
                    // 기존 DailySteps 모두 제거
                    let existingSteps = self.realm.objects(DailySteps.self)
                    if !existingSteps.isEmpty {
                        self.realm.delete(existingSteps)
                    }
                    
                    // 새 DailySteps 생성하고 즉시 목표 걸음수 설정
                    let newDailySteps = DailySteps()
                    // 중요: 이 부분을 먼저 실행해야 함
                    newDailySteps.targetSteps = targetSteps  // 랜덤값 대신 지정된 목표 걸음수 사용
                    newDailySteps.steps = 0
                    newDailySteps.baseStepCount = currentTotalSteps
                    newDailySteps.measurementStartTime = now
                    self.realm.add(newDailySteps)
                }
                
                // 상태 업데이트
                self.loadCurrentData()
                
                // 걸음 수 업데이트 시작 - 현재 시간부터
                self.startPedometerUpdates(from: now)
            }
        }
    }
}
