//
//  CompletedSnowmanView.swift
//  Snowman2
//
//  Created by 양희태 on 3/1/25.
//
import SwiftUI
import RealmSwift

struct CompletedSnowmenView: View {
    @ObservedResults(SnowmanRecord.self) var snowmanRecords
    
    var body: some View {
        NavigationStack {
            if snowmanRecords.isEmpty {
                VStack {
                    Image(systemName: "snow")
                        .font(.system(size: 70))
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("아직 완성된 눈사람이 없습니다")
                        .font(.headline)
                    
                    Text("목표 걸음 수를 달성하여 눈사람을 완성해보세요!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .padding()
            } else {
                List {
                    ForEach(snowmanRecords.sorted(byKeyPath: "completionDate", ascending: false)) { record in
                        NavigationLink(destination: SnowmanDetailView(record: record)) {
                            SnowmanListItemView(record: record)
                        }
                    }
                }
                .navigationTitle("냉동실")
            }
        }
    }
}


// 5. 눈사람 목록 아이템 뷰
struct SnowmanListItemView: View {
    let record: SnowmanRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing:20) {
                // 눈사람 이미지를 ZStack으로 구현
                ZStack {
                    Image("snow")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100,height: 100)
                               // record.visible에 있는 각 아이템 이름을 이용해 이미지 표시
                               ForEach(record.usedItems, id: \.self) { itemName in
                                   Image(itemName)
                                       .resizable()
                                       .scaledToFit()
                                       .frame(width: 100 ,height: 100) // 적절한 크기로 조정
                               }
                           }
                .frame(width: 100,height: 100) // ZStack 전체 크기 조정
                VStack(alignment: .leading, spacing: 4){
                    Text(record.name)
                        .font(.headline)
                    Text(formatDate(record.completionDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("제작: \(record.daysSpent)일")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("걸음 수: \(record.steps) / \(record.targetSteps)")
                        .font(.subheadline)
                    
                    
                }
            }
        }
        .padding(.vertical, 5)
    }
    
    // 날짜 포맷팅 함수
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}


struct SnowmanDetailView: View {
    let record: SnowmanRecord
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                RefrigeratorView(snowmanRecord: record)
                                .frame(height: 300)
                                .background(Color.white)
                
                Text(record.name)
                                      .font(.largeTitle)
                                      .fontWeight(.bold)
                
                // 걸음 수 정보
                InfoCard(title: "걸음 수 정보") {
                    InfoRow(label: "달성 걸음 수", value: "\(record.steps)")
                    InfoRow(label: "목표 걸음 수", value: "\(record.targetSteps)")
                    InfoRow(label: "달성률", value: "\(Int((Double(record.steps) / Double(record.targetSteps)) * 100))%")
                }
                
                // 제작 기간 정보
                InfoCard(title: "제작 기간") {
                    InfoRow(label: "시작일", value: formatDate(record.creationDate))
                    InfoRow(label: "완성일", value: formatDate(record.completionDate))
                    InfoRow(label: "소요 일수", value: "\(record.daysSpent)일")
                }
            }
            .padding()
        }
        .navigationTitle("냉동보관중")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // 날짜 포맷팅 함수
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}

struct InfoCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// 8. 정보 행 컴포넌트
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 5)
    }
}
