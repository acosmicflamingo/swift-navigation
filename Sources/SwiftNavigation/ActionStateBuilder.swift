

@resultBuilder
public enum ActionStateBuilder<Action> {
  public static func buildArray(
    _ components: [[AnyActionState<Action>]]
  ) -> [AnyActionState<Action>] {
    components.flatMap { $0 }
  }

  public static func buildBlock(
    _ components: [AnyActionState<Action>]...
  ) -> [AnyActionState<Action>] {
    components.flatMap { $0 }
  }

  public static func buildLimitedAvailability(
    _ component: [AnyActionState<Action>]
  ) -> [AnyActionState<Action>] {
    component
  }

  public static func buildEither(
    first component: [AnyActionState<Action>]
  ) -> [AnyActionState<Action>] {
    component
  }

  public static func buildEither(
    second component: [AnyActionState<Action>]
  ) -> [AnyActionState<Action>] {
    component
  }

  public static func buildExpression(
    _ expression: AnyActionState<Action>
  ) -> [AnyActionState<Action>] {
    [expression]
  }

  public static func buildOptional(
    _ component: [AnyActionState<Action>]?
  ) -> [AnyActionState<Action>] {
    component ?? []
  }
}
