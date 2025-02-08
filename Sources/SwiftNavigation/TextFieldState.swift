import CasePaths
import CustomDump
import Foundation
import ConcurrencyExtras
import IssueReporting

#if canImport(SwiftUI)
  import SwiftUI
#endif

public struct TextFieldState<Action>: Identifiable {
  public let id: UUID
  public let initialText: String
  public let action: TextFieldStateAction<Action>
  public let placeholderText: TextState

  init(
    id: UUID,
    initialText: String = "",
    action: TextFieldStateAction<Action>,
    placeholderText: TextState
  ) {
    self.id = id
    self.initialText = initialText
    self.action = action
    self.placeholderText = placeholderText
  }

  /// Creates button state.
  ///
  /// - Parameters:
  ///   - initialText: Initial text for the text field
  ///   - action: The action to send when the user interacts with the button.
  ///   - label: A view that describes the purpose of the button's `action`.
  public init(
    initialText: String = "",
    action: TextFieldStateAction<Action> = .send(nil),
    placeholderText: () -> TextState
  ) {
    self.init(
      id: UUID(),
      initialText: initialText,
      action: action,
      placeholderText: placeholderText()
    )
  }

  /// Creates button state.
  ///
  /// - Parameters:
  ///   - initialText: Initial text for the text field
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
      action: .send2(action, text: initialText),
      placeholderText: placeholderText()
    )
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
    action: Action,
    placeholderText: () -> TextState
  ) {
    self.init(
      id: UUID(),
      initialText: initialText,
      action: .send(action),
      placeholderText: placeholderText()
    )
  }

  /// Handle the button's action in a closure.
  ///
  /// - Parameter perform: Unwraps and passes a button's action to a closure to be performed. If the
  ///   action has an associated animation, the context will be wrapped using SwiftUI's
  ///   `withAnimation`.
  public func withAction(_ perform: (Action?) -> Void, text2: String) {
    switch self.action.type {
    case let .send(action):
      perform(action)

    case let .send2(action, _):
      perform(action.embed(text2))

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
  public func withAction(
    _ perform: @MainActor (Action?) async -> Void,
    text2: String
  ) async {
    switch self.action.type {
    case let .send(action):
      await perform(action)

    case let .send2(action, _):
      await perform(action.embed(text2))

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
  public func map<NewAction>(_ transform: (Action?) -> NewAction?) -> TextFieldState<NewAction> {
    TextFieldState<NewAction>(
      id: self.id,
      action: self.action.map(transform),
      placeholderText: self.placeholderText
    )
  }
}

extension AnyCasePath {
  public func map<Action, NewAction>(
    embed: @Sendable (String) -> Action,
    extract: @Sendable (Action) -> String?,
    transform: @Sendable (Action) -> NewAction,
    pullback: @Sendable (NewAction) -> Action
  ) -> AnyCasePath<NewAction, String> {
    .init(
      embed: { text in
        transform(embed(text))
      },
      extract: { action in
        extract(pullback(action))
      }
    )
  }
}

/// A type that wraps an action with additional context, _e.g._ for animation.
public struct TextFieldStateAction<Action> {
  public let embed: @Sendable (String) -> Action
  public let extract: @Sendable (Action) -> String?
  public let type: _ActionType
  public var text: String

  public static func send2(
    _ action: AnyCasePath<Action, String>,
    text: String
  ) -> Self {
    .init(
      embed: action.embed,
      extract: action.extract,
      type: .send(action.embed(text)),
      text: text
    )
  }

  public static func send(_ action: Action?) -> Self {
    .init(
      type: .send(action),
      text: ""
    )
  }

  #if canImport(SwiftUI)
    public static func send(_ action: Action?, animation: Animation?) -> Self {
      .init(type: .animatedSend(action, animation: animation), text: "")
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

    case let .send2(action, text):
      return action.embed(text)
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

    case let .send2(action, text):
      return .send(transform(action.embed(text)))
    }
  }

  public enum _ActionType {
    case send(Action?)
    case send2(AnyCasePath<Action, String>, String)
    #if canImport(SwiftUI)
      case animatedSend(Action?, animation: Animation?)
    #endif
  }
}

extension TextFieldState: ActionState {}

extension TextFieldState: CustomDumpReflectable {
  public var customDumpMirror: Mirror {
    var children: [(label: String?, value: Any)] = []
    children.append(("initialText", self.initialText))
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

    case let .send2(action, text):
      return Mirror(
        self,
        children: [
          "send": (action, text: text)
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
extension TextFieldStateAction._ActionType: Equatable where Action: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case let (.send(lhs), .send(rhs)):
      lhs == rhs

    case let (
      .send2(lhsAction, lhsText),
      .send2(rhsAction, rhsText)
    ):
      lhsAction.embed(lhsText) == rhsAction.embed(rhsText)

  #if canImport(SwiftUI)
    case let (
      .animatedSend(lhsAction, lhsAnimation),
      .animatedSend(rhsAction, rhsAnimation)
    ):
      lhsAction == rhsAction
        && lhsAnimation == rhsAnimation

    default:
      false
    #endif
    }
  }
}
extension TextFieldState: Equatable where Action: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.initialText == rhs.initialText
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

    case let .send2(action, text):
      hasher.combine(action.embed(text))
    }
  }
}
extension TextFieldState: Hashable where Action: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.initialText)
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
    ) {
      var text = textField.initialText
      self.init(
        text: Binding(
          get: { text },
          set: { newText in
            text = newText
            textField.withAction(action, text2: newText)
          }
        )
      ) {
        Text(textField.placeholderText)
      }
    }

    @available(iOS 16, macOS 13, tvOS 16, watchOS 8, *)
    public init<Action: Sendable>(
      _ textField: TextFieldState<Action>,
      action: @escaping @Sendable (Action?) async -> Void
    ) {
      let text = LockIsolated(textField.initialText)
      self.init(
        text: Binding(
          get: { text.value },
          set: { newText in
            Task {
              text.withValue { $0 = newText }
              await textField.withAction(action, text2: newText)
            }
          }
        )
      ) {
        Text(textField.placeholderText)
      }
    }
  }
#endif
