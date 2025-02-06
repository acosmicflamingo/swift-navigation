import CustomDump
import Foundation
import IssueReporting

#if canImport(SwiftUI)
  import SwiftUI
#endif

public struct ButtonState2<Action>: Identifiable {
  public let id: UUID
  public let action: ButtonState2Action<Action>
  public let label: TextState
  public let role: ButtonState2Role?

  init(
    id: UUID,
    action: ButtonState2Action<Action>,
    label: TextState,
    role: ButtonState2Role?
  ) {
    self.id = id
    self.action = action
    self.label = label
    self.role = role
  }

  /// Creates button state.
  ///
  /// - Parameters:
  ///   - role: An optional semantic role that describes the button. A value of `nil` means that the
  ///     button doesn't have an assigned role.
  ///   - action: The action to send when the user interacts with the button.
  ///   - label: A view that describes the purpose of the button's `action`.
  public init(
    role: ButtonState2Role? = nil,
    action: ButtonState2Action<Action> = .send(nil),
    label: () -> TextState
  ) {
    self.init(id: UUID(), action: action, label: label(), role: role)
  }

  /// Creates button state.
  ///
  /// - Parameters:
  ///   - role: An optional semantic role that describes the button. A value of `nil` means that the
  ///     button doesn't have an assigned role.
  ///   - action: The action to send when the user interacts with the button.
  ///   - label: A view that describes the purpose of the button's `action`.
  public init(
    role: ButtonState2Role? = nil,
    action: Action,
    label: () -> TextState
  ) {
    self.init(id: UUID(), action: .send(action), label: label(), role: role)
  }

  /// Handle the button's action in a closure.
  ///
  /// - Parameter perform: Unwraps and passes a button's action to a closure to be performed. If the
  ///   action has an associated animation, the context will be wrapped using SwiftUI's
  ///   `withAnimation`.
  public func withAction(_ perform: (Action?) -> Void) {
    switch self.action.type {
    case let .send(action):
      perform(action)
    #if canImport(SwiftUI)
      case let .animatedSend(action, animation):
        withAnimation(animation) {
          perform(action)
        }
    #endif
    }
  }

  /// Handle the button's action in an async closure.
  ///
  /// > Warning: Async closures cannot be performed with animation. If the underlying action is
  /// > animated, a runtime warning will be emitted.
  ///
  /// - Parameter perform: Unwraps and passes a button's action to a closure to be performed.
  @MainActor
  public func withAction(_ perform: @MainActor (Action?) async -> Void) async {
    switch self.action.type {
    case let .send(action):
      await perform(action)
    #if canImport(SwiftUI)
      case let .animatedSend(action, _):
        var output = ""
        customDump(self.action, to: &output, indent: 4)
        reportIssue(
          """
          An animated action was performed asynchronously: …

            Action:
          \((output))

          Asynchronous actions cannot be animated. Evaluate this action in a synchronous closure, \
          or use 'SwiftUI.withAnimation' explicitly.
          """
        )
        await perform(action)
    #endif
    }
  }

  /// Transforms a button state's action into a new action.
  ///
  /// - Parameter transform: A closure that transforms an optional action into a new optional
  ///   action.
  /// - Returns: Button state over a new action.
  public func map<NewAction>(_ transform: (Action?) -> NewAction?) -> ButtonState2<NewAction> {
    ButtonState2<NewAction>(
      id: self.id,
      action: self.action.map(transform),
      label: self.label,
      role: self.role
    )
  }
}

/// A type that wraps an action with additional context, _e.g._ for animation.
public struct ButtonState2Action<Action> {
  public let type: _ActionType

  public static func send(_ action: Action?) -> Self {
    .init(type: .send(action))
  }

  #if canImport(SwiftUI)
    public static func send(_ action: Action?, animation: Animation?) -> Self {
      .init(type: .animatedSend(action, animation: animation))
    }
  #endif

  public var action: Action? {
    switch self.type {
    #if canImport(SwiftUI)
      case let .animatedSend(action, animation: _):
        return action
    #endif
    case let .send(action):
      return action
    }
  }

  public func map<NewAction>(
    _ transform: (Action?) -> NewAction?
  ) -> ButtonState2Action<NewAction> {
    switch self.type {
    #if canImport(SwiftUI)
      case let .animatedSend(action, animation: animation):
        return .send(transform(action), animation: animation)
    #endif
    case let .send(action):
      return .send(transform(action))
    }
  }

  public enum _ActionType {
    case send(Action?)
    #if canImport(SwiftUI)
      case animatedSend(Action?, animation: Animation?)
    #endif
  }
}

/// A value that describes the purpose of a button.
///
/// See `SwiftUI.ButtonRole` for more information.
public enum ButtonState2Role: Sendable {
  /// A role that indicates a cancel button.
  ///
  /// See `SwiftUI.ButtonRole.cancel` for more information.
  case cancel

  /// A role that indicates a destructive button.
  ///
  /// See `SwiftUI.ButtonRole.destructive` for more information.
  case destructive
}

extension ButtonState2: ActionState {}

extension ButtonState2: CustomDumpReflectable {
  public var customDumpMirror: Mirror {
    var children: [(label: String?, value: Any)] = []
    if let role = self.role {
      children.append(("role", role))
    }
    children.append(("action", self.action))
    children.append(("label", self.label))
    return Mirror(
      self,
      children: children,
      displayStyle: .struct
    )
  }
}

extension ButtonState2Action: CustomDumpReflectable {
  public var customDumpMirror: Mirror {
    switch self.type {
    case let .send(action):
      return Mirror(
        self,
        children: [
          "send": action as Any
        ],
        displayStyle: .enum
      )
    #if canImport(SwiftUI)
      case let .animatedSend(action, animation):
        return Mirror(
          self,
          children: [
            "send": (action, animation: animation)
          ],
          displayStyle: .enum
        )
    #endif
    }
  }
}

extension ButtonState2Action: Equatable where Action: Equatable {}
extension ButtonState2Action._ActionType: Equatable where Action: Equatable {}
extension ButtonState2Role: Equatable {}
extension ButtonState2: Equatable where Action: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.action == rhs.action
      && lhs.label == rhs.label
      && lhs.role == rhs.role
  }
}

extension ButtonState2Action: Hashable where Action: Hashable {}
extension ButtonState2Action._ActionType: Hashable where Action: Hashable {
  public func hash(into hasher: inout Hasher) {
    switch self {
    #if canImport(SwiftUI)
      case let .animatedSend(action, animation: _):
        hasher.combine(action)  // TODO: Should we hash the animation?
    #endif
    case let .send(action):
      hasher.combine(action)
    }
  }
}
extension ButtonState2Role: Hashable {}
extension ButtonState2: Hashable where Action: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.action)
    hasher.combine(self.label)
    hasher.combine(self.role)
  }
}

extension ButtonState2Action: Sendable where Action: Sendable {}
extension ButtonState2Action._ActionType: Sendable where Action: Sendable {}
extension ButtonState2: Sendable where Action: Sendable {}

#if canImport(SwiftUI)
  // MARK: - SwiftUI bridging

  extension Alert.Button {
    /// Initializes a `SwiftUI.Alert.Button` from `ButtonState2` and an action handler.
    ///
    /// - Parameters:
    ///   - button: Button state.
    ///   - action: An action closure that is invoked when the button is tapped.
    public init<Action>(_ button: ButtonState2<Action>, action: @escaping (Action?) -> Void) {
      let action = { button.withAction(action) }
      switch button.role {
      case .cancel:
        self = .cancel(Text(button.label), action: action)
      case .destructive:
        self = .destructive(Text(button.label), action: action)
      case .none:
        self = .default(Text(button.label), action: action)
      }
    }

    /// Initializes a `SwiftUI.Alert.Button` from `ButtonState2` and an async action handler.
    ///
    /// > Warning: Async closures cannot be performed with animation. If the underlying action is
    /// > animated, a runtime warning will be emitted.
    ///
    /// - Parameters:
    ///   - button: Button state.
    ///   - action: An action closure that is invoked when the button is tapped.
    public init<Action: Sendable>(
      _ button: ButtonState2<Action>,
      action: @escaping @Sendable (Action?) async -> Void
    ) {
      let action = { _ = Task { await button.withAction(action) } }
      switch button.role {
      case .cancel:
        self = .cancel(Text(button.label), action: action)
      case .destructive:
        self = .destructive(Text(button.label), action: action)
      case .none:
        self = .default(Text(button.label), action: action)
      }
    }
  }

  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  extension ButtonRole {
    public init(_ role: ButtonState2Role) {
      switch role {
      case .cancel:
        self = .cancel
      case .destructive:
        self = .destructive
      }
    }
  }

  extension Button where Label == Text {
    /// Initializes a `SwiftUI.Button` from `ButtonState2` and an async action handler.
    ///
    /// - Parameters:
    ///   - button: Button state.
    ///   - action: An action closure that is invoked when the button is tapped.
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
    #if compiler(>=6)
      @MainActor
    #endif
    public init<Action>(_ button: ButtonState2<Action>, action: @escaping (Action?) -> Void) {
      self.init(
        role: button.role.map(ButtonRole.init),
        action: { button.withAction(action) }
      ) {
        Text(button.label)
      }
    }

    /// Initializes a `SwiftUI.Button` from `ButtonState2` and an action handler.
    ///
    /// > Warning: Async closures cannot be performed with animation. If the underlying action is
    /// > animated, a runtime warning will be emitted.
    ///
    /// - Parameters:
    ///   - button: Button state.
    ///   - action: An action closure that is invoked when the button is tapped.
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
    public init<Action: Sendable>(
      _ button: ButtonState2<Action>,
      action: @escaping @Sendable (Action?) async -> Void
    ) {
      self.init(
        role: button.role.map(ButtonRole.init),
        action: { Task { await button.withAction(action) } }
      ) {
        Text(button.label)
      }
    }
  }
#endif
