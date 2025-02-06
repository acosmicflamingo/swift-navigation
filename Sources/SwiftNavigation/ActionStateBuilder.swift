@resultBuilder

public enum ActionStateBuilder<Action> {
  @available(iOS 16.0.0, *)
  public static func buildArray(
    _ components: [[any ActionState<Action>]]
  ) -> [AnyActionState<Action>] {
    components.flatMap { $0 }
      .compactMap {
        switch $0 {
        case let buttonState as ButtonState<Action>:
            .button(buttonState)

        default:
          nil
        }
      }
  }

  @available(iOS 16.0.0, *)
  public static func buildBlock(
    _ components: [any ActionState<Action>]...
  ) -> [AnyActionState<Action>] {
    components.flatMap { $0 }
      .compactMap {
        switch $0 {
        case let buttonState as ButtonState<Action>:
            .button(buttonState)

        default:
          nil
        }
      }
  }

  @available(iOS 16.0.0, *)
  public static func buildLimitedAvailability(
    _ component: [any ActionState<Action>]
  ) -> [AnyActionState<Action>] {
    component.compactMap {
      switch $0 {
      case let buttonState as ButtonState<Action>:
          .button(buttonState)

      default:
        nil
      }
    }
  }

  @available(iOS 16.0.0, *)
  public static func buildEither(
    first component: [any ActionState<Action>]
  ) -> [AnyActionState<Action>] {
    component.compactMap {
      switch $0 {
      case let buttonState as ButtonState<Action>:
          .button(buttonState)

      default:
        nil
      }
    }
  }

  @available(iOS 16.0.0, *)
  public static func buildEither(
    second component: [any ActionState<Action>]
  ) -> [AnyActionState<Action>] {
    component.compactMap {
      switch $0 {
      case let buttonState as ButtonState<Action>:
          .button(buttonState)

      default:
        nil
      }
    }
  }

  @available(iOS 16.0.0, *)
  public static func buildExpression(
    _ expression: any ActionState<Action>
  ) -> [any ActionState<Action>] {
    [expression]
  }

  @available(iOS 16.0.0, *)
  public static func buildOptional(
    _ component: [any ActionState<Action>]?
  ) -> [any ActionState<Action>] {
    component ?? []
  }
}
