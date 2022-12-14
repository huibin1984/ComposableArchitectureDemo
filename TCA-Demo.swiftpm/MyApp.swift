import SwiftUI
import ComposableArchitecture

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            let initialState = AppState(todos: [
                Todo(
                    description: "Milk",
                    id: UUID(),
                    isComplete: false
                ),
                Todo(
                    description: "Eggs",
                    id: UUID(),
                    isComplete: false
                ),
                Todo(
                    description: "Hand Soap",
                    id: UUID(),
                    isComplete: true
                ),
            ])
            let store = Store(initialState: initialState,
                              reducer: appReducer,
                              environment: AppEnvironment())
            ContentView(store: store)
        }
    }
}
