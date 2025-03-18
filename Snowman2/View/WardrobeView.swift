import SwiftUI
import RealmSwift

// MARK: 옷장
struct SnowmanWardrobeView: View {
    @ObservedObject var stepManager: StepManager
    @State private var selectedItems: [String] = []
    @State private var selectedCategory = "Hat"
    @Environment(\.presentationMode) var presentationMode
    
    var itemManager: ItemManager {
        return stepManager.itemManager
    }
    
    let categories = ["Hat", "Hand", "Eye", "Nose", "Mouth", "Stomach"]
    let categoryIcons = [
        "Hat": "hat.widebrim",
        "Hand": "hand.raised",
        "Eye": "eye",
        "Nose": "nose",
        "Mouth": "mouth",
        "Stomach": "circle"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 카테고리 탭
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories, id: \.self) { category in
                        categoryTab(category)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .background(Color.white)
            
            Divider()
            
            // 아이템 그리드
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 130))], spacing: 16) {
                    ForEach(itemManager.getItems(for: selectedCategory)) { item in
                        itemCell(item)
                    }
                }
                .padding()
            }
            .background(Color.white)
            
            // 하단 버튼 영역
            VStack(spacing: 0) {
                Divider()
                
                // 적용 버튼
                Button(action: {
                    stepManager.updateSelectedItems(selectedItems)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("장식하기")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedItems.isEmpty ? Color.gray : Color.blue
                        )
                        .cornerRadius(10)
                }
                .padding()
                .disabled(selectedItems.isEmpty)
            }
            .background(Color.white)
        }
        .background(Color.white)
        .navigationBarItems(trailing: Button("닫기") {
            presentationMode.wrappedValue.dismiss()
        })
        .onAppear {
            // 뷰가 나타날 때 현재 장착 중인 아이템 로드
            selectedItems = stepManager.selectedItems
        }
    }
    
    // 카테고리 탭 UI
    private func categoryTab(_ category: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: categoryIcons[category] ?? "questionmark")
                .font(.system(size: 20))
                .foregroundColor(selectedCategory == category ? .blue : .gray)
            
            Text(categoryDisplayName(category))
                .font(.caption)
                .fontWeight(selectedCategory == category ? .semibold : .regular)
                .foregroundColor(selectedCategory == category ? .blue : .black)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 15)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(selectedCategory == category ? Color.blue.opacity(0.1) : Color.clear)
        )
        .onTapGesture {
            selectedCategory = category
        }
    }
    
    // 아이템 셀 UI
    private func itemCell(_ item: SnowmanItem) -> some View {
        let isSelected = selectedItems.contains(item.name)
        let isAvailable = item.quantity > 0
        
        return VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                VStack(spacing: 8) {
                    Image(item.name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .padding(.top, 12)
                    
                    VStack(spacing: 2) {
                        Text(item.displayName)
                            .font(.footnote)
                            .foregroundColor(.black)
                            .lineLimit(1)
                        
                        Text("수량: \(item.quantity)")
                            .font(.caption)
                            .foregroundColor(isAvailable ? .blue : .gray)
                            .padding(.bottom, 8)
                    }
                }
            }
            .frame(height: 110)
            .opacity(isAvailable ? 1.0 : 0.6)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
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
        // 현재 선택한 아이템이 이미 선택되어 있는지 확인
        if let index = selectedItems.firstIndex(of: item.name) {
            // 이미 선택되어 있으면 제거 (한 번 더 누르면 선택 해제)
            selectedItems.remove(at: index)
        } else {
            // 같은 카테고리의 기존 선택 아이템 찾기
            if let existingItemIndex = selectedItems.firstIndex(where: { name in
                itemManager.getItems(for: item.category).contains(where: { $0.name == name })
            }) {
                // 같은 카테고리의 아이템이 이미 선택되어 있으면 제거
                selectedItems.remove(at: existingItemIndex)
            }
            
            // 선택한 아이템 추가
            selectedItems.append(item.name)
        }
        
        // 선택 상태를 저장
        itemManager.updateEquippedItems(selectedItems: selectedItems)
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
