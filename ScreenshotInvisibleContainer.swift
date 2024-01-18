//
//  ScreenshotInvisibleContainer.swift
//  
//
//  Created by Князьков Илья on 01.03.2022.
//

import UIKit

@objc
public class ScreenshotInvisibleContainer: UITextField {

    // MARK: - Private Properties

    private let hiddenContainerRecognizer = HiddenContainerRecognizer()

    @objc
    public var hiddenContainer: UIView? {
        try? hiddenContainerRecognizer.getHiddenContainer(from: self)
    }

    // MARK: - Internal Properties

    /// - View, which will be hidden on screenshots and screen recording
    private(set) var content: UIView

    // MARK: - Initialization
    
    @objc
    public init(content: UIView) {
        self.content = content
        super.init(frame: .zero)
        setupInitialState()
    }
    
    @objc
    public required init?(coder: NSCoder) {
        self.content = UIView()
        super.init(coder: coder)
        setupInitialState()
    }

    // MARK: - UIView

    override public var canBecomeFocused: Bool {
        false
    }

    override public var canBecomeFirstResponder: Bool {
        false
    }
    
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return hiddenContainer?.hitTest(point, with: event)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        isUserInteractionEnabled = content.isUserInteractionEnabled
    }
    
    // MARK: - Private methods
    
    private func setupInitialState() {
        appendContent(to: hiddenContainer)

        backgroundColor = .clear
        isUserInteractionEnabled = content.isUserInteractionEnabled
    }
    
    private func activateLayoutConstraintsOfContent(to view: UIView) {
        [
            content.topAnchor.constraint(equalTo: view.topAnchor),
            content.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            content.leftAnchor.constraint(equalTo: view.leftAnchor),
            content.rightAnchor.constraint(equalTo: view.rightAnchor)
        ].forEach { $0.isActive = true }
    }
    
    private func appendContent(to view: UIView?) {
        guard let view = view else {
            return
        }
        view.addSubview(content)
        view.isUserInteractionEnabled = true
        content.translatesAutoresizingMaskIntoConstraints = false
        activateLayoutConstraintsOfContent(to: view)
    }
    
}

// MARK: - ScreenshotInvisibleContainerProtocol

@objc
extension ScreenshotInvisibleContainer: ScreenshotInvisibleContainerProtocol {
    
    @objc
    public func eraseOldAndAddNewContent(_ newContent: UIView) {
        content.removeFromSuperview()
        content = newContent
        appendContent(to: hiddenContainer)
    }
    
    @objc
    public func setupContainerAsHideContentInScreenshots() {
        isSecureTextEntry = true
    }
    
    @objc
    public func setupContainerAsDisplayContentInScreenshots() {
        isSecureTextEntry = false
    }
    
}
