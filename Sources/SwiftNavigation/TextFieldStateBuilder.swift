@resultBuilder
public enum TextFieldStateBuilder<Action> {
  public static func buildArray(_ components: [[TextFieldState<Action>]]) -> [TextFieldState<Action>] {
    components.flatMap { $0 }
  }

  public static func buildBlock(_ components: [TextFieldState<Action>]...) -> [TextFieldState<Action>] {
    components.flatMap { $0 }
  }

  public static func buildLimitedAvailability(
    _ component: [TextFieldState<Action>]
  ) -> [TextFieldState<Action>] {
    component
  }

  public static func buildEither(first component: [TextFieldState<Action>]) -> [TextFieldState<Action>] {
    component
  }

  public static func buildEither(second component: [TextFieldState<Action>]) -> [TextFieldState<Action>] {
    component
  }

  public static func buildExpression(_ expression: TextFieldState<Action>) -> [TextFieldState<Action>] {
    [expression]
  }

  public static func buildOptional(_ component: [TextFieldState<Action>]?) -> [TextFieldState<Action>] {
    component ?? []
  }
}
