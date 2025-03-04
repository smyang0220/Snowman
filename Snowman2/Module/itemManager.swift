//
//  itemManager.swift
//  Snowman2
//
//  Created by 양희태 on 2/28/25.
//
import RealmSwift
import Foundation
import CoreMotion
import SwiftUI

// 아이템 관련 상수와 유틸리티 함수
class ItemConstants {
    static let itemDropRate: Double = 0.001 // 0.1%
    
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

// 아이템 관리 클래스
class ItemManager: ObservableObject {
    private var realm: Realm
    @Published var newItemAlert = false
    @Published var newItemName = ""
    private var lastStepCount = 0
    
    init(realm: Realm? = nil) {
        if let providedRealm = realm {
            self.realm = providedRealm
        } else {
            // 스키마 버전을 6으로 증가시키고 마이그레이션 로직 추가
            let config = Realm.Configuration(
                schemaVersion: 6, // 스키마 버전 증가
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
                        // 기존 마이그레이션 코드
                    }
                    
                    // 스키마 버전 6에 대한 마이그레이션 - SnowmanRecord 클래스 변경
                    if oldSchemaVersion < 6 {
                        migration.enumerateObjects(ofType: SnowmanRecord.className()) { oldObject, newObject in
                            // 'date' 속성 값을 새로운 'completionDate' 속성으로 이동
                            if let oldDate = oldObject?["date"] as? Date {
                                newObject?["completionDate"] = oldDate
                                // 'creationDate'에 임시로 같은 날짜 사용 (정확한 생성 날짜는 없으므로)
                                newObject?["creationDate"] = oldDate
                            } else {
                                // 날짜 정보가 없으면 현재 날짜 사용
                                newObject?["completionDate"] = Date()
                                newObject?["creationDate"] = Date()
                            }
                            
                            // 새로운 필드에 기본값 설정
                            newObject?["targetSteps"] = oldObject?["steps"] as? Int ?? 10000 // 목표를 현재 걸음수로 가정
                            newObject?["daysSpent"] = 1 // 기본적으로 1일로 설정
                            newObject?["averageSpeed"] = 0.0 // 기본 속도
                        }
                    }
                }
            )
            
            self.realm = try! Realm(configuration: config)
        }
        
        initializeItems()
    }
    
    // 모든 아이템 초기화 (앱 첫 실행 시)
    private func initializeItems() {
        // 이미 아이템이 존재하면 초기화하지 않음
        if realm.objects(SnowmanItem.self).count > 0 {
            return
        }
        
        // 모자 카테고리
        addInitialItem("CowboyHat", "카우보이 모자", "Hat", 10, "hat.cowboy")
        addInitialItem("ButterflyHat", "나비 모자", "Hat", 10, "butterfly")
        
        // 손 카테고리
        addInitialItem("BranchHands", "나뭇가지 손", "Hand", 10, "branch")
        addInitialItem("StickHands", "막대기 손", "Hand", 10, "stick")
        addInitialItem("UmbrellaHands", "우산 손", "Hand", 10, "umbrella")
        
        // 눈 카테고리
        addInitialItem("CoalEyes", "석탄 눈", "Eye", 10, "eye.fill")
        addInitialItem("ButtonEyes", "단추 눈", "Eye", 10, "circle.fill")
        addInitialItem("CoinEyes", "동전 눈", "Eye", 10, "circle")
        addInitialItem("FingerEyes", "손가락 눈", "Eye", 10, "hand.point.up.fill")
        addInitialItem("GoldEyes", "금화 눈", "Eye", 10, "dollarsign.circle")
        addInitialItem("StoneEyes", "돌 눈", "Eye", 10, "circle.dashed")
        
        // 코 카테고리
        addInitialItem("CarrotNose", "당근 코", "Nose", 10, "triangle.fill")
        addInitialItem("PencilNose", "연필 코", "Nose", 10, "pencil")
        addInitialItem("PineconeNose", "솔방울 코", "Nose", 10, "leaf.fill")
        addInitialItem("RedPebbleNose", "빨간 자갈 코", "Nose", 10, "circle.fill")
        addInitialItem("TangerineNose", "귤 코", "Nose", 10, "circle.fill")
        addInitialItem("WoodenNose", "나무 코", "Nose", 10, "square.fill")
        
        // 입 카테고리
        addInitialItem("SimpleMouth", "심플 입", "Mouth", 10, "mouth.fill")
        addInitialItem("StoneMouth", "돌 입", "Mouth", 10, "seal.fill")
        addInitialItem("StrawberryMouth", "딸기 입", "Mouth", 10, "heart.fill")
        addInitialItem("RibbonMouth", "리본 입", "Mouth", 10, "ribbon")
        addInitialItem("BranchMouth", "나뭇가지 입", "Mouth", 10, "line.horizontal.3")
        
        // 배 카테고리
        addInitialItem("MoonButtons", "달 단추", "Stomach", 10, "moon.fill")
    }

    private func addInitialItem(_ name: String, _ displayName: String, _ category: String, _ quantity: Int = 10, _ imageName: String) {
        let item = SnowmanItem(name: name, displayName: displayName, category: category, quantity: quantity, imageName: imageName)
        try? realm.write {
            realm.add(item)
        }
    }
    
    // 걸음 수에 따른 아이템 획득 확인
    func checkItemDrop(currentSteps: Int) {
        // 새로 증가한 걸음 수만큼 아이템 드롭 확률 계산
        let stepsDifference = currentSteps - lastStepCount
        
        if stepsDifference > 0 {
            for _ in 0..<stepsDifference {
                if Double.random(in: 0...1) <= ItemConstants.itemDropRate {
                    if let randomItemName = ItemConstants.getRandomItem() {
                        addItem(named: randomItemName)
                        
                        // UI 업데이트를 위한 발행
                        newItemName = getItemDisplayName(randomItemName)
                        newItemAlert = true
                    }
                }
            }
            
            lastStepCount = currentSteps
        }
    }
    
    // 아이템 이름으로 표시 이름 가져오기
    func getItemDisplayName(_ name: String) -> String {
        if let item = realm.objects(SnowmanItem.self).filter("name == %@", name).first {
            return item.displayName
        }
        return name
    }
    
    // 카테고리별 아이템 가져오기
    func getItems(for category: String) -> [SnowmanItem] {
        return Array(realm.objects(SnowmanItem.self).filter("category == %@", category))
    }
    
    // 모든 아이템 가져오기
    func getAllItems() -> [SnowmanItem] {
        return Array(realm.objects(SnowmanItem.self))
    }
    
    // 아이템 획득
    func addItem(named name: String, quantity: Int = 1) {
        try? realm.write {
            if let item = realm.objects(SnowmanItem.self).filter("name == %@", name).first {
                item.quantity += quantity
            }
        }
    }
    
    // 아이템 사용
    func useItem(named name: String) {
        try? realm.write {
            if let item = realm.objects(SnowmanItem.self).filter("name == %@", name).first, item.quantity > 0 {
                item.quantity -= 1
            }
        }
    }
    
    // 아이템 보유 수량 확인
    func getItemQuantity(named name: String) -> Int {
        if let item = realm.objects(SnowmanItem.self).filter("name == %@", name).first {
            return item.quantity
        }
        return 0
    }
    
    // 아이템 장착 상태 업데이트
    // ItemManager의 updateEquippedItems 메서드
    func updateEquippedItems(selectedItems: [String]) {
        try? realm.write {
            if let currentSteps = realm.objects(DailySteps.self).sorted(byKeyPath: "date", ascending: false).first {
                // 기존 아이템 목록 비우기
                currentSteps.equippedItems.removeAll()
                
                // 새 아이템 목록 추가
                for item in selectedItems {
                    currentSteps.equippedItems.append(item)
                }
                
                print("Realm에 저장된 아이템: \(Array(currentSteps.equippedItems))")
            }
        }
    }
       
       // 현재 장착 중인 아이템 가져오기
       func getEquippedItems() -> [String] {
           if let currentSteps = realm.objects(DailySteps.self).sorted(byKeyPath: "date", ascending: false).first {
               return Array(currentSteps.equippedItems)
           }
           return []
       }
       
       // 눈사람 완성 (선택된 아이템 사용)
    func completeSnowman(from dailySteps: DailySteps, selectedItems: [String]) {
            // 아이템 사용 (수량 감소)
            for itemName in selectedItems {
                useItem(named: itemName)
            }
            
            // 완성된 눈사람 저장
            let snowmanRecord = SnowmanRecord(from: dailySteps, usedItems: selectedItems)
            try? realm.write {
                realm.add(snowmanRecord)
                
                // 현재 DailySteps 초기화 (새 눈사람 시작)
                resetCurrentDailySteps()
            }
        }
    
    // 현재 DailySteps 초기화 및 새로 생성
        private func resetCurrentDailySteps() {
            try? realm.write {
                // 현재 DailySteps 삭제 (선택사항)
                if let currentSteps = realm.objects(DailySteps.self).first {
                    realm.delete(currentSteps)
                }
                
                // 새 DailySteps 생성
                let newDailySteps = DailySteps()
                realm.add(newDailySteps)
            }
        }
    
    // 모든 아이템 수량을 10개로 설정 (테스트용)
    func resetAllItemsQuantity() {
        try? realm.write {
            let allItems = realm.objects(SnowmanItem.self)
            for item in allItems {
                item.quantity = 10
            }
        }
    }
}

