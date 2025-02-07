#if canImport(UIKit) && !os(watchOS)
  import UIKit

  @available(iOS 13, *)
  @available(macCatalyst 13, *)
  @available(macOS, unavailable)
  @available(tvOS 13, *)
  @available(watchOS, unavailable)
  extension UIAlertController {
    /// Creates and returns a view controller for displaying an alert using a data description.
    ///
    /// - Parameters:
    ///   - state: A data description of the alert.
    ///   - handler: A closure that is invoked with an action held in `state`.
    public convenience init<Action>(
      state: AlertState<Action>,
      handler: @escaping (_ action: Action?) -> Void = { (_: Never?) in }
    ) {
      self.init(
        title: String(state: state.title),
        message: state.message.map { String(state: $0) },
        preferredStyle: .alert
      )
      for action in state.actions {
        switch action {
        case let .button(buttonState):
          addAction(UIAlertAction(buttonState, action: handler))

        case let .textField(textFieldState):
          addTextField(configurationHandler: { textField in
            let text = textField.text ?? ""
            textFieldState.withAction(handler, text: text)
          })
        }
      }
    }

    /// Creates and returns a view controller for displaying an action sheet using a data
    /// description.
    ///
    /// - Parameters:
    ///   - state: A data description of the alert.
    ///   - handler: A closure that is invoked with an action held in `state`.
    public convenience init<Action>(
      state: ConfirmationDialogState<Action>,
      handler: @escaping (_ action: Action?) -> Void = { (_: Never?) in }
    ) {
      self.init(
        title: state.titleVisibility == .visible ? String(state: state.title) : nil,
        message: state.message.map { String(state: $0) },
        preferredStyle: .actionSheet
      )
      for button in state.buttons {
        addAction(UIAlertAction(button, action: handler))
      }
    }
  }

  @available(iOS 13, *)
  @available(macCatalyst 13, *)
  @available(macOS, unavailable)
  @available(tvOS 13, *)
  @available(watchOS, unavailable)
  extension UIAlertAction.Style {
    public init(_ role: ButtonStateRole) {
      switch role {
      case .cancel:
        self = .cancel
      case .destructive:
        self = .destructive
      }
    }
  }

  @available(iOS 13, *)
  @available(macCatalyst 13, *)
  @available(macOS, unavailable)
  @available(tvOS 13, *)
  @available(watchOS, unavailable)
  extension UIAlertAction {
    public convenience init<Action>(
      _ button: ButtonState<Action>,
      action handler: @escaping (_ action: Action?) -> Void = { (_: Never?) in }
    ) {
      self.init(
        title: String(state: button.label),
        style: button.role.map(UIAlertAction.Style.init) ?? .default
      ) { _ in
        button.withAction(handler)
      }
      if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
        self.accessibilityLabel = button.label.accessibilityLabel.map { String(state: $0) }
      }
    }
  }

  @available(iOS 13, *)
  @available(macCatalyst 13, *)
  @available(macOS, unavailable)
  @available(tvOS 13, *)
  @available(watchOS, unavailable)
  extension UIAlertAction {
    public convenience init<Action>(
      _ state: TextFieldState<Action>,
      textField: UITextField,
      action handler: @escaping (_ action: Action?) -> Void = { (_: Never?) in }
    ) {
      self.init(
        title: String(state: state.placeholderText),
        style: .default
      ) { [weak textField] _ in
        guard let textField else { return }
        state.withAction(handler, text: textField.text ?? "")
      }
      if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
        self.accessibilityLabel = state.placeholderText.accessibilityLabel.map {
          String(state: $0)
        }
      }
    }
  }
#endif
