//
//  KeyboardAccessoryView.swift
//  Tilo
//
//  Custom keyboard accessory bar with dark purple background
//

import SwiftUI
import UIKit

// MARK: - UIKit Integration for Custom Input Accessory
struct KeyboardAccessoryTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""
    var font: UIFont = .systemFont(ofSize: 22, weight: .semibold)
    var textColor: UIColor = .white
    var keyboardType: UIKeyboardType = .decimalPad
    var textAlignment: NSTextAlignment = .right
    var onEditingChanged: ((Bool) -> Void)?
    var onCommit: (() -> Void)?
    @Binding var isFirstResponder: Bool
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.font = font
        textField.textColor = textColor
        textField.keyboardType = keyboardType
        textField.textAlignment = textAlignment
        textField.tintColor = .white
        textField.backgroundColor = .clear
        textField.placeholder = placeholder
        
        // Create custom accessory view
        let accessoryView = createAccessoryView(context: context)
        textField.inputAccessoryView = accessoryView
        
        // Store reference for focus management
        context.coordinator.textField = textField
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        // Update text only if different to avoid cursor jumping
        if uiView.text != text {
            uiView.text = text
        }
        
        // Only handle becoming first responder - don't explicitly resign
        // Resigning happens automatically when another field becomes first responder
        // This keeps the keyboard open during switches
        if isFirstResponder && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        }
    }
    
    private func createAccessoryView(context: Context) -> UIView {
        // Dark purple background color - matching app theme
        let darkPurple = UIColor(red: 0.08, green: 0.05, blue: 0.14, alpha: 1.0)
        
        // Container that extends beyond to cover keyboard rounded corners
        let container = UIView()
        container.backgroundColor = darkPurple
        // Extra height to cover the gap from keyboard rounded corners
        container.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 60)
        
        // Add a bottom extension to cover keyboard corner gaps
        let bottomExtension = UIView()
        bottomExtension.backgroundColor = darkPurple
        container.addSubview(bottomExtension)
        bottomExtension.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomExtension.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bottomExtension.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomExtension.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bottomExtension.heightAnchor.constraint(equalToConstant: 12)
        ])
        
        // Done button - darker purple with white text
        let buttonPurple = UIColor(red: 0.30, green: 0.15, blue: 0.50, alpha: 1.0)
        
        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.backgroundColor = buttonPurple
        doneButton.layer.cornerRadius = 18
        doneButton.addTarget(context.coordinator, action: #selector(Coordinator.doneTapped), for: .touchUpInside)
        
        container.addSubview(doneButton)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            doneButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            doneButton.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            doneButton.heightAnchor.constraint(equalToConstant: 36),
            doneButton.widthAnchor.constraint(equalToConstant: 80)
        ])
        
        return container
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: KeyboardAccessoryTextField
        weak var textField: UITextField?
        var isDismissingExplicitly = false // Track explicit dismissals vs focus transfers
        
        init(_ parent: KeyboardAccessoryTextField) {
            self.parent = parent
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            isDismissingExplicitly = false
            DispatchQueue.main.async {
                self.parent.isFirstResponder = true
            }
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.parent.isFirstResponder = false
            }
            // Only notify parent if this was an explicit dismiss (Done button)
            // Not when focus transferred to another text field
            if isDismissingExplicitly {
                parent.onEditingChanged?(false)
            }
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            if let currentText = textField.text,
               let textRange = Range(range, in: currentText) {
                let updatedText = currentText.replacingCharacters(in: textRange, with: string)
                DispatchQueue.main.async {
                    self.parent.text = updatedText
                }
            }
            return true
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            isDismissingExplicitly = true
            textField.resignFirstResponder()
            parent.onCommit?()
            return true
        }
        
        @objc func doneTapped() {
            isDismissingExplicitly = true
            textField?.resignFirstResponder()
            parent.onCommit?()
        }
    }
}
