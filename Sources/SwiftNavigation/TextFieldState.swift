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
  public var text: String
  public var action: (@Sendable (String) -> Action?)?
  public let placeholderText: TextState

  init(
    id: UUID,
    initialText: String = "",
    action: (@Sendable (String) -> Action?)? = nil,
    placeholderText: TextState
  ) {
    self.id = id
    self.initialText = initialText
    self.text = initialText
    self.action = action
    self.placeholderText = placeholderText
  }

  public init(
    initialText: String = "",
    action: (@Sendable (String) -> Action?)? = nil,
    placeholderText: TextState
  ) {
    self.id = UUID()
    self.initialText = initialText
    self.text = initialText
    self.action = action
    self.placeholderText = placeholderText
  }

  ///   action.
  /// - Returns: Button state over a new action.
  public func map<NewAction>(
    _ transform: @escaping @Sendable (Action?) -> NewAction?
  ) -> TextFieldState<NewAction>
  where Action: Sendable {
    TextFieldState<NewAction>(
      id: self.id,
      action: { transform(action?($0)) },
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
    lhs.initialText == rhs.initialText
      && lhs.text == rhs.text
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
    hasher.combine(self.initialText)
    hasher.combine(self.text)
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
      let textField = LockIsolated(textField)
      self.init(
        text: Binding(
          get: { textField.value.text },
          set: { newText in
            textField.withValue { $0.text = newText }
            action(textField.action?(newText))
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
      let textField = LockIsolated(textField)
      self.init(
        text: Binding(
          get: { textField.value.text },
          set: { newText in
            Task {
              textField.withValue { $0.text = newText }
              await action(textField.action?(newText))
            }
          }
        )
      ) {
        Text(textField.placeholderText)
      }
    }
  }
#endif
