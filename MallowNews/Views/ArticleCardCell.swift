//
//  ArticleCardCell.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 21/09/26.
//

import UIKit

final class ArticleCardCell: UICollectionViewCell {
	// MARK: - Reuse Identifier

	static let reuseIdentifier = "ArticleCardCell"

	// MARK: - UI Components

	private let thumbnailImageView = UIImageView()
	private let sourceLabel = UILabel()
	private let titleLabel = UILabel()
	private let dateLabel = UILabel()
	private let excerptLabel = UILabel()
	private let imageActivityIndicator = UIActivityIndicatorView(style: .medium)
	private let stack = UIStackView()

	// MARK: - Properties

	private var imageTask: Task<Void, Never>?
	private var representedArticleID: Int?
	private var thumbnailWidthConstraint: NSLayoutConstraint!

	// MARK: - Initialization

	override init(frame: CGRect) {
		super.init(frame: frame)
		
		backgroundColor = .clear
		
		contentView.backgroundColor = .clear
		
		thumbnailImageView.backgroundColor = .tertiarySystemFill
		thumbnailImageView.contentMode = .scaleAspectFill
		thumbnailImageView.clipsToBounds = true
		thumbnailImageView.layer.cornerRadius = 8
		imageActivityIndicator.hidesWhenStopped = true
		imageActivityIndicator.color = .secondaryLabel
		
		sourceLabel.font = .systemFont(ofSize: 11, weight: .bold)
		sourceLabel.adjustsFontForContentSizeCategory = true
		sourceLabel.textColor = .secondaryLabel
		
        let font = UIFont.systemFont(ofSize: 17, weight: .semibold)
		titleLabel.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: UIFont(descriptor: font.fontDescriptor.withDesign(.rounded) ?? font.fontDescriptor, size: 17))
		titleLabel.adjustsFontForContentSizeCategory = true
		titleLabel.numberOfLines = 0
		
		dateLabel.font = .preferredFont(forTextStyle: .caption2)
		dateLabel.adjustsFontForContentSizeCategory = true
		dateLabel.textColor = .secondaryLabel

		excerptLabel.font = .preferredFont(forTextStyle: .subheadline)
		excerptLabel.textColor = .secondaryLabel
		excerptLabel.numberOfLines = 2
		
		let textStack = UIStackView(
			arrangedSubviews: [sourceLabel, titleLabel, excerptLabel, dateLabel]
		)
		
		textStack.axis = .vertical
		textStack.spacing = 6
		textStack.alignment = .leading
		
		stack.addArrangedSubview(textStack)
		stack.addArrangedSubview(thumbnailImageView)
		stack.axis = .horizontal
		stack.spacing = FeedStyle.rowSpacing
		stack.alignment = .center
		
		contentView.addSubview(stack)
		thumbnailImageView.addSubview(imageActivityIndicator)
		
		stack.translatesAutoresizingMaskIntoConstraints = false
		thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
		imageActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
		
        // Lower priority allows the constraint to yield during UIKit's initial estimated-height pass, avoiding layout warnings.
        let bottomInset = stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14)
        bottomInset.priority = UILayoutPriority(999)
		NSLayoutConstraint.activate([
			stack.topAnchor.constraint( equalTo: contentView.topAnchor, constant: FeedStyle.contentInset),
			stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: FeedStyle.contentInset),
			stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -FeedStyle.contentInset),
            bottomInset,
			thumbnailImageView.heightAnchor.constraint(equalToConstant: 88),
			imageActivityIndicator.centerXAnchor.constraint(equalTo: thumbnailImageView.centerXAnchor),
			imageActivityIndicator.centerYAnchor.constraint(equalTo: thumbnailImageView.centerYAnchor)
		])
		thumbnailWidthConstraint = thumbnailImageView.widthAnchor.constraint(equalToConstant: 92)
		thumbnailWidthConstraint.isActive = true
		let separator = UIView()
		separator.backgroundColor = .separator
		contentView.addSubview(separator)
		separator.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
			separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
			separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
			separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
		])
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Lifecycle / Cell Reuse

	override func prepareForReuse() {
		super.prepareForReuse()
		
		// Cancel in-flight image tasks to prevent recycled cells from displaying incorrect images.
		imageTask?.cancel()
		imageTask = nil
		representedArticleID = nil
		
		thumbnailImageView.image = nil
		thumbnailImageView.backgroundColor = .tertiarySystemFill
		thumbnailWidthConstraint.constant = 92
		thumbnailImageView.isHidden = false
		imageActivityIndicator.stopAnimating()
	}

	// MARK: - Configuration

	func configure(with article: Article) {
		representedArticleID = article.id
		
		sourceLabel.attributedText = FeedStyle.trackedSource(article.newsSite, color: tintColor)
		titleLabel.text = article.title
		excerptLabel.text = article.summary.trimmingCharacters(in: .whitespacesAndNewlines)
		dateLabel.text = "\(article.publishedAt.relativeDescription)"
		thumbnailWidthConstraint.constant = 92
		thumbnailImageView.isHidden = false
		stack.spacing = FeedStyle.rowSpacing
		
		loadImage(from: article.imageURL, articleID: article.id)
	}

	// MARK: - Image Loading

	private func loadImage(from url: URL?, articleID: Int) {
		imageTask?.cancel()
		thumbnailImageView.contentMode = .scaleAspectFill
		thumbnailImageView.image = nil
		thumbnailImageView.backgroundColor = .tertiarySystemFill
		imageActivityIndicator.startAnimating()
		
		guard let url else {
			showImageFallback()
			return
		}
		
		imageTask = Task { [weak self] in
			do {
				let image = try await ImageLoader.shared.image(from: url)
				
				guard !Task.isCancelled,
					 self?.representedArticleID == articleID else {
					return
				}
				
				self?.thumbnailImageView.image = image
				self?.thumbnailImageView.backgroundColor = .clear
				self?.imageActivityIndicator.stopAnimating()
				
			} catch {
				guard !Task.isCancelled,
					 self?.representedArticleID == articleID else {
					return
				}
				
				self?.showImageFallback()
			}
		}
	}
	
	private func showImageFallback() {
		thumbnailImageView.image = nil
		thumbnailWidthConstraint.constant = 0
		thumbnailImageView.isHidden = true
		stack.spacing = 0
		imageActivityIndicator.stopAnimating()
	}
}
