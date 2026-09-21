//
//  ArticleDetailViewController.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 21/09/26.
//

import SafariServices
import UIKit

final class ArticleDetailViewController: UIViewController {
// MARK: - Properties
	
	private let articles: [Article]
	private let service: NewsService
	private var detailViewModel: ArticleDetailViewModel
	private var index: Int
	private var article: Article { articles[index] }
	
// MARK: - UI Components
	
	private let scrollView = UIScrollView()
	private let surface = UIView()
	private let imageView = UIImageView()
	private let imageActivity = UIActivityIndicatorView(style: .large)
	private let sourceLabel = UILabel()
	private let titleLabel = UILabel()
	private let metadataLabel = UILabel()
	private let summaryLabel = UILabel()
	private let readButton = UIButton(type: .system)
	private let positionLabel = UILabel()
	private let takeawaysTitle = UILabel()
	private let takeawaysLabel = UILabel()
	private let bookmarkButton = UIBarButtonItem()
	
// MARK: - Reader State & Async Tasks
	
	private var readerScale: CGFloat = UserDefaults.standard.object(forKey: "reader-scale") as? CGFloat ?? 1
	private var imageTask: Task<Void, Never>?
	private var detailTask: Task<Void, Never>?
	private var imageRequestID = UUID()
	
// MARK: - Initialization
	
	init(articles: [Article], index: Int, service: NewsService = NetworkManager.shared) {
		self.articles = articles; self.index = index; self.service = service; self.detailViewModel = ArticleDetailViewModel(article: articles[index], service: service)
		super.init(nibName: nil, bundle: nil)
	}
	required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
	
	private var brand: UIColor { AppTheme.brand }
	
// MARK: - Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = AppTheme.background
		view.tintColor = brand
		bookmarkButton.target = self
		bookmarkButton.action = #selector(toggleBookmark)
		navigationItem.rightBarButtonItems = [
			UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareArticle)),
			bookmarkButton,
			makeTextSizeMenu()
		]
		setupViews()
		let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(showNext))
		swipeLeft.direction = .left
		let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(showPrevious))
		swipeRight.direction = .right
		view.addGestureRecognizer(swipeLeft)
		view.addGestureRecognizer(swipeRight)
		renderArticle()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		navigationController?.setNavigationBarHidden(false, animated: animated)
		navigationController?.navigationBar.tintColor = brand
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		if isMovingFromParent { navigationController?.setNavigationBarHidden(true, animated: animated) }
	}
	
// MARK: - Setup
	
	private func setupViews() {
		surface.backgroundColor = .systemBackground
		surface.layer.cornerRadius = 24; surface.layer.cornerCurve = .continuous
		imageView.backgroundColor = .secondarySystemBackground
		imageView.contentMode = .scaleAspectFill; imageView.clipsToBounds = true; imageView.layer.cornerRadius = 16
		imageActivity.hidesWhenStopped = true; imageActivity.color = brand
		sourceLabel.font = .preferredFont(forTextStyle: .caption1); sourceLabel.textColor = brand
		sourceLabel.adjustsFontForContentSizeCategory = true
		let font = UIFont.systemFont(ofSize: 27, weight: .bold)
		titleLabel.font = UIFontMetrics(forTextStyle: .title1).scaledFont(for: UIFont(descriptor: font.fontDescriptor.withDesign(.rounded) ?? font.fontDescriptor, size: 27))
		titleLabel.adjustsFontForContentSizeCategory = true; titleLabel.numberOfLines = 0
		metadataLabel.font = .preferredFont(forTextStyle: .subheadline); metadataLabel.textColor = .secondaryLabel; metadataLabel.numberOfLines = 0
		summaryLabel.numberOfLines = 0
		takeawaysTitle.text = "What to know"
		takeawaysTitle.font = .preferredFont(forTextStyle: .headline)
		takeawaysLabel.font = .preferredFont(forTextStyle: .subheadline)
		takeawaysLabel.textColor = .secondaryLabel
		takeawaysLabel.numberOfLines = 0
		readButton.configuration = .filled(); readButton.configuration?.title = "Read original story"; readButton.configuration?.baseBackgroundColor = brand; readButton.configuration?.cornerStyle = .large
		readButton.addTarget(self, action: #selector(openOriginal), for: .touchUpInside)
		positionLabel.font = .preferredFont(forTextStyle: .caption1); positionLabel.textColor = .secondaryLabel; positionLabel.textAlignment = .center; positionLabel.numberOfLines = 0;
		let stack = UIStackView(arrangedSubviews: [imageView, sourceLabel, titleLabel, metadataLabel, takeawaysTitle, takeawaysLabel, summaryLabel, readButton, positionLabel])
		stack.axis = .vertical; stack.spacing = 16; stack.setCustomSpacing(22, after: metadataLabel); stack.setCustomSpacing(24, after: summaryLabel)
		scrollView.delegate = self
		view.addSubview(scrollView); scrollView.addSubview(surface); surface.addSubview(stack); imageView.addSubview(imageActivity)
		[scrollView, surface, stack, imageView, imageActivity].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
		NSLayoutConstraint.activate([
			scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor), scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor), scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			surface.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16), surface.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16), surface.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16), surface.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -28),
			stack.topAnchor.constraint(equalTo: surface.topAnchor, constant: 16), stack.leadingAnchor.constraint(equalTo: surface.leadingAnchor, constant: 16), stack.trailingAnchor.constraint(equalTo: surface.trailingAnchor, constant: -16), stack.bottomAnchor.constraint(equalTo: surface.bottomAnchor, constant: -20),
			imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.62), imageActivity.centerXAnchor.constraint(equalTo: imageView.centerXAnchor), imageActivity.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
		])
	}
	
// MARK: - Rendering
	
	private func renderArticle() {
			// Cancel in-flight image and detail tasks to prevent stale asynchronous results overwriting current story.
		imageTask?.cancel(); detailTask?.cancel(); imageRequestID = UUID()
		let requestID = imageRequestID; let current = article
		title = current.newsSite; sourceLabel.text = current.newsSite.uppercased(); titleLabel.text = current.title; summaryLabel.text = current.summary
		takeawaysLabel.text = "• \(current.newsSite) published this update\n• \(current.publishedAt.relativeDescription)\n• Open the original story for the complete report"
		positionLabel.text = "\(index + 1) of \(articles.count) \n· Swipe for the next story"
		metadataLabel.text = metadataText(for: current); scrollView.setContentOffset(.zero, animated: false)
		updateReaderScale()
		updateBookmarkButton()
		imageView.image = nil; imageView.contentMode = .scaleAspectFill; imageView.backgroundColor = .secondarySystemBackground; imageActivity.startAnimating()
		guard let url = current.imageURL else { showImageFallback(); return }
		imageTask = Task { [weak self] in
			guard let image = try? await ImageLoader.shared.image(from: url), !Task.isCancelled, let self, self.imageRequestID == requestID else { return }
			self.imageView.image = image; self.imageView.backgroundColor = .clear; self.imageActivity.stopAnimating()
		}
		detailTask = Task { [weak self] in
			guard let self else { return }
			let id = current.id
			let detail = await detailViewModel.loadDetail()
			guard !Task.isCancelled,
				 self.article.id == id else { return }
			self.summaryLabel.text = detail.summary
			self.metadataLabel.text = self.metadataText(for: detail)
		}
	}
	
	private func metadataText(for article: Article) -> String {
		let author = article.authors.map(\.name).joined(separator: ", ")
		var metadata = (author.isEmpty ? article.newsSite : author) + " · " + article.publishedAt.formatted(date: .abbreviated, time: .shortened)
		if article.updatedAt > article.publishedAt { metadata += "\nUpdated " + article.updatedAt.formatted(date: .abbreviated, time: .shortened) }
		return metadata
	}
	
	private func showImageFallback() { imageView.contentMode = .center; imageView.tintColor = .tertiaryLabel; imageView.image = UIImage(systemName: "photo", withConfiguration: UIImage.SymbolConfiguration(pointSize: 32)); imageView.accessibilityLabel = "Article image unavailable"; imageActivity.stopAnimating() }
	
// MARK: - Actions
	
	@objc private func openOriginal() { present(SFSafariViewController(url: article.url), animated: true) }
	@objc private func shareArticle() { let controller = UIActivityViewController(activityItems: [article.title, article.url], applicationActivities: nil); controller.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem; present(controller, animated: true) }
	@objc private func toggleBookmark() { BookmarkStore.shared.toggle(article); UIImpactFeedbackGenerator(style: .light).impactOccurred(); updateBookmarkButton() }
	private func updateBookmarkButton() { bookmarkButton.image = UIImage(systemName: BookmarkStore.shared.contains(article) ? "bookmark.fill" : "bookmark") }
	
// MARK: - Reader Scale
	
	private func makeTextSizeMenu() -> UIBarButtonItem {
		let item = UIBarButtonItem(image: UIImage(systemName: "textformat.size"), style: .plain, target: nil, action: nil)
		item.menu = UIMenu(children: [
			UIAction(title: "Smaller text") { [weak self] _ in self?.setReaderScale(0.9) },
			UIAction(title: "Default text") { [weak self] _ in self?.setReaderScale(1) },
			UIAction(title: "Larger text") { [weak self] _ in self?.setReaderScale(1.15) }
		])
		return item
	}
	private func setReaderScale(_ scale: CGFloat) { readerScale = scale; UserDefaults.standard.set(scale, forKey: "reader-scale"); updateReaderScale() }
	private func updateReaderScale() {
		summaryLabel.font = UIFont.preferredFont(forTextStyle: .body).withSize(UIFont.preferredFont(forTextStyle: .body).pointSize * readerScale)
		takeawaysLabel.font = UIFont.preferredFont(forTextStyle: .subheadline).withSize(UIFont.preferredFont(forTextStyle: .subheadline).pointSize * readerScale)
	}
	
// MARK: - Navigation
	
	@objc private func showNext() { navigate(to: index + 1) }
	@objc private func showPrevious() { navigate(to: index - 1) }
	private func navigate(to newIndex: Int) { guard articles.indices.contains(newIndex) else { UINotificationFeedbackGenerator().notificationOccurred(.warning); return }; index = newIndex; detailViewModel = ArticleDetailViewModel(article: article, service: service); UIImpactFeedbackGenerator(style: .light).impactOccurred(); UIView.transition(with: view, duration: 0.22, options: .transitionCrossDissolve) { self.renderArticle() } }
	
// MARK: - Deinitialization
	
	deinit { imageTask?.cancel(); detailTask?.cancel() }
}

// MARK: - UIScrollViewDelegate

extension ArticleDetailViewController: UIScrollViewDelegate {
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
			// Apply interactive rubber-band scaling to the hero image on pull-down.
		guard scrollView.contentOffset.y < 0 else { imageView.transform = .identity; return }
		let scale = 1 + abs(scrollView.contentOffset.y) / 300
		imageView.transform = CGAffineTransform(scaleX: scale, y: scale)
	}
}
