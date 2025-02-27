import SceneKit
import SwiftUI

struct SnowmanView: UIViewRepresentable {
    var currentSpeed: Double
    var currentSteps: Int
    var visibleItems: [String] = []
    
    // Coordinator 클래스를 추가하여 타이머와 내부 속도를 관리
    class Coordinator: NSObject {
        var timer: Timer?
        var internalSpeed: Double = 0
        var view: SCNView?
        var currentSpeed : Double
        
        init(currentSpeed : Double) {
            self.currentSpeed = currentSpeed
            super.init()
            
//            // 5초마다 속도를 5씩 증가시키는 타이머 설정
//            timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
//                guard let self = self else { return }
//                // 속도 증가
//                self.internalSpeed += 5.0
//                print("속도 자동 증가: \(self.internalSpeed)")
//                
//                // 현재 씬 뷰가 있으면 회전 업데이트
                if let scnView = self.view, let scene = scnView.scene {
                    self.updateRotation(in: scene)
                }
//            }
        }
        
        func updateRotation(in scene: SCNScene) {
            print("updateRotation(in:) 호출됨 \(currentSpeed)") // 디버깅 메시지
          
            if let snowNode = scene.rootNode.childNode(withName:"SnowBody", recursively: true) {
                // 속도에 비례하는 회전 속도 설정
                let snowRotationSpeed = Float(currentSpeed * -0.0005)
                
                // 회전 액션 키
                let snowRotationActionKey = "snowRotationAction"
                
                // currentSpeed가 0이면 회전 멈춤
                if currentSpeed == 0 {
                    snowNode.removeAction(forKey: snowRotationActionKey) // 회전 액션 제거
                    print("눈 회전 멈춤")
                } else if snowRotationSpeed < 0 {
                    // 새로운 회전 동작 생성
                    let rotateAction = SCNAction.rotateBy(x: CGFloat(snowRotationSpeed), y: 0, z: 0, duration: 1)
                    let repeatAction = SCNAction.repeatForever(rotateAction)
                    
                    // 기존 액션이 있으면 부드럽게 전환
                    if snowNode.action(forKey: snowRotationActionKey) != nil {
                        SCNTransaction.begin()
                        SCNTransaction.animationDuration = 0.3
                        snowNode.removeAction(forKey: snowRotationActionKey)
                        snowNode.runAction(repeatAction, forKey: snowRotationActionKey)
                        SCNTransaction.commit()
                    } else {
                        snowNode.runAction(repeatAction, forKey: snowRotationActionKey)
                    }
                }
                print("눈 현재스피드 \(snowRotationSpeed)")
            }

            
            if let mapNode = scene.rootNode.childNode(withName:"map", recursively: true) {
                // 속도에 비례하는 회전 속도 설정
                let mapRotationSpeed = Float(currentSpeed * 0.0001)
                
                // 회전 액션 키
                let mapRotationActionKey = "mapRotationAction"
                
                // currentSpeed가 0이면 회전 멈춤
                if currentSpeed == 0 {
                    mapNode.removeAction(forKey: mapRotationActionKey) // 회전 액션 제거
                    print("맵 회전 멈춤")
                } else if mapRotationSpeed > 0 {
                    // 새로운 회전 동작 생성
                    let rotateAction = SCNAction.rotateBy(x: 0, y: CGFloat(mapRotationSpeed), z: 0, duration: 1)
                    let repeatAction = SCNAction.repeatForever(rotateAction)
                    
                    // 기존 액션이 있으면 부드럽게 전환
                    if mapNode.action(forKey: mapRotationActionKey) != nil {
                        SCNTransaction.begin()
                        SCNTransaction.animationDuration = 0.3
                        mapNode.removeAction(forKey: mapRotationActionKey)
                        mapNode.runAction(repeatAction, forKey: mapRotationActionKey)
                        SCNTransaction.commit()
                    } else {
                        mapNode.runAction(repeatAction, forKey: mapRotationActionKey)
                    }
                }
                print("맵 현재스피드 \(mapRotationSpeed)")
            }
            
        }
        
        deinit {
            // 뷰가 해제될 때 타이머도 해제
            timer?.invalidate()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(currentSpeed: currentSpeed)
    }
    
    // 처음 생성할때
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        let scene = loadScene()
        scnView.scene = scene
        scnView.backgroundColor = .clear
//        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = false // 기본 조명 자동 활성화 비활성화
//        scnView.defaultCameraController.interactionMode = .orbitTurntable
        
        
        
        // Coordinator에 뷰 참조 저장
        context.coordinator.view = scnView
        // 초기 속도 설정
        context.coordinator.internalSpeed = currentSpeed
        
     
        
        return scnView
    }
    
    // 상태값 변경될때
    func updateUIView(_ uiView: SCNView, context: Context) {
        guard let scene = uiView.scene else {
            print("씬 없음")
            return
        }
        
        context.coordinator.currentSpeed = currentSpeed
        context.coordinator.updateRotation(in: scene)
        
        // 아이템 선택 감지
        print("SnowmanView 업데이트: \(visibleItems)")
        
        let visibleItems = visibleItems
        
        hideAllNodes(node: scene.rootNode)
            
        // 2. camera와 light는 항상 표시
        showNodesWithNames(["camera", "omniLight", "areaLight", "areaLight2", "snow", "map"], rootNode: scene.rootNode)
            
        // 3. snow 노드 표시
        
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
            
            // 4. map 노드와 그 모든 자식들 표시
            if let mapNode = scene.rootNode.childNode(withName: "map", recursively: false) {
                mapNode.isHidden = false
                showAllChildNodes(mapNode)
            }
       
        
        // 외부에서 전달된 속도가 변경되면 내부 속도도 업데이트
        if context.coordinator.internalSpeed != currentSpeed {
            context.coordinator.internalSpeed = currentSpeed
        }
        
        if let snowNode = scene.rootNode.childNode(withName:"ball", recursively: true) {
            // 크기 조절 코드는 그대로 유지
            let scale = 0.5 + (Double(currentSteps) / 1000.0)
            let scaleAction = SCNAction.scale(to: CGFloat(scale), duration: 0.3)
            snowNode.runAction(scaleAction, forKey: "scaleAction")
            print("현재크기 \(scale)")
        }
        
        printNodeDetails(node: scene.rootNode)
        
    }
    
    // 씬 설정 (나머지 코드는 동일)
    private func loadScene() -> SCNScene {
        let scene = SCNScene(named: "Snow.scnassets/snow.scn") ?? SCNScene()
        
        scene.rootNode.name = "snow"
        
        
        let cameraNode = makeCamera()
        scene.rootNode.addChildNode(cameraNode)
        

         let mapNode = addMap()
            scene.rootNode.addChildNode(mapNode)
        
        
        // 쉐이딩 설정
        updateMaterialsToPhysicallyBased(for: scene)
        
        // 면광원 조명 추가
        let areaLightNode = makeAreaLight(intensity: 9000, name: "areaLight", position: SCNVector3(-8, 8, 30), areaExtents: simd_float3(x: 15, y: 15, z: 1))
        scene.rootNode.addChildNode(areaLightNode)
           
        let areaLightNode2 = makeAreaLight(intensity: 6000, name: "areaLight2", position: SCNVector3(8, -8, 10), areaExtents: simd_float3(x: 7, y: 7, z: 1.0))
        scene.rootNode.addChildNode(areaLightNode2)
        
        let makeOmniLightNode = makeOmniLight()
        scene.rootNode.addChildNode(makeOmniLightNode)
        
        let makeBackOmniLightNode = makeBackOmniLight()
        scene.rootNode.addChildNode(makeBackOmniLightNode)
        
        return scene
    }
    
    
}
