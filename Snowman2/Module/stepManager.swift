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
    
    private var timer: Timer?
    @Published var currentSpeed: Double = 0
    @Published var currentSteps: Int = 0
    @Published var targetSteps: Int = 0
    @Published var snowmanName: String = ""
    @Published var selectedItems: [String] = []
    @Published var itemManager = ItemManager()
    
    init() {
           // Realm 마이그레이션 설정
           let config = Realm.Configuration(
               schemaVersion: 5,  // 스키마 버전 증가
               migrationBlock: { migration, oldSchemaVersion in
                   if oldSchemaVersion < 1 {
                       migration.enumerateObjects(ofType: DailySteps.className()) { oldObject, newObject in
                           newObject!["measurementStartTime"] = Date()
                       }
                   }
                   if oldSchemaVersion < 2 {
                       migration.enumerateObjects(ofType: DailySteps.className()) { oldObject, newObject in
                           // 새로운 필드들에 기본값 설정
                           newObject!["targetSteps"] = DailySteps.generateRandomTarget()
                           newObject!["daysSpent"] = 0
                       }
                   }
                   if oldSchemaVersion < 3 {
                       migration.enumerateObjects(ofType: DailySteps.className()) { oldObject, newObject in
                           newObject?["currentSpeed"] = 0.0  // 새로운 컬럼 추가
                       }
                   }
                   if oldSchemaVersion < 4 {
                       // 아이템 관련 모델 추가에 필요한 마이그레이션
                       migration.enumerateObjects(ofType: DailySteps.className()) { oldObject, newObject in
                           // 착용 아이템 목록 빈 배열로 초기화
                           newObject?["equippedItems"] = List<String>()
                       }
                   }
                   if oldSchemaVersion < 5 {
                       // 추가 마이그레이션이 필요한 경우
                   }
               }
           )
           
           Realm.Configuration.defaultConfiguration = config
           realm = try! Realm()
           
           // ItemManager에 realm 인스턴스 전달
           self.itemManager = ItemManager(realm: realm)
           
           // 초기 데이터 로드
           loadLatestData()
           loadEquippedItems()
           
           // 매일 daysSpent 업데이트
           updateDaysSpent()
       }
    
    // 최신 데이터 로드
    private func loadLatestData() {
        if let latestSteps = realm.objects(DailySteps.self).sorted(byKeyPath: "date", ascending: false).first {
            self.currentSteps = latestSteps.steps
            self.targetSteps = latestSteps.targetSteps
            self.currentSpeed = latestSteps.currentSpeed
            self.snowmanName = latestSteps.snowmanName
        }
    }
    
    // 장착된 아이템 로드
    private func loadEquippedItems() {
        self.selectedItems = itemManager.getEquippedItems()
    }
    
    func calPace(){
        print(CMPedometer.isPaceAvailable())
    }
    
    // OnAppear
    func startCounting() {
        if CMPedometer.authorizationStatus() != .authorized {
            print("권한이 없습니다.")
            return
        }
        
        guard CMPedometer.isStepCountingAvailable() else {
            print("Cant Check Steps")
            return
        }
        
        // 최신 데이터 로드
        loadLatestData()
        loadEquippedItems()
        
        // 가장 최근 기록의 측정 시작 시간부터 측정 재개
        if let latestSteps = realm.objects(DailySteps.self).sorted(byKeyPath: "date", ascending: false).first {
            startPedometerUpdates(from: latestSteps.measurementStartTime)
        } else {
            startNewCount()
        }
    }
    
    // 경과 일수 업데이트
    private func updateDaysSpent() {
        guard let latestSteps = realm.objects(DailySteps.self).sorted(byKeyPath: "date", ascending: false).first else {
            return
        }
        
        let calendar = Calendar.current
        let daysPassed = calendar.dateComponents([.day],
                                               from: latestSteps.measurementStartTime,
                                               to: Date()).day ?? 0
        
        try? realm.write {
            latestSteps.daysSpent = daysPassed
        }
    }
        
    func startNewCount() {
        // 목표 달성 체크
        if let currentSteps = realm.objects(DailySteps.self).sorted(byKeyPath: "date", ascending: false).first {
            if currentSteps.steps < currentSteps.targetSteps {
                print("목표 걸음수를 달성해야 새로운 눈사람을 만들 수 있습니다!")
                return
            }
        }
        
        pedometer.stopUpdates()
        
        try? realm.write {
            let newDailySteps = DailySteps()
            realm.add(newDailySteps)
        }
        
        // 새로운 눈사람 데이터 로드
        loadLatestData()
        self.selectedItems = [] // 새 눈사람은 아이템이 없음
        
        if let latestSteps = realm.objects(DailySteps.self).sorted(byKeyPath: "date", ascending: false).first {
            startPedometerUpdates(from: latestSteps.measurementStartTime)
        }
    }
    
    private func startPedometerUpdates(from startDate: Date) {
        print("측정 시작 시간: \(startDate)")

        pedometer.startUpdates(from: startDate) { [weak self] data, error in
            guard let self = self, let data = data else {
                print("걸음수 업데이트 에러: \(error?.localizedDescription ?? "")")
                return
            }

            DispatchQueue.main.async {
                let newSteps = Int(truncating: data.numberOfSteps)
                if let pace = data.currentPace {
                    let speedKmh = 3600 / pace.doubleValue  // km/h 변환
                    self.updateLatestSteps(newSteps, speed: speedKmh)
                }
                else {
                    // 걷지 않을 때는 속도를 0으로 설정
                    self.updateLatestSteps(newSteps, speed: 0.0)
                }
            }
        }
    }
    
    // 아이템 선택 업데이트
    func updateSelectedItems(_ items: [String]) {
        self.objectWillChange.send() // 명시적으로 변경 알림
        self.selectedItems = items
        itemManager.updateEquippedItems(selectedItems: items)
    }
    
    // 눈사람 완성 처리
    func completeSnowman() {
        itemManager.completeSnowman(
            name: self.snowmanName,
            steps: self.currentSteps,
            selectedItems: self.selectedItems
        )
        self.selectedItems = []
        startNewCount()
    }
    
    // 업데이트된 updateLatestSteps 함수
    private func updateLatestSteps(_ newSteps: Int, speed: Double) {
        try? realm.write {
            if let latestSteps = realm.objects(DailySteps.self).sorted(byKeyPath: "date", ascending: false).first {
                latestSteps.steps = newSteps
                latestSteps.currentSpeed = speed
                
                // Published 프로퍼티 업데이트
                self.currentSteps = newSteps
                self.currentSpeed = speed
            }
        }
        
        // 아이템 획득 확인
        itemManager.checkItemDrop(currentSteps: newSteps)
    }
}
