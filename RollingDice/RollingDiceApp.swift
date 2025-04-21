import SwiftUI

@Observable
class DiceData {
    var rolledNumber = 0
}

@main
struct RollingDiceApp: App {

    @State private var appModel = AppModel()
    @State var diceData = DiceData()

    var body: some Scene {
        WindowGroup {
            ContentView(diceData: diceData)
        }
        .defaultSize(width: 100, height: 100)

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView(diceData: diceData)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
     }
}
