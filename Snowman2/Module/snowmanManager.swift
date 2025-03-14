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
//    cameraNode.camera?.fieldOfView = 90
    let angle = Float(-18 * Float.pi / 180)
    cameraNode.eulerAngles.x = angle
    cameraNode.camera?.automaticallyAdjustsZRange = true
    cameraNode.name = "camera"
    return cameraNode
}

// 냉동실
func makeCamera2() -> SCNNode {
    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3(x: 0, y: 1, z: 6)
    cameraNode.camera?.automaticallyAdjustsZRange = false
    cameraNode.name = "camera"
    return cameraNode
}

// 쉐이딩 파트
func updateMaterialsToPhysicallyBased(for scene: SCNScene) {
    // 재귀적으로 모든 노드를 방문하는 함수
    func updateMaterials(node: SCNNode) {
        // 현재 노드의 재질 업데이트
        if let geometry = node.geometry {
            for (index, material) in geometry.materials.enumerated() {
                // 기존 라이팅 모델 저장
                let oldLightingModel = material.lightingModel
                let materialName = material.name ?? "이름 없음"
                
                // 새로운 재질 생성
                let newMaterial = SCNMaterial()
                newMaterial.name = materialName
                newMaterial.lightingModel = .physicallyBased
                
                // 기존 재질의 속성 복사
                if let diffuseContents = material.diffuse.contents {
                    newMaterial.diffuse.contents = diffuseContents
                } else {
                    newMaterial.diffuse.contents = UIColor.white
                }
                
                // PBR 속성 설정
                newMaterial.roughness.contents = NSNumber(value: 1.0)
                
                // 새 재질 적용
                geometry.replaceMaterial(at: index, with: newMaterial)
                
                print("재질 업데이트: \(materialName)")
                print("  변경 전: \(oldLightingModel)")
                print("  변경 후: \(newMaterial.lightingModel)")
                print("  roughness: \(newMaterial.roughness.contents ?? "nil")")
                print("  metalness: \(newMaterial.metalness.contents ?? "nil")")
                print("  diffuse: \(newMaterial.diffuse.contents ?? "nil")")
            }
        }
        
        // 모든 자식 노드에 대해 재귀적으로 호출
        for childNode in node.childNodes {
            updateMaterials(node: childNode)
        }
    }
    
    // 루트 노드부터 시작하여 모든 노드 처리
    updateMaterials(node: scene.rootNode)
    print("모든 재질을 피지컬 베이스드로 업데이트 완료")
}

// 면광원 조명 추가
func makeAreaLight(intensity: CGFloat, name: String, position: SCNVector3, areaExtents: simd_float3, color: UIColor) -> SCNNode {
    let areaLightNode = SCNNode()
    let areaLight = SCNLight()
    areaLight.type = .area
    areaLight.intensity = intensity
    areaLight.areaType = .rectangle
    areaLight.areaExtents = areaExtents
    areaLight.color = color
    
    // 그림자 설정
    areaLight.castsShadow = true
    areaLight.shadowRadius = 2.0  // 부드러운 그림자 경계
    areaLight.shadowColor = UIColor.black.withAlphaComponent(0.6)  // 반투명 그림자
    areaLight.shadowMode = .deferred
    areaLight.shadowSampleCount = 8  // 성능과 품질의 균형
    
    areaLightNode.light = areaLight
    areaLightNode.position = position
    
    // 눈사람 중심을 바라보게 설정
    areaLightNode.look(at: SCNVector3(x: -12, y: 0, z: 0))
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

// MARK: 맵 노드 추가
func addRefrigerator() -> SCNNode {
    let scene = SCNScene(named: "Refrigerator.scnassets/refrigerator.scn") ?? SCNScene()
    scene.rootNode.name = "refrigerator"

    // 눈사람 아래에 바닥이 위치해야해서 y축 음수
    moveNodeToPosition(node: scene.rootNode, x: 0.0, y: -3.0, z: 0.0) // x, y, z 값은 원하는 위치로 설정
    return scene.rootNode
}

// MARK: 모델 좌표 이동
func moveNodeToPosition(node: SCNNode, x: Float, y: Float, z: Float) {
    node.position = SCNVector3(x, y, z)
}


// MARK: 노드 숨기기 관련 코드들
// 모든 노드와 자식들 숨기기
func hideAllNodes(node: SCNNode) {
    node.isHidden = true
    
    for childNode in node.childNodes {
        hideAllNodes(node: childNode)
    }
}

// 특정 이름을 가진 노드들 표시
func showNodesWithNames(_ names: [String], rootNode: SCNNode) {
    if let nodeName = rootNode.name, names.contains(nodeName) {
        rootNode.isHidden = false
    }
    
    for childNode in rootNode.childNodes {
        showNodesWithNames(names, rootNode: childNode)
    }
}

// 노드와 모든 자식 노드 표시
func showAllChildNodes(_ node: SCNNode) {
    node.isHidden = false
    
    for childNode in node.childNodes {
        showAllChildNodes(childNode)
    }
}

// MARK: 모든 노드 출력
func printNodeDetails(node: SCNNode, depth: Int = 0) {
    // 현재 노드의 이름과 깊이를 출력합니다.
    let indentation = String(repeating: "  ", count: depth)
    print("\(indentation)Node name: \(node.name ?? "Unnamed")")
    print("\(indentation)  IsHidden: \(node.isHidden)")
    // 노드의 지오메트리가 있으면 지오메트리의 정보를 출력합니다.
    if let geometry = node.geometry {
        print("\(indentation)  Geometry: \(geometry.name ?? "Unnamed")")
        for material in geometry.materials {
            if let color = material.diffuse.contents as? UIColor {
//                print("\(indentation)    Material color: \(color)")
            }
        }
    }
    
    // 자식 노드가 있으면 자식 노드를 재귀적으로 탐색합니다.
    for childNode in node.childNodes {
        printNodeDetails(node: childNode, depth: depth + 1)
    }
}


// 스케일 및 위치 조정을 위한 공통 함수
func updateScaleAndPosition(
    for node: SCNNode,
    initialScale: Double,
    scaleRatio: Double,
    initialY: Double,
    positionYRatio: Double,
    actionKey: String,
    currentSteps : Int
) {
    let scale = initialScale + (Double(currentSteps) / scaleRatio)
    let scaleAction = SCNAction.scale(to: CGFloat(scale), duration: 0.3)
    
    
    let newX = -6
    - (Double(currentSteps) / 5000)
    let newY = initialY
    + (Double(currentSteps) / positionYRatio)
    
    // 기존 x, z 값 유지
    let newPosition = SCNVector3(Float(newX), Float(newY), node.position.z)
    
    // 위치와 스케일 동시 애니메이션
    SCNTransaction.begin()
    SCNTransaction.animationDuration = 0.3
    node.position = newPosition
    SCNTransaction.commit()
    
    node.runAction(scaleAction, forKey: actionKey)
    print("\(node.name ?? "노드") 현재크기: \(scale), 위치Y: \(newY)")
}

// 카메라 위치 업데이트 함수
func updateCameraPosition(for camera: SCNNode, currentSteps: Int) {
    let baseY = 1.0
    let baseZ = 6.0
    
    // 스텝에 따른 증분 계산
    let additionalY = (Double(currentSteps) / 1000) 
    let additionalZ = (Double(currentSteps) / 1000)
    let newX = -6
    - (Double(currentSteps) / 5000)
    // 새 위치 계산
    let newPosition = SCNVector3(
        Float(newX),
        Float(baseY + additionalY),
        Float(baseZ + additionalZ)
    )
    
    // 애니메이션으로 위치 이동
    let moveAction = SCNAction.move(to: newPosition, duration: 0.3)
    camera.runAction(moveAction, forKey: "cameraPositionAction")
    
    print("카메라 위치: Y=\(newPosition.y), Z=\(newPosition.z)")
}
