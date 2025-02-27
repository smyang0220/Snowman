//
//  snowmanManager.swift
//  Snowman2
//
//  Created by 양희태 on 2/27/25.
//
import SceneKit
import SwiftUI

// 카메라 노드 생성
func makeCamera() -> SCNNode {
    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3(x: -12, y: 1, z: 6)
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
    omniLight.intensity = 200 // 조명 강도를 낮추어 부드러운 느낌
    omniLight.color = UIColor.white.withAlphaComponent(0.5) // 은은한 조명
    omniLightNode.light = omniLight
    omniLightNode.position = SCNVector3(-12, 10, 10) // 위치 설정
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
    omniLightNode.position = SCNVector3(-12, 10, -10) // 위치 설정
    omniLightNode.name = "omniLight"
    
       
    
    return omniLightNode
}

// MARK: 맵 노드 추가
func addMap() -> SCNNode {
    let scene = SCNScene(named: "Map.scnassets/map.scn") ?? SCNScene()
    scene.rootNode.name = "map"

    // 눈사람 아래에 바닥이 위치해야해서 y축 음수
    moveNodeToPosition(node: scene.rootNode, x: 0.0, y: -1.0, z: 0.0) // x, y, z 값은 원하는 위치로 설정
    return scene.rootNode
}

// MARK: 모델 좌표 이동
func moveNodeToPosition(node: SCNNode, x: Float, y: Float, z: Float) {
    node.position = SCNVector3(x, y, z)
}
