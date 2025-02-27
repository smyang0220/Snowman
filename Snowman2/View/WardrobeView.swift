//
//  WardrobeView.swift
//  Snowman2
//
//  Created by 양희태 on 2/28/25.
//
import SwiftUI
import RealmSwift

struct SnowmanWardrobeView: View {
    @ObservedObject var itemManager = ItemManager()
    @ObservedResults(DailySteps.self) var dailySteps
    @State private var selectedItems: [String] = []
    @State private var selectedCategory = "Hat"
    @Environment(\.presentationMode) var presentationMode
    
    var todaySteps: Int {
        dailySteps.last?.steps ?? 0
    }
    
    var snowmanName: String {
        dailySteps.last?.snowmanName ?? "스!노우맨"
    }
    
    var nowSpeed: Double {
        dailySteps.last?.currentSpeed ?? 0
    }
    
    let categories = ["Hat", "Hand", "Eye", "Nose", "Mouth", "Stomach"]
    let categoryIcons = [
        "Hat": "hat",
        "Hand": "hand.raised",
        "Eye": "eye",
        "Nose": "nose",
        "Mouth": "mouth",
        "Stomach": "circle"
    ]
    
    var body: some View {
        VStack {
            // 카테고리 탭
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(categories, id: \.self) { category in
                        categoryTab(category)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 10)
            
            // 아이템 그리드
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 150))], spacing: 20) {
                    ForEach(itemManager.getItems(for: selectedCategory)) { item in
                        itemCell(item)
                    }
                }
                .padding()
            }
            
            // 완성 버튼
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("장식하기")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        selectedItems.isEmpty ? Color.gray : Color.blue
                    )
                    .cornerRadius(12)
            }
            .padding()
        }
        .navigationBarItems(trailing: Button("닫기") {
            presentationMode.wrappedValue.dismiss()
        })
        .onAppear {
            // 뷰가 나타날 때 현재 장착 중인 아이템 로드
            selectedItems = itemManager.getEquippedItems()
        }
    }
    
    // 카테고리 탭 UI
    private func categoryTab(_ category: String) -> some View {
        VStack {
            Image(systemName: categoryIcons[category] ?? "questionmark")
                .font(.system(size: 22))
            Text(categoryDisplayName(category))
                .font(.caption)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(selectedCategory == category ? Color.blue.opacity(0.2) : Color.clear)
        )
        .onTapGesture {
            selectedCategory = category
        }
    }
    
    // 아이템 셀 UI
    private func itemCell(_ item: SnowmanItem) -> some View {
        let isSelected = selectedItems.contains(item.name)
        let isAvailable = item.quantity > 0
        
        return VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.3) : Color.white)
                    .shadow(radius: 3)
                
                VStack {
                    Image(systemName: item.imageName)
                        .font(.system(size: 40))
                        .foregroundColor(isAvailable ? .primary : .gray)
                        .padding(.top, 10)
                    
                    Text(item.displayName)
                        .font(.caption)
                        .foregroundColor(isAvailable ? .primary : .gray)
                    
                    Text("수량: \(item.quantity)")
                        .font(.caption2)
                        .foregroundColor(isAvailable ? .blue : .gray)
                        .padding(.bottom, 5)
                }
            }
            .frame(height: 120)
            .opacity(isAvailable ? 1.0 : 0.5)
            .overlay(
                isSelected ?
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 2)
                    : nil
            )
        }
        .onTapGesture {
            if isAvailable {
                toggleItemSelection(item)
            }
        }
    }
    
    // 아이템 선택/해제
    private func toggleItemSelection(_ item: SnowmanItem) {
        // 같은 카테고리의 기존 선택 아이템 찾기
        if let existingItemIndex = selectedItems.firstIndex(where: { name in
            itemManager.getItems(for: item.category).contains(where: { $0.name == name })
        }) {
            // 같은 카테고리의 아이템이 이미 선택되어 있으면 제거
            selectedItems.remove(at: existingItemIndex)
        }
        
        // 현재 선택한 아이템이 이미 선택되어 있는지 확인
        if let index = selectedItems.firstIndex(of: item.name) {
            // 이미 선택되어 있으면 제거
            selectedItems.remove(at: index)
        } else {
            // 아니면 추가
            selectedItems.append(item.name)
        }
        
        // 선택 상태를 Realm에 저장
        itemManager.updateEquippedItems(selectedItems: selectedItems)
    }
    
    // 눈사람 완성 처리
    private func completeSnowman() {
        itemManager.completeSnowman(name: snowmanName, steps: todaySteps, selectedItems: selectedItems)
        selectedItems = []
        presentationMode.wrappedValue.dismiss()
    }
    
    
    // 카테고리 표시 이름
    private func categoryDisplayName(_ category: String) -> String {
        switch category {
        case "Hat": return "모자"
        case "Hand": return "손"
        case "Eye": return "눈"
        case "Nose": return "코"
        case "Mouth": return "입"
        case "Stomach": return "배"
        default: return category
        }
    }
}
