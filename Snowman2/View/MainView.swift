//
//  MainView.swift
//  Snowman2
//
//  Created by 양희태 on 2/28/25.
//

import SwiftUI

struct MainView: View {
    // 현재 선택된 아이템들을 저장
    @State private var selectedItems: [String] = ["ButterflyHat", "BranchHands", "CoalEyes", "CarrotNose", "SimpleMouth"]
    
    // 속도와 걸음 수 데이터 (실제 앱에서는 이 데이터를 가져오는 로직이 필요)
    @State private var currentSpeed: Double = 3.5
    @State private var currentSteps: Int = 8000
    
    // 각 카테고리별 선택 가능한 아이템들
    let hatOptions = ["CowboyHat", "ButterflyHat"]
    let handOptions = ["BranchHands", "StickHands", "UmbrellaHands"]
    let eyeOptions = ["CoinEyes", "ButtonEyes", "CoalEyes", "FingerEyes", "GoldEyes", "StoneEyes"]
    let noseOptions = ["PencilNose", "PineconeNose", "RedPebbleNose", "TangerineNose", "WoodenNose", "CarrotNose"]
    let mouthOptions = ["StoneMouth", "StrawberryMouth", "SimpleMouth", "RibbonMouth", "BranchMouth"]
    let stomachOptions = ["MoonButtons"]
    
    var body: some View {
        NavigationView {
            VStack {
                // 눈사람 뷰 표시
                SnowmanView(currentSpeed: currentSpeed, currentSteps: currentSteps, visibleItems: selectedItems)
                    .frame(height: 300)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding()
                
                // 사용자 커스터마이징 옵션
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 모자 선택
                        categorySection(title: "모자", options: hatOptions, category: "Hat")
                        
                        // 손 선택
                        categorySection(title: "손", options: handOptions, category: "Hand")
                        
                        // 눈 선택
                        categorySection(title: "눈", options: eyeOptions, category: "Eye")
                        
                        // 코 선택
                        categorySection(title: "코", options: noseOptions, category: "Nose")
                        
                        // 입 선택
                        categorySection(title: "입", options: mouthOptions, category: "Mouth")
                        
                        // 배 선택
                        categorySection(title: "배", options: stomachOptions, category: "Stomach")
                    }
                    .padding()
                }
            }
            .navigationTitle("눈사람 꾸미기")
        }
    }
    
    // 각 카테고리별 선택 UI
    func categorySection(title: String, options: [String], category: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 5)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(options, id: \.self) { option in
                        itemButton(name: option, category: category)
                    }
                }
                .padding(.horizontal, 5)
            }
        }
    }
    
    // 각 아이템 선택 버튼
    func itemButton(name: String, category: String) -> some View {
        let isSelected = selectedItems.contains(name)
        
        return Button(action: {
            // 같은 카테고리의 다른 아이템 제거
            selectedItems.removeAll { item in
                let isSameCategory = options(for: category).contains(item)
                return isSameCategory
            }
            
            // 현재 선택한 아이템 추가
            selectedItems.append(name)
        }) {
            Text(displayName(for: name))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(isSelected ? .white : .black)
                .cornerRadius(8)
        }
    }
    
    // 카테고리별 옵션 반환
    func options(for category: String) -> [String] {
        switch category {
        case "Hat": return hatOptions
        case "Hand": return handOptions
        case "Eye": return eyeOptions
        case "Nose": return noseOptions
        case "Mouth": return mouthOptions
        case "Stomach": return stomachOptions
        default: return []
        }
    }
    
    // 아이템 이름을 보기 좋게 변환
    func displayName(for name: String) -> String {
        // "CowboyHat" -> "카우보이 모자" 같은 식으로 변환
        // 실제 앱에서는 더 자세한 매핑이 필요할 수 있음
        switch name {
        case "CowboyHat": return "카우보이 모자"
        case "ButterflyHat": return "나비 모자"
        case "BranchHands": return "나뭇가지 손"
        case "StickHands": return "막대기 손"
        case "UmbrellaHands": return "우산 손"
        case "CoalEyes": return "석탄 눈"
        case "ButtonEyes": return "단추 눈"
        case "CoinEyes": return "동전 눈"
        case "FingerEyes": return "손가락 눈"
        case "GoldEyes": return "금화 눈"
        case "StoneEyes": return "돌 눈"
        case "CarrotNose": return "당근 코"
        case "PencilNose": return "연필 코"
        case "PineconeNose": return "솔방울 코"
        case "RedPebbleNose": return "빨간 자갈 코"
        case "TangerineNose": return "귤 코"
        case "WoodenNose": return "나무 코"
        case "SimpleMouth": return "심플 입"
        case "StoneMouth": return "돌 입"
        case "StrawberryMouth": return "딸기 입"
        case "RibbonMouth": return "리본 입"
        case "BranchMouth": return "나뭇가지 입"
        case "MoonButtons": return "달 단추"
        default: return name
        }
    }
}

