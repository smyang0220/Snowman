import SceneKit
import SwiftUI

// MARK: 3D　눈사람
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
        }
        
        func updateRotation(in scene: SCNScene) {
            print("updateRotation(in:) 호출됨 \(currentSpeed)") // 디버깅 메시지
            
            // 회전 액션 적용을 위한 공통 함수
            func applyRotation(to node: SCNNode, speedFactor: Float, xAxis: CGFloat = 0, yAxis: CGFloat = 0, zAxis: CGFloat = 0, actionKey: String) {
                // currentSpeed가 0이면 회전 멈춤
                if currentSpeed == 0 {
                    node.removeAction(forKey: actionKey) // 회전 액션 제거
                    print("\(node.name ?? "노드") 회전 멈춤")
                    return
                }
                
                let speed = Float(currentSpeed) * speedFactor
                
                // 속도가 의미 있는 방향인지 확인 (SnowBody와 SnowHead는 음수, map은 양수일 때만 회전)
                let isValidDirection = (speedFactor < 0 && speed < 0) || (speedFactor > 0 && speed > 0)
                
                if isValidDirection {
                    // 새로운 회전 동작 생성
                    let rotateAction = SCNAction.rotateBy(
                        x: xAxis * CGFloat(speed),
                        y: yAxis * CGFloat(speed),
                        z: zAxis * CGFloat(speed),
                        duration: 1
                    )
                    let repeatAction = SCNAction.repeatForever(rotateAction)
                    
                    // 기존 액션이 있으면 부드럽게 전환
                    if node.action(forKey: actionKey) != nil {
                        SCNTransaction.begin()
                        SCNTransaction.animationDuration = 0.3
                        node.removeAction(forKey: actionKey)
                        node.runAction(repeatAction, forKey: actionKey)
                        SCNTransaction.commit()
                    } else {
                        node.runAction(repeatAction, forKey: actionKey)
                    }
                    
                    print("\(node.name ?? "노드") 현재스피드 \(speed)")
                } else {
                    // 속도가 유효하지 않은 방향이면 회전 멈춤
                    node.removeAction(forKey: actionKey)
                }
            }
            
            // SnowBody 회전 (x축)
            if let snowBodyNode = scene.rootNode.childNode(withName: "SnowBody", recursively: true) {
                applyRotation(
                    to: snowBodyNode,
                    speedFactor: -0.0005, // 음수로 설정
                    xAxis: 1,             // x축 회전
                    actionKey: "snowRotationAction"
                )
            }
            
            // SnowHead 회전 (y축)
            if let snowHeadNode = scene.rootNode.childNode(withName: "SnowHead", recursively: true) {
                applyRotation(
                    to: snowHeadNode,
                    speedFactor: -0.0005, // 음수로 설정
                    yAxis: 1,             // y축 회전
                    actionKey: "snowRotationHeadAction"
                )
            }
            
            // Map 회전 (y축)
            if let mapNode = scene.rootNode.childNode(withName: "map", recursively: true) {
                applyRotation(
                    to: mapNode,
                    speedFactor: 0.0001,  // 양수로 설정
                    yAxis: 1,             // y축 회전
                    actionKey: "mapRotationAction"
                )
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
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = false // 기본 조명 자동 활성화 비활성화
        
        
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
        showNodesWithNames(["camera", "omniLight", "areaLight", "areaLight2", "areaLight3","snow", "map","keyLight","fillLight","backLight","ambientLight","mapLight"], rootNode: scene.rootNode)
            
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

        // 눈사람 머리
        if let snowHeadNode = scene.rootNode.childNode(withName: "SnowHead", recursively: true) {
            updateScaleAndPosition(
                for: snowHeadNode,
                initialScale: 0.2,
                scaleRatio: 3600,  // 크면 클수록 작아짐
                initialY: -0.13,
                positionYRatio: 1200,  // y축 좌표
                actionKey: "scaleAction",
                currentSteps: currentSteps
            )
        }

        // 눈사람 몸체
        if let snowBodyNode = scene.rootNode.childNode(withName: "SnowBody", recursively: true) {
            updateScaleAndPosition(
                for: snowBodyNode,
                initialScale: 0.3,
                scaleRatio: 2400,  // scale
                initialY: -0.6,
                positionYRatio: 2800,  // y축 좌표
                actionKey: "scaleAction",
                currentSteps: currentSteps
            )
        }

        // 카메라 위치 업데이트
        if let cameraNode = scene.rootNode.childNode(withName: "camera", recursively: true) {
            updateCameraPosition(for: cameraNode, currentSteps: currentSteps)
        }
        
        // 전체 노드 확인
//        printNodeDetails(node: scene.rootNode)
        
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
        
       
        
        // 주요 조명(key light) - 주 광원, 눈사람의 정면에서 약간 위쪽 방향
        let keyLight = makeAreaLight(
            intensity: 600,
            name: "keyLight",
            position: SCNVector3(-20, 10, 15),
            areaExtents: simd_float3(x: 150, y: 150, z: 1),
            color: UIColor(white: 1.0, alpha: 1.0)
        )
        scene.rootNode.addChildNode(keyLight)

        // 보조 조명(fill light) - 그림자를 부드럽게 만들어주는 덜 강한 조명
        let fillLight = makeAreaLight(
            intensity: 300,
            name: "fillLight",
            position: SCNVector3(10, 5, 10),
            areaExtents: simd_float3(x: 100, y: 100, z: 1),
            color: UIColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 1.0) // 약간 푸른 계열
        )
        scene.rootNode.addChildNode(fillLight)

        // 환경 조명 - 전체적인 분위기를 만드는 약한 조명
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 200
        ambientLight.light?.color = UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0) // 차가운 환경광
        ambientLight.name = "ambientLight"
        scene.rootNode.addChildNode(ambientLight)

        return scene
    }
    
    
}
