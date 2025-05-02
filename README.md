# RollingDice

A spatial computing dice rolling application for Apple Vision Pro that demonstrates physics-based interactions in a mixed reality environment.

## Index

1.  [Overview](#overview)
2.  [Key Features](key-features)
3.  [Technical Implementation Details](#techinical-details)
    *   [Physics Implementation](#physics)
    *   [3D Model (USDZ) Management](#3D)
    *   [Dice Face Detection System](#face)
    *   [Gesture Handling](#gesture)
    *   [Transparent Collision Floor](#floor)
    *   [Shared State Architecture](#shared-state)
4.  [Requirements](#requirements)
5.  [Getting Started](#getting-started)
6.  [License](#license)

## <a name="overview"></a>1. Overview

RollingDice is an immersive spatial application that allows users to interact with a 3D dice in mixed reality. The app uses RealityKit's physics engine to simulate realistic dice rolling behavior, complete with gravity, collision detection, and physics-based motion.

## <a name="key-features"></a>2. Key Features

- **3D Dice in Mixed Reality**: Places a fully interactive 3D dice model in your physical space
- **Physics-Based Interactions**: Realistic physics simulation for dice rolling and collisions
- **Gesture Controls**: Drag and drop the dice with natural hand gestures
- **Dice Face Detection**: Accurately determines which face is up when the dice comes to rest
- **Shared State Model**: Maintains dice state across both window and immersive views

## <a name="techinical-details"></a>3. Technical Implementation Details

### <a name="physics"></a>3.1 Physics Implementation

The app uses RealityKit's physics system to create realistic dice behavior:

```swift
// Physics properties for the dice
dice.components[PhysicsBodyComponent.self] = .init(PhysicsBodyComponent(
    massProperties: .default,
    material: .generate(staticFriction: 0.8, dynamicFriction: 0.5, restitution: 0.05),
    mode: .dynamic
))
```

The physics configuration uses carefully tuned parameters:
- `staticFriction: 0.8`: Determines how much the dice resists sliding when at rest
- `dynamicFriction: 0.5`: Controls friction when the dice is in motion
- `restitution: 0.05`: Sets the "bounciness" of the dice (low value for realistic dice behavior)

### <a name="3D"></a>3.2 3D Model (USDZ) Management

The application loads a USDZ model for the dice, navigating through its complex hierarchy:

```swift
if let diceModel = try? await Entity(named: "dice"),
   let dice = diceModel.children.first?.children.first?.children.first?.children.first?.children.first?.children.first?.children.first?.children.first {
    // Configure the dice
}
```

The deep nesting of `children.first` references indicates a complex hierarchy in the USDZ file. This approach traverses the model tree to find the actual dice mesh entity that needs to be manipulated.

### <a name="face"></a>3.3 Dice Face Detection System

One of the most interesting aspects is how the app determines which face is showing after the dice stops rolling:

```swift
// Mapping of directions to dice face values
let diceMap = [
//  [+, -]
    [3, 4], // x (red)   pos: 3; neg: 4
    [1, 6], // y (green) pos: 1; neg: 6
    [2, 5], // z (blue)  pos: 2; neg: 5
]
```

The system works by:

1. Waiting for the dice to stop moving (checking both linear and angular velocity)
2. Finding which axis (x, y, or z) of the dice is most aligned with the world's up direction
3. Determining whether that axis is pointing positively or negatively
4. Using the `diceMap` to translate this orientation into the correct face value

```swift
// Check if dice has stopped moving
if simd_length(diceMotion.linearVelocity) < 0.1 && simd_length(diceMotion.angularVelocity) < 0.1 {
    // Get local axes directions in world space
    let xDirection = dice.convert(direction: SIMD3(x: 1, y: 0, z: 0), to: nil)
    let yDirection = dice.convert(direction: SIMD3(x: 0, y: 1, z: 0), to: nil)
    let zDirection = dice.convert(direction: SIMD3(x: 0, y: 0, z: 1), to: nil)

    // Find which axis is most aligned with world up
    let greatestDirection = [
        0: xDirection.y,
        1: yDirection.y,
        2: zDirection.y
    ]
        .sorted(by: { abs($0.1) > abs($1.1) })[0]
    
    // Look up the face value in our mapping
    diceData.rolledNumber = diceMap[greatestDirection.key][greatestDirection.value > 0 ? 0 : 1]
}
```

This elegantly solves the problem of determining which face is up, regardless of the dice's final orientation.

### <a name="gesture"></a>3.4 Gesture Handling

The app implements a drag gesture that allows users to pick up, move, and drop the dice in the mixed reality environment:

```swift
var dragGesture: some Gesture {
    DragGesture()
        .targetedToAnyEntity()
        .onChanged { value in
            // Update position during drag
            value.entity.position = value.convert(value.location3D, from: .local, to: value.entity.parent!)
            // Switch to kinematic mode while being held
            value.entity.components[PhysicsBodyComponent.self]?.mode = .kinematic
        }
        .onEnded { value in
            // Return to dynamic physics when released
            value.entity.components[PhysicsBodyComponent.self]?.mode = .dynamic
            
            // Mark dice as dropped after a short delay
            if !droppedDice {
                Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                    droppedDice = true
                }
            }
        }
}
```

The physics body switches between `.kinematic` mode (when being dragged) and `.dynamic` mode (when released) to create natural interactions.

### <a name="floor"></a>3.5 Transparent Collision Floor

The app creates an invisible floor for the dice to land on:

```swift
let floor = ModelEntity(mesh: .generatePlane(width: 50, depth: 50), materials: [OcclusionMaterial()])
floor.generateCollisionShapes(recursive: false)
floor.components[PhysicsBodyComponent.self] = .init(
    massProperties: .default,
    mode: .static
)
```

Using `OcclusionMaterial()` creates a transparent surface that still interacts with physical objects, making the dice appear to land on an invisible plane in the user's space.

### <a name="shared-state"></a>3.6 Shared State Architecture

The app uses a shared `DiceData` class to maintain state between the window and immersive views:

```swift
@Observable
class DiceData {
    var rolledNumber = 0
}
```

This ensures that when the dice settles on a value in the immersive space, the window view updates to show the same number.

## <a name="requirements">4. Requirements

- Apple Vision Pro running visionOS 1.0 or later
- Xcode 15.0 or later with visionOS SDK

## <a name="getting-started">5. Getting Started

1. Clone this repository
2. Open the project in Xcode
3. Build and run on an Apple Vision Pro device

## <a name="license">6. License

This project is licensed under the <a href="https://github.com/lorenzo-27/RollingDice/blob/master/LICENSE" target="_blank">MIT</a> License.
