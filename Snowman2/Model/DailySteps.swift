//
//  StepCount.swift
//  Snowman2
//
//  Created by 양희태 on 2/13/25.
//

import RealmSwift
import Foundation

class DailySteps : Object,ObjectKeyIdentifiable {
   
    @Persisted(primaryKey: true) private var _id: String = ""
        @Persisted var date: Date
        @Persisted var steps: Int = 0
        @Persisted var snowmanName: String
        @Persisted var measurementStartTime: Date
        @Persisted var targetSteps: Int  // 목표 걸음 수
        @Persisted var daysSpent: Int = 0  // 만드는데 걸린 날짜
        @Persisted var currentSpeed: Double = 0.0  // 현재 속도 저장
        @Persisted var equippedItems = List<String>() // 현재 착용 중인 아이템 이름 목록
        @Persisted var baseStepCount: Int = 0  // 눈사람 시작 시점의 기준 걸음 수
        override init() {
            super.init()
            self.date = Calendar.current.startOfDay(for: Date())
            self.snowmanName = DailySteps.generateSnowmanName()
            self._id = self.snowmanName
            self.measurementStartTime = Date()
            self.targetSteps = Self.generateRandomTarget()  // 랜덤 목표 설정
        }
        
    // 랜덤 목표 걸음 수 생성 (5000~15000)
    static func generateRandomTarget() -> Int {
            return Int.random(in: 50...100)
        }
    
    
    
    static func generateSnowmanName() -> String {
            let adjectives = ["행복한", "졸린", "신나는", "배고픈", "따뜻한", "차가운", "귀여운", "용감한", "웃긴", "현명한"]
            let names = ["눈송이", "눈뭉치", "눈사람", "눈덩이", "눈알", "눈별", "눈꽃", "눈표범", "눈토끼", "눈나비"]
            
            let randomAdjective = adjectives.randomElement() ?? "행복한"
            let randomName = names.randomElement() ?? "눈사람"
            
            return "\(randomAdjective) \(randomName)"
        }
}
