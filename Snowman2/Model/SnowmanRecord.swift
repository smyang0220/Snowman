//
//  SnowmanRecord.swift
//  Snowman2
//
//  Created by 양희태 on 2/28/25.
//
import RealmSwift
import Foundation

// 완성된 눈사람 모델
class SnowmanRecord: Object, ObjectKeyIdentifiable {
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
