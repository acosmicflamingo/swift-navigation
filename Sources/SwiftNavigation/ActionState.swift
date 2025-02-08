import Foundation

public protocol ActionState<Action>: Identifiable {
  associatedtype Action

  var id: ID { get }
}

public enum AnyActionState<Action> {
  case button(ButtonState<Action>)
  case textField(TextFieldState<Action>)

  public var id: UUID {
    switch self {
    case let .button(buttonState):
      return buttonState.id

    case let .textField(textFieldState):
      return textFieldState.id
    }
  }
}

extension AnyActionState: ActionState {}

extension AnyActionState: Equatable where Action: Equatable {}
extension AnyActionState: Hashable where Action: Hashable {}
extension AnyActionState: Sendable where Action: Sendable {}
