import SwiftUI

public protocol ActionState {
  associatedtype Action
  associatedtype Body: View

  func body(withAction perform: @escaping (Action) -> Void) -> Body
}

public struct AnyActionState<Action>: ActionState {
  public typealias Action = Action

  public typealias Body = AnyView

  private let _body: (@escaping (Action) -> Void) -> AnyView

  public init<S: ActionState>(_ state: S) where S.Action == Action {
    self._body = { perform in
      AnyView(state.body(withAction: perform))
    }
  }

  public func body(withAction perform: @escaping (Action) -> Void) -> AnyView {
    self._body(perform)
  }
}
