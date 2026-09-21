//
//  PaginationFooterView.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 21/09/26.
//


import UIKit

final class PaginationFooterView: UICollectionReusableView {
    // MARK: - Reuse Identifier

    static let reuseIdentifier = "PaginationFooterView"

    // MARK: - Callbacks

    var onRetry: (() -> Void)?

    // MARK: - UI Components

    private let indicator = UIActivityIndicatorView(style: .medium)
    private let label = UILabel()
    private let retryButton = UIButton(type: .system)

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = .preferredFont(forTextStyle: .footnote); label.textColor = .secondaryLabel
        retryButton.configuration = .tinted(); retryButton.configuration?.title = "Try again"
        retryButton.addTarget(self, action: #selector(retry), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [indicator, label, retryButton]); stack.spacing = 8; stack.alignment = .center
        addSubview(stack); stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([stack.centerXAnchor.constraint(equalTo: centerXAnchor), stack.centerYAnchor.constraint(equalTo: centerYAnchor)])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Configuration

    func configure(isLoading: Bool, error: String?) {
        indicator.isHidden = !isLoading
        isLoading ? indicator.startAnimating() : indicator.stopAnimating()
        label.text = isLoading ? "Loading more stories" : (error == nil ? nil : "Couldn’t load more")
        retryButton.isHidden = error == nil || isLoading
    }

    // MARK: - Actions

    @objc private func retry() { onRetry?() }
}
