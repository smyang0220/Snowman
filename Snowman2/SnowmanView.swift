import SceneKit
import SwiftUI

struct SnowmanView: UIViewRepresentable {
    var currentSpeed: Double
    var currentSteps: Int
    
    
    // 처음 생성할때
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        let scene = loadScene()
        scnView.scene = scene
        scnView.allowsCameraControl = true
        
        return scnView
    }
    
    
    // 상태값 변경될때
    func updateUIView(_ uiView: SCNView, context: Context) {
        guard let scene = uiView.scene else {
            print("씬 없음")
            return
        }
        
        print("통과")
        
        if let snowNode = scene.rootNode.childNode(withName:"구체", recursively : true){
            let rotationSpeed = Float(currentSpeed * 0.5)
            snowNode.runAction(SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(rotationSpeed), duration: 0.1))
            
            let scale = 0.5 + (Double(currentSteps) / 1000.0)
            let scaleAction = SCNAction.scale(to: CGFloat(scale), duration: 0.3)
            snowNode.runAction(scaleAction)
            print("현재크기 \(scale)")
        }
    }
    
    // 씬 설정
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
        
        return scene
    }
    
    // 카메라 노드 생성
    func makeCamera() -> SCNNode {
            let cameraNode = SCNNode()
           cameraNode.camera = SCNCamera()
           cameraNode.position = SCNVector3(x: 0, y: 0, z: 4)
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
    func makeAreaLight( intensity : CGFloat , name : String , position : SCNVector3, areaExtents : simd_float3 ) -> SCNNode {
        let areaLightNode = SCNNode()
        let areaLight = SCNLight()
        areaLight.type = .area
        areaLight.intensity = intensity // 면광원으로 부드러운 조명 효과
        areaLight.areaType = .rectangle // 또는 .line, .polygon
        areaLight.areaExtents = areaExtents // 크기 조절 (width, height, depth)
        areaLightNode.light = areaLight
        areaLightNode.position = position // 적절한 위치 조정
        areaLightNode.look(at: SCNVector3.init(x: 0.5, y: 0.6, z: 0.2))
        areaLightNode.name = name
        return areaLightNode
    }

    
}
