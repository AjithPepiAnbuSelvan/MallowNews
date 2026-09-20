//
//  ArticleCardCell.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 21/09/26.
//

import UIKit

final class ArticleCardCell: UICollectionViewCell {
	
	static let reuseIdentifier = "ArticleCardCell"
	
	private let thumbnailImageView = UIImageView()
	private let sourceLabel = UILabel()
	private let titleLabel = UILabel()
	private let dateLabel = UILabel()
	private let imageActivityIndicator = UIActivityIndicatorView(style: .medium)
	
	private var imageTask: Task<Void, Never>?
	private var representedArticleID: Int?
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		backgroundColor = .clear
		
		contentView.backgroundColor = .systemBackground
		contentView.layer.cornerRadius = 16
		contentView.layer.cornerCurve = .continuous
		contentView.clipsToBounds = true
		
		thumbnailImageView.backgroundColor = .tertiarySystemFill
		thumbnailImageView.contentMode = .scaleAspectFill
		thumbnailImageView.clipsToBounds = true
		thumbnailImageView.layer.cornerRadius = 8
		imageActivityIndicator.hidesWhenStopped = true
		imageActivityIndicator.color = .secondaryLabel
		
		sourceLabel.font = .preferredFont(forTextStyle: .caption1)
		sourceLabel.adjustsFontForContentSizeCategory = true
		sourceLabel.textColor = .secondaryLabel
		
        let font = UIFont.systemFont(ofSize: 17, weight: .semibold)
		titleLabel.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: UIFont(descriptor: font.fontDescriptor.withDesign(.rounded) ?? font.fontDescriptor, size: 17))
		titleLabel.adjustsFontForContentSizeCategory = true
		titleLabel.numberOfLines = 0
		
		dateLabel.font = .preferredFont(forTextStyle: .caption2)
		dateLabel.adjustsFontForContentSizeCategory = true
		dateLabel.textColor = .secondaryLabel
		
		let textStack = UIStackView(
			arrangedSubviews: [sourceLabel, titleLabel, dateLabel]
		)
		
		textStack.axis = .vertical
		textStack.spacing = 6
		textStack.alignment = .leading
		
		let stack = UIStackView(
			arrangedSubviews: [textStack, thumbnailImageView]
		)
		
		stack.axis = .horizontal
		stack.spacing = 14
		stack.alignment = .center
		
		contentView.addSubview(stack)
		thumbnailImageView.addSubview(imageActivityIndicator)
		
		stack.translatesAutoresizingMaskIntoConstraints = false
		thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
		imageActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
		
        // UIKit temporarily imposes its estimated height before self-sizing.
        // Let this inset yield during that pass, keeping the image intact.
        let bottomInset = stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14)
        bottomInset.priority = UILayoutPriority(999)
		NSLayoutConstraint.activate([
			stack.topAnchor.constraint(
				equalTo: contentView.topAnchor,
				constant: 16
			),
			stack.leadingAnchor.constraint(
				equalTo: contentView.leadingAnchor,
				constant: 16
			),
			stack.trailingAnchor.constraint(
				equalTo: contentView.trailingAnchor,
				constant: -16
			),
            bottomInset,
			
			thumbnailImageView.widthAnchor.constraint(equalToConstant: 92),
			thumbnailImageView.heightAnchor.constraint(equalToConstant: 88),
			imageActivityIndicator.centerXAnchor.constraint(equalTo: thumbnailImageView.centerXAnchor),
			imageActivityIndicator.centerYAnchor.constraint(equalTo: thumbnailImageView.centerYAnchor)
		])
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func configure(with article: Article) {
		representedArticleID = article.id
		
		sourceLabel.text = article.newsSite.uppercased()
        sourceLabel.textColor = tintColor
		titleLabel.text = article.title
		
		let formatter = DateFormatter()
		formatter.dateFormat = "MMM d, yyyy"
		dateLabel.text = formatter.string(from: article.publishedAt)
		
		loadImage(from: article.imageURL, articleID: article.id)
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		imageTask?.cancel()
		imageTask = nil
		representedArticleID = nil
		
		thumbnailImageView.image = nil
		thumbnailImageView.backgroundColor = .tertiarySystemFill
		imageActivityIndicator.stopAnimating()
	}
	
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
		thumbnailImageView.contentMode = .center
		thumbnailImageView.image = UIImage(systemName: "photo", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .regular))
		thumbnailImageView.tintColor = .tertiaryLabel
		imageActivityIndicator.stopAnimating()
	}
}
