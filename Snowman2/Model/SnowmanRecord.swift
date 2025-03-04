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
    @Persisted var completionDate: Date
    @Persisted var creationDate: Date
    @Persisted var steps: Int
    @Persisted var targetSteps: Int
    @Persisted var daysSpent: Int
    @Persisted var averageSpeed: Double // 추후 추가
    @Persisted var usedItems = List<String>()
    
    convenience init(from dailySteps: DailySteps, usedItems: [String]) {
        self.init()
        self.name = dailySteps.snowmanName
        self.completionDate = Date()
        self.creationDate = dailySteps.measurementStartTime
        self.steps = dailySteps.steps
        self.targetSteps = dailySteps.targetSteps
        self.daysSpent = dailySteps.daysSpent
        self.averageSpeed = dailySteps.currentSpeed
        self.usedItems.append(objectsIn: usedItems)
    }
}
