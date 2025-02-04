import SwiftUI

public protocol ActionState {
  associatedtype Action
  associatedtype Body: View

  #if compiler(>=6)
    @MainActor
  #endif
  func body(withAction perform: @escaping (Action) -> Void) -> Body
}

public struct AnyActionState<Action>: ActionState {
  public typealias Action = Action

  public typealias Body = AnyView

  private let _body: (@escaping (Action) -> Void) -> AnyView

  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  #if compiler(>=6)
    @MainActor
  #endif
  public init<S: ActionState>(_ state: S) where S.Action == Action {
    self._body = { perform in
      AnyView(state.body(withAction: perform))
    }
  }

  public func body(withAction perform: @escaping (Action) -> Void) -> AnyView {
    self._body(perform)
  }
}
