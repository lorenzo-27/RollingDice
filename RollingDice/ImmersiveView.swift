import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
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
            }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
