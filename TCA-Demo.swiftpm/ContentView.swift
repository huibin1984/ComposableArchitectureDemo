import SwiftUI
import ComposableArchitecture

struct Todo: Equatable, Identifiable {
    var description = ""
    let id: UUID
    var isComplete = false
}

enum TodoAction: Equatable {
    case checkboxTapped
    case textFieldChanged(String)
}

struct todoEnvironment {
}

let todoReducer = Reducer<Todo, TodoAction, todoEnvironment> { state, action, environment in
    switch action {
    case .checkboxTapped:
        state.isComplete.toggle()
        return .none
    case .textFieldChanged(let text):
        state.description = text
        return .none
    }
}

struct AppState: Equatable {
    var todos: [Todo] = []
}

enum AppAction: Equatable {
    case addButtonTapped
    case todo(index: Int, action: TodoAction)
    case todoDelayCompleted
}

struct AppEnvironment {
    var uuid: () -> UUID
}
 
let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
    todoReducer.forEach(
        state: \AppState.todos,
        action: /AppAction.todo(index:action:),
        environment: { _ in todoEnvironment() }
    ),
    Reducer { state, action, environment in
        switch action {
        case .addButtonTapped:
            state.todos.insert(Todo(id: UUID()), at: 0)
            return .none
            
        case .todo(index: _, action: .checkboxTapped):
            struct CancelDelayID: Hashable {}
            return Effect(value: AppAction.todoDelayCompleted)
                .delay(for: 1, scheduler: DispatchQueue.main)
                .eraseToEffect()
                .cancellable(id: CancelDelayID(), cancelInFlight: true)
            
        case .todo(index: let index, action: let action):
            return .none
        
        case .todoDelayCompleted:
            state.todos = state.todos.enumerated()
                .sorted { lhs, rhs in
                    (!lhs.element.isComplete && rhs.element.isComplete)
                    || lhs.offset < rhs.offset
                }
                .map(\.element)
            
            return .none
        }
    }
)
    .debug()

struct TodoView: View {
    let store: Store<Todo, TodoAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            HStack {
                Button(action: { viewStore.send(.checkboxTapped) }) {
                    Image(systemName: viewStore.isComplete ? "checkmark.square" : "square")
                }
                .buttonStyle(PlainButtonStyle())
                
                TextField(
                    "Untitled todo",
                    text: viewStore.binding(
                        get: \.description,
                        send: TodoAction.textFieldChanged
                    )
                )
            }
            .foregroundColor(viewStore.isComplete ? .gray : nil)
        }
    }
}

struct ContentView: View {
    let store: Store<AppState, AppAction>
    
    var body: some View {
        NavigationView {
          WithViewStore(store) { viewStore in
            List {
                ForEachStore(
                    store.scope(state: \.todos, action: AppAction.todo(index:action:)),
                    content: TodoView.init(store:)
                )
            }
            .navigationBarTitle("Todos")
            .navigationBarItems(trailing: Button("Add", action: {
                viewStore.send(.addButtonTapped)
            }))
          }
        }
    }
}
