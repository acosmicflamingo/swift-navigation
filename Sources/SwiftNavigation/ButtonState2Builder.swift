@resultBuilder
public enum ButtonState2Builder<Action> {
  public static func buildArray(_ components: [[ButtonState2<Action>]]) -> [ButtonState2<Action>] {
    components.flatMap { $0 }
  }

  public static func buildBlock(_ components: [ButtonState2<Action>]...) -> [ButtonState2<Action>] {
    components.flatMap { $0 }
  }

  public static func buildLimitedAvailability(
    _ component: [ButtonState2<Action>]
  ) -> [ButtonState2<Action>] {
    component
  }

  public static func buildEither(first component: [ButtonState2<Action>]) -> [ButtonState2<Action>] {
    component
  }

  public static func buildEither(second component: [ButtonState2<Action>]) -> [ButtonState2<Action>] {
    component
  }

  public static func buildExpression(_ expression: ButtonState2<Action>) -> [ButtonState2<Action>] {
    [expression]
  }

  public static func buildOptional(_ component: [ButtonState2<Action>]?) -> [ButtonState2<Action>] {
    component ?? []
  }
}
