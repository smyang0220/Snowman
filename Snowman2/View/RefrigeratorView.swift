import SceneKit
import SwiftUI

// MARK: 3D 냉동실 ( 크기별로 냉동실, 이글루, 북극, 아파트 이렇게 해볼 예정 )
struct RefrigeratorView: UIViewRepresentable {
    var snowmanRecord: SnowmanRecord  // 표시할 눈사람 레코드
    
    // 간단한 Coordinator 클래스
    class Coordinator: NSObject {
        var view: SCNView?
        
        override init() {
            super.init()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    // 처음 생성할때
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        let scene = loadScene()
        scnView.scene = scene
        scnView.backgroundColor = .clear
        scnView.autoenablesDefaultLighting = false // 기본 조명 자동 활성화 비활성화
        
        // Coordinator에 뷰 참조 저장
        context.coordinator.view = scnView
        
        return scnView
    }
    
    // 상태값 변경될때
    func updateUIView(_ uiView: SCNView, context: Context) {
        guard let scene = uiView.scene else {
            print("씬 없음")
            return
        }
        
        // 아이템 표시
        let visibleItems = snowmanRecord.usedItems.map { $0 }
        print("RefrigeratorView 업데이트: \(visibleItems)")
        
        hideAllNodes(node: scene.rootNode)
        
        // camera와 light는 항상 표시
        showNodesWithNames(["camera", "omniLight", "areaLight", "areaLight2", "snow", "refrigerator"], rootNode: scene.rootNode)
        
        // SnowBody와 SnowHead 노드 표시
        if let snowBodyNode = scene.rootNode.childNode(withName: "SnowBody", recursively: false) {
            snowBodyNode.isHidden = false
            
            // SnowBody의 직계 자식 노드들(Hand, Hat, Stomach, Mouse, Nose, Eye 등) 표시
            for childNode in snowBodyNode.childNodes {
                childNode.isHidden = false
                
                // 각 자식 노드의 하위 노드들은 기본적으로 모두 숨김
                for grandChild in childNode.childNodes {
                    grandChild.isHidden = true
                }
                
                // visibleItems에 포함된 항목만 표시
                for itemName in visibleItems {
                    if let itemNode = childNode.childNode(withName: itemName, recursively: false) {
                        itemNode.isHidden = false
                        // 이 항목의 자식들도 모두 표시
                        showAllChildNodes(itemNode)
                    }
                }
            }
        }
        
        // 머리부분 보이게하기
        if let snowHeadNode = scene.rootNode.childNode(withName: "SnowHead", recursively: false) {
            snowHeadNode.isHidden = false
            
            // SnowHead의 직계 자식 노드들도 표시
            for childNode in snowHeadNode.childNodes {
                childNode.isHidden = false
                
                // 각 자식 노드의 하위 노드들은 기본적으로 모두 숨김
                for grandChild in childNode.childNodes {
                    grandChild.isHidden = true
                }
                
                // visibleItems에 포함된 항목만 표시
                for itemName in visibleItems {
                    if let itemNode = childNode.childNode(withName: itemName, recursively: false) {
                        itemNode.isHidden = false
                        // 이 항목의 자식들도 모두 표시
                        showAllChildNodes(itemNode)
                    }
                }
            }
        }
        
        // refrigerator 노드와 그 모든 자식들 표시
        if let refrigeratorNode = scene.rootNode.childNode(withName: "refrigerator", recursively: false) {
            refrigeratorNode.isHidden = false
            showAllChildNodes(refrigeratorNode)
        }
        
        // 눈사람 크기 설정 (걸음 수 기반)
        if let snowHeadNode = scene.rootNode.childNode(withName:"SnowHead", recursively: true) {
            // 크기 조절 코드는 그대로 유지
            let scale = 0.2 + (Double(snowmanRecord.steps) / 600)
            let scaleAction = SCNAction.scale(to: CGFloat(scale), duration: 0.3)
            
            // 눈사람이 커질수록 머리 위치가 올라가야함
            snowHeadNode.position = SCNVector3(0, -0.37 + (Double(snowmanRecord.steps) / 260), 0)
            snowHeadNode.runAction(scaleAction, forKey: "scaleAction")
        }
        
        if let snowBodyNode = scene.rootNode.childNode(withName:"SnowBody", recursively: true) {
            let scale = 0.3 + (Double(snowmanRecord.steps) / 400)
            let scaleAction = SCNAction.scale(to: CGFloat(scale), duration: 0.3)
            snowBodyNode.position = SCNVector3(0, -0.7, 0)
            snowBodyNode.runAction(scaleAction, forKey: "scaleAction")
        }
    }
    
    // 씬 설정
    private func loadScene() -> SCNScene {
        let scene = SCNScene(named: "Snow.scnassets/snow.scn") ?? SCNScene()
        scene.rootNode.name = "snow"
        
        // 카메라 설정
        let cameraNode = makeCamera2()
        scene.rootNode.addChildNode(cameraNode)
        
        // 냉장고 모델 추가
        let refrigeratorNode = addRefrigerator()
           scene.rootNode.addChildNode(refrigeratorNode)
        
        // 쉐이딩 설정
        updateMaterialsToPhysicallyBased(for: scene)
        
        
        let makeOmniLightNode = makeOmniLight()
        scene.rootNode.addChildNode(makeOmniLightNode)
        
        let makeBackOmniLightNode = makeBackOmniLight()
        scene.rootNode.addChildNode(makeBackOmniLightNode)
        
        return scene
    }
    
}
