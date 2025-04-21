import SwiftUI
import RealityKit
import RealityKitContent

let diceMap = [
//  [+, -]
    [3, 4], // x (red)   pos: 3; neg: 4
    [1, 6], // y (green) pos: 1; neg: 6
    [2, 5], // z (blue)  pos: 2; neg: 5
]

struct ImmersiveView: View {
    var diceData: DiceData
    @State var droppedDice = false

    var body: some View {
        RealityView { content in
            // pavimento trasparente che consente la "caduta" del dado
            let floor = ModelEntity(mesh: .generatePlane(width: 50, depth:  50), materials: [OcclusionMaterial()])
            floor.generateCollisionShapes(recursive: false)
            floor.components[PhysicsBodyComponent.self] = .init(
                massProperties: .default,
                mode: .static
            )
            
            content.add(floor)
            
            if let diceModel = try? await Entity(named: "dice"),
               // con children e first mi muovo all'interno del file dice.usdz, devo prendere la mesh
               let dice = diceModel.children.first?.children.first?.children.first?.children.first?.children.first?.children.first?.children.first?.children.first,
               // skybox
               let environment = try? await EnvironmentResource(named: "studio") {
                dice.scale = [0.1, 0.1, 0.1]
                
                // posizionamento del dado dall'alto e "lontano" -1 dall'utente
                dice.position.y = 0.5
                dice.position.z = -1
                
                // collisioni del dado
                dice.generateCollisionShapes(recursive: false)
                dice.components.set(InputTargetComponent())
                
                // dice lightining and shadows
                dice.components.set(ImageBasedLightComponent(source: .single(environment)))
                dice.components.set(ImageBasedLightReceiverComponent(imageBasedLight: dice))
                dice.components.set(GroundingShadowComponent(castsShadow: true))
                
                // proprietà fisiche del dado: modificandole cambia il comportamento del dado nello spazio
                dice.components[PhysicsBodyComponent.self] = .init(PhysicsBodyComponent(
                    massProperties: .default,
                    material: .generate(staticFriction: 0.8, dynamicFriction: 0.5, restitution: 0.05),
                    mode: .dynamic
                ))
                
                dice.components[PhysicsMotionComponent.self] = .init()
                
                content.add(dice)
                
                let _ = content.subscribe(to: SceneEvents.Update.self) { event in
                    guard droppedDice else { return }
                    guard let diceMotion = dice.components[PhysicsMotionComponent.self] else { return }
                    
                    // controllo velocità e velocità angolare per sapere se il dado è fermo
                    if simd_length(diceMotion.linearVelocity) < 0.1 && simd_length(diceMotion.angularVelocity) < 0.1 {
                        // controlliamo dove puntano le direzioni delle facce del dado
                        let xDirection = dice.convert(direction: SIMD3(x: 1, y: 0, z: 0), to: nil)
                        let yDirection = dice.convert(direction: SIMD3(x: 0, y: 1, z: 0), to: nil)
                        let zDirection = dice.convert(direction: SIMD3(x: 0, y: 0, z: 1), to: nil)

                        let greatestDirection = [
                            0: xDirection.y,
                            1: yDirection.y,
                            2: zDirection.y
                        ]
                            // sorting basato su quale faccia del dado ha il valore di y più alto in abs
                            .sorted(by: { abs($0.1) > abs($1.1) })[0]
                        
                        diceData.rolledNumber = diceMap[greatestDirection.key][greatestDirection.value > 0 ? 0 : 1]
                    }
                }
            }
        }
        .gesture(dragGesture)
    }
    
    var dragGesture: some Gesture {
        DragGesture()
            // target su tutte le entità anche se l'unica entità presente è il dado
            .targetedToAnyEntity()
            .onChanged { value in
                value.entity.position = value.convert(value.location3D, from: .local, to: value.entity.parent!)
                value.entity.components[PhysicsBodyComponent.self]?.mode = .kinematic
            }
            .onEnded { value in
                value.entity.components[PhysicsBodyComponent.self]?.mode = .dynamic
                
                // controllo se il dado è stato rilasciato oppure no
                if !droppedDice {
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                        droppedDice = true
                    }
                }
            }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView(diceData: DiceData())
        .environment(AppModel())
}
