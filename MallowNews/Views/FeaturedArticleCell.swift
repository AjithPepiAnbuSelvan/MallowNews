//
//  FeaturedArticleCell.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 21/09/26.
//

import UIKit

final class FeaturedArticleCell: UICollectionViewCell {
    // MARK: - Reuse Identifier
    static let reuseIdentifier = "FeaturedArticleCell"

    // MARK: - UI Components
    private let photo = UIImageView()
    private let badge = UILabel()
    private let source = UILabel()
    private let headline = UILabel()
    private let metadata = UILabel()

    // MARK: - Properties
    private var imageTask: Task<Void, Never>?
    private var requestID = UUID()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 20
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true
        photo.contentMode = .scaleAspectFill
        photo.clipsToBounds = true
        photo.layer.cornerRadius = 12
        photo.backgroundColor = .secondarySystemBackground
        badge.text = "FEATURED"
        badge.font = .preferredFont(forTextStyle: .caption1)
        badge.textColor = .systemPurple
        let font = UIFont.systemFont(ofSize: 25, weight: .bold)
        headline.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: UIFont(descriptor: font.fontDescriptor.withDesign(.rounded) ?? font.fontDescriptor, size: 25))
        headline.numberOfLines = 0
        headline.textColor = .label
        metadata.font = .preferredFont(forTextStyle: .caption1)
        metadata.numberOfLines = 0
        metadata.textColor = .secondaryLabel
        source.font = .preferredFont(forTextStyle: .caption1)
        source.numberOfLines = 0
        [source, badge, headline, metadata].forEach { $0.adjustsFontForContentSizeCategory = true }
        let text = UIStackView(arrangedSubviews: [photo, source, badge, headline, metadata])
        text.axis = .vertical
        text.spacing = 10
        text.setCustomSpacing(16, after: photo)
        contentView.addSubview(text)
        photo.translatesAutoresizingMaskIntoConstraints = false
        text.translatesAutoresizingMaskIntoConstraints = false
        let bottom = text.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18)
        bottom.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            photo.heightAnchor.constraint(equalTo: photo.widthAnchor, multiplier: 0.58),
            text.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            text.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            text.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bottom
        ])
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Configuration
    func configure(with article: Article) {
        // Cancel existing image task to ensure slow responses don't overwrite current cell content.
        imageTask?.cancel()
        requestID = UUID()
        let token = requestID
        photo.image = nil
        badge.isHidden = !article.featured
        source.attributedText = FeedStyle.trackedSource(article.newsSite, color: tintColor)
        badge.textColor = tintColor
        headline.text = article.title
        metadata.text = article.publishedAt.formatted(date: .abbreviated, time: .omitted)
        accessibilityLabel = [badge.isHidden ? nil : badge.text, article.newsSite, headline.text, metadata.text].compactMap { $0 }.joined(separator: ", ")
        guard let url = article.imageURL else { showImageFallback(); return }
        imageTask = Task { [weak self] in
            guard let image = try? await ImageLoader.shared.image(from: url), !Task.isCancelled,
                  let self, self.requestID == token else { return }
            self.photo.image = image
        }
    }

    // MARK: - Helpers
    private func showImageFallback() {
        photo.contentMode = .center
        photo.tintColor = .tertiaryLabel
        photo.image = UIImage(systemName: "photo", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .regular))
    }

    // MARK: - Lifecycle / Cell Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        requestID = UUID()
        photo.image = nil
        photo.contentMode = .scaleAspectFill
    }

    // MARK: - Deinitialization
    deinit {
	    imageTask?.cancel()
    }
}
