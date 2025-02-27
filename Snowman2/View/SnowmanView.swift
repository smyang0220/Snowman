import SceneKit
import SwiftUI

struct SnowmanView: UIViewRepresentable {
    var currentSpeed: Double
    var currentSteps: Int
    
    // Coordinator 클래스를 추가하여 타이머와 내부 속도를 관리
    class Coordinator: NSObject {
        var timer: Timer?
        var internalSpeed: Double = 0
        var view: SCNView?
        
        override init() {
            super.init()
            
            // 5초마다 속도를 5씩 증가시키는 타이머 설정
            timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                // 속도 증가
                self.internalSpeed += 5.0
                print("속도 자동 증가: \(self.internalSpeed)")
                
                // 현재 씬 뷰가 있으면 회전 업데이트
                if let scnView = self.view, let scene = scnView.scene {
                    self.updateRotation(in: scene)
                }
            }
        }
        
        func updateRotation(in scene: SCNScene) {
            if let snowNode = scene.rootNode.childNode(withName:"SnowBody", recursively: true) {
                // 속도에 비례하는 회전 속도 설정
                let rotationSpeed = Float(self.internalSpeed * 0.5)
                
                // 회전 액션 키
                let rotationActionKey = "rotationAction"
                
                // 애니메이션 방식으로 처리
                if rotationSpeed > 0 {
                    // 새로운 회전 동작 생성
                    let rotateAction = SCNAction.rotateBy(x: CGFloat(rotationSpeed), y: 0, z: 0, duration: 1)
                    let repeatAction = SCNAction.repeatForever(rotateAction)
                    
                    // 기존 액션이 있으면 부드럽게 전환
                    if snowNode.action(forKey: rotationActionKey) != nil {
                        SCNTransaction.begin()
                        SCNTransaction.animationDuration = 0.3
                        snowNode.removeAction(forKey: rotationActionKey)
                        snowNode.runAction(repeatAction, forKey: rotationActionKey)
                        SCNTransaction.commit()
                    } else {
                        snowNode.runAction(repeatAction, forKey: rotationActionKey)
                    }
                }
                
                print("현재스피드 \(rotationSpeed)")
            }
        }
        
        deinit {
            // 뷰가 해제될 때 타이머도 해제
            timer?.invalidate()
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
        scnView.allowsCameraControl = true
        
        scnView.backgroundColor = .clear
        
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
    }
    
    // 씬 설정 (나머지 코드는 동일)
    private func loadScene() -> SCNScene {
        let scene = SCNScene(named: "Snow.scnassets/snow.scn") ?? SCNScene()
               
        // 카메라 노드 추가
        let cameraNode = makeCamera()
        scene.rootNode.addChildNode(cameraNode)
        
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
    
    // 카메라 노드 생성
    func makeCamera() -> SCNNode {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 1, z: 4)
        cameraNode.camera?.automaticallyAdjustsZRange = false
        cameraNode.name = "camera"
        return cameraNode
    }
    
    // 쉐이딩 파트
    func updateMaterialsToPhysicallyBased(for scene: SCNScene) {
        scene.rootNode.enumerateChildNodes { (node, _) in
            for material in node.geometry?.materials ?? [] {
                material.lightingModel = .physicallyBased
                material.roughness.contents = 0.8 // 거칠기 값을 높여 매트하게 만듭니다.
            }
        }
    }
    
    // 면광원 조명 추가
    func makeAreaLight(intensity: CGFloat, name: String, position: SCNVector3, areaExtents: simd_float3) -> SCNNode {
        let areaLightNode = SCNNode()
        let areaLight = SCNLight()
        areaLight.type = .area
        areaLight.intensity = intensity
        areaLight.areaType = .rectangle
        areaLight.areaExtents = areaExtents
        areaLightNode.light = areaLight
        areaLightNode.position = position
        areaLightNode.look(at: SCNVector3.init(x: 0.5, y: 0.6, z: 0.2))
        areaLightNode.name = name
        return areaLightNode
    }
    
    // 점광원
    func makeOmniLight() -> SCNNode {
        let omniLightNode = SCNNode()
        let omniLight = SCNLight()
        omniLight.type = .omni
        // 중간점검 800
        omniLight.intensity = 100 // 조명 강도를 낮추어 부드러운 느낌
        omniLight.color = UIColor.white.withAlphaComponent(0.5) // 은은한 조명
        omniLightNode.light = omniLight
        omniLightNode.position = SCNVector3(0, 10, 10) // 위치 설정
        omniLightNode.name = "omniLight"
        
           
        
        return omniLightNode
    }
    
    // 점광원
    func makeBackOmniLight() -> SCNNode {
        let omniLightNode = SCNNode()
        let omniLight = SCNLight()
        omniLight.type = .omni
        // 중간점검 800
        omniLight.intensity = 200 // 조명 강도를 낮추어 부드러운 느낌
        omniLight.color = UIColor.white.withAlphaComponent(0.5) // 은은한 조명
        omniLightNode.light = omniLight
        omniLightNode.position = SCNVector3(0, 10, -10) // 위치 설정
        omniLightNode.name = "omniLight"
        
           
        
        return omniLightNode
    }
}
