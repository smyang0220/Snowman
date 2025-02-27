//
//  SnowmanItem.swift
//  Snowman2
//
//  Created by 양희태 on 2/28/25.
//

import RealmSwift
import Foundation

// 아이템 모델
class SnowmanItem: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var name: String         // 노드 이름 (예: "ButterflyHat")
    @Persisted var displayName: String  // 표시 이름 (예: "나비 모자")
    @Persisted var category: String     // 카테고리 (예: "Hat")
    @Persisted var quantity: Int = 0    // 보유 수량
    @Persisted var imageName: String    // 아이템 이미지 이름
    @Persisted var dateAcquired: Date   // 획득 날짜
    
    convenience init(name: String, displayName: String, category: String, quantity: Int = 0, imageName: String) {
        self.init()
        self.name = name
        self.displayName = displayName
        self.category = category
        self.quantity = quantity
        self.imageName = imageName
        self.dateAcquired = Date()
    }
}

// 완성된 눈사람 모델
class CompletedSnowman: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var name: String
    @Persisted var date: Date
    @Persisted var steps: Int
    @Persisted var usedItems = List<String>() // 사용된 아이템 이름 목록
    
    convenience init(name: String, steps: Int, usedItems: [String]) {
        self.init()
        self.name = name
        self.date = Date()
        self.steps = steps
        self.usedItems.append(objectsIn: usedItems)
    }
}

// DailySteps 모델에 아이템 관련 필드 추가
extension DailySteps {
    // 각 걸음 마다 아이템 획득 확률
    static let itemDropRate: Double = 0.001 // 0.1%
    
    // 아이템 랜덤 획득
    static func getRandomItem() -> String? {
        let allItems = [
            // 모자
            "CowboyHat", "ButterflyHat",
            // 손
            "BranchHands", "StickHands", "UmbrellaHands",
            // 눈
            "CoalEyes", "ButtonEyes", "CoinEyes", "FingerEyes", "GoldEyes", "StoneEyes",
            // 코
            "CarrotNose", "PencilNose", "PineconeNose", "RedPebbleNose", "TangerineNose", "WoodenNose",
            // 입
            "SimpleMouth", "StoneMouth", "StrawberryMouth", "RibbonMouth", "BranchMouth",
            // 배
            "MoonButtons"
        ]
        
        return allItems.randomElement()
    }
}
