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

  public func map<NewAction>(
    _ transform: @escaping @Sendable (Action?) -> NewAction?
  ) -> AnyActionState<NewAction>
  where Action: Sendable {
    switch self {
    case let .button(buttonState):
      .button(buttonState.map(transform))

    case let .textField(textFieldState):
      .textField(textFieldState.map(transform))
    }
  }
}

extension AnyActionState: ActionState {}

extension AnyActionState: Equatable where Action: Equatable {}
extension AnyActionState: Hashable where Action: Hashable {}
extension AnyActionState: Sendable where Action: Sendable {}
