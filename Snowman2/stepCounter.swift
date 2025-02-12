//
//  stepCounter.swift
//  Snowman2
//
//  Created by 양희태 on 2/13/25.
//

import CoreMotion
import RealmSwift

class StepCounter: ObservableObject {
    private let pedometer = CMPedometer()
    private let realm: Realm
    
    init() {
        // Realm 마이그레이션 설정
        let config = Realm.Configuration(
            schemaVersion: 2,  // 스키마 버전 증가
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
            }
        )
        
        Realm.Configuration.defaultConfiguration = config
        realm = try! Realm()
        
        // 매일 daysSpent 업데이트
        updateDaysSpent()
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
        
        if let latestSteps = realm.objects(DailySteps.self).sorted(byKeyPath: "date", ascending: false).first {
            startPedometerUpdates(from: latestSteps.measurementStartTime)
        }
    }
    
    private func startPedometerUpdates(from startDate: Date) {
        print("측정 시작 시간: \(startDate)")
        
        pedometer.startUpdates(from: startDate) { [weak self] data, error in
            guard let self = self,
                  let data = data else {
                print("걸음수 업데이트 에러: \(error?.localizedDescription ?? "")")
                return
            }
            
            DispatchQueue.main.async {
                let newSteps = Int(truncating: data.numberOfSteps)
                self.updateLatestSteps(newSteps)
            }
        }
    }
    
    private func updateLatestSteps(_ newSteps: Int) {
        try? realm.write {
            if let latestSteps = realm.objects(DailySteps.self).sorted(byKeyPath: "date", ascending: false).first {
                latestSteps.steps = newSteps
            }
        }
    }
}
