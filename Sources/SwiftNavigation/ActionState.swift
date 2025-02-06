import Foundation

public enum AnyActionState<Action> {
  case button(ButtonState<Action>)
  case textField(ButtonState<Action>)

  public func map<NewAction>(
    _ transform: (Action?) -> NewAction?
  ) -> AnyActionState<NewAction> {
    switch self {
    case let .button(buttonState):
      .button(buttonState.map(transform))

    case let .textField(textFieldState):
      .textField(textFieldState.map(transform))
    }
  }
}

extension AnyActionState: Equatable where Action: Equatable {}
extension AnyActionState: Hashable where Action: Hashable {}
extension AnyActionState: Sendable where Action: Sendable {}
