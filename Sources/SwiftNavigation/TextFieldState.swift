import CasePaths
import CustomDump
import Foundation
import ConcurrencyExtras
import IssueReporting

#if canImport(SwiftUI)
  import SwiftUI
#endif

public protocol TextFieldAction {
  static func defaultValue(_ string: String) -> Self
}

public struct TextFieldState<Action>: Identifiable {
  public let id: UUID
  public var text: String
  public var action: Action?
  public let placeholderText: TextState

  init(
    id: UUID,
    initialText: String = "",
    action: Action?,
    placeholderText: TextState
  ) {
    self.id = id
    self.text = initialText
    self.action = action
    self.placeholderText = placeholderText
  }

  /// Creates button state.
  ///
  /// - Parameters:
  ///   - role: An optional semantic role that describes the button. A value of `nil` means that the
  ///     button doesn't have an assigned role.
  ///   - action: The action to send when the user interacts with the button.
  ///   - label: A view that describes the purpose of the button's `action`.
  public init(
    initialText: String = "",
    action: AnyCasePath<Action, String>,
    placeholderText: () -> TextState
  ) {
    self.init(
      id: UUID(),
      initialText: initialText,
      action: action.embed(initialText),
      placeholderText: placeholderText()
    )
  }

  /// Handle the button's action in a closure.
  ///
  /// - Parameter perform: Unwraps and passes a button's action to a closure to be performed. If the
  ///   action has an associated animation, the context will be wrapped using SwiftUI's
  ///   `withAnimation`.
  public func withAction(_ perform: (Action?) -> Void)
  where Action: TextFieldAction {
    perform(AnyCasePath(Action.defaultValue).embed(text))
  }

  /// Handle the button's action in an async closure.
  ///
  /// > Warning: Async closures cannot be performed with animation. If the underlying action is
  /// > animated, a runtime warning will be emitted.
  ///
  /// - Parameter perform: Unwraps and passes a button's action to a closure to be performed.
  @MainActor
  public func withAction(_ perform: @MainActor (Action?) async -> Void) async
  where Action: TextFieldAction {
    await perform(AnyCasePath(Action.defaultValue).embed(text))
  }

  /// Transforms a button state's action into a new action.
  ///
  /// - Parameter transform: A closure that transforms an optional action into a new optional
  ///   action.
  /// - Returns: Button state over a new action.
  public func map<NewAction>(
    _ transform: (Action?) -> NewAction?
  ) -> TextFieldState<NewAction> {
    TextFieldState<NewAction>(
      id: self.id,
      action: transform(self.action),
      placeholderText: self.placeholderText
    )
  }
}

/// A type that wraps an action with additional context, _e.g._ for animation.
public struct TextFieldStateAction<Action> {
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
  ) -> TextFieldStateAction<NewAction> {
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

extension TextFieldState: ActionState {}

extension TextFieldState: CustomDumpReflectable {
  public var customDumpMirror: Mirror {
    var children: [(label: String?, value: Any)] = []
    children.append(("text", self.text))
    children.append(("action", self.action))
    children.append(("placeholderText", self.placeholderText))
    return Mirror(
      self,
      children: children,
      displayStyle: .struct
    )
  }
}

extension TextFieldStateAction: CustomDumpReflectable {
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

extension TextFieldStateAction: Equatable where Action: Equatable {}
extension TextFieldStateAction._ActionType: Equatable where Action: Equatable {}
extension TextFieldState: Equatable where Action: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.text == rhs.text
      && lhs.action == rhs.action
      && lhs.placeholderText == rhs.placeholderText
  }
}

extension TextFieldStateAction: Hashable where Action: Hashable {}
extension TextFieldStateAction._ActionType: Hashable where Action: Hashable {
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
extension TextFieldState: Hashable where Action: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.text)
    hasher.combine(self.action)
    hasher.combine(self.placeholderText)
  }
}

extension TextFieldStateAction: Sendable where Action: Sendable {}
extension TextFieldStateAction._ActionType: Sendable where Action: Sendable {}
extension TextFieldState: Sendable where Action: Sendable {}

#if canImport(SwiftUI)
  // MARK: - SwiftUI bridging

  extension TextField where Label == Text {
    @available(iOS 16, macOS 13, tvOS 16, watchOS 8, *)
    #if compiler(>=6)
      @MainActor
    #endif
    public init<Action: Sendable>(
      _ textField: TextFieldState<Action>,
      action: @escaping (Action?) -> Void
    ) where Action: TextFieldAction {
      var textField = textField
      self.init(
        text: Binding(
          get: { textField.text },
          set: { newText in
            textField.text = newText
            textField.withAction(action)
          }
        )
      ) {
        Text(textField.placeholderText)
      }
    }

    @available(iOS 16, macOS 13, tvOS 16, watchOS 8, *)
    @MainActor
    public init<Action: Sendable>(
      _ textField: TextFieldState<Action>,
      action: @escaping @Sendable (Action?) async -> Void
    ) where Action: TextFieldAction {
      var textField = textField
      self.init(
        text: Binding(
          get: { textField.text },
          set: { newText in
            textField.text = newText
//            textField.withAction(action)
          }
        )
      ) {
        Text(textField.placeholderText)
      }
    }
  }
#endif
