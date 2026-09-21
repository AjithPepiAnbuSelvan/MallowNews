//
//  FeedViewController.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 21/09/26.
//


import UIKit

final class FeedViewController: UIViewController {
		// MARK: - Section Definitions
	
	private enum Section: Int { case hero, latest }
	
		// MARK: - Dependencies & State
	
	private let viewModel = FeedViewModel()
	private let initialQuery: String?
	
		// MARK: - UI Components
	
	private let titleLabel = UILabel()
	private let searchButton = UIButton(type: .system)
	private let headerStack = UIStackView()
	private let topicScrollView = UIScrollView()
	private let topicStack = UIStackView()
	private var selectedTopic: String = "All"
	private let searchField = UISearchTextField()
	private let searchContainer = UIView()
	private let activityIndicator = UIActivityIndicatorView(
		style: .large
	)
	private let messageLabel = UILabel()
	private let refreshControl = UIRefreshControl()
	private let retryButton = UIButton(type: .system)
	private let skeletonStack = UIStackView()
	private var loadingFeedbackTask: Task<Void, Never>?
	private var shouldShowReplacementSkeleton = false
	
	private lazy var collectionView = UICollectionView(
		frame: .zero,
		collectionViewLayout: createLayout()
	)
	
		// MARK: - Data Source & Cache
	
	private lazy var dataSource = makeDataSource()
		// Diffable data sources can query cell providers while an active network response replaces items;
		// caching articles by ID protects animated transitions and avoids inconsistencies.
	private var displayedArticles: [Int: Article] = [:]
	
		// MARK: - Initialization
	
	init(initialQuery: String? = nil) {
		self.initialQuery = initialQuery
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
	
		// MARK: - Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setupUI()
		observeViewModel()
		
		Task {
			await viewModel.loadInitial(query: initialQuery)
		}
	}
	
		// MARK: - Setup
	
	private func setupUI() {
		view.backgroundColor = AppTheme.background
		view.tintColor = AppTheme.brand
		view.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
		
		titleLabel.text = "MallowNews"
		titleLabel.textColor = view.tintColor
		let brandFont = UIFont.systemFont(ofSize: 25, weight: .bold)
		titleLabel.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: UIFont(descriptor: brandFont.fontDescriptor.withDesign(.rounded) ?? brandFont.fontDescriptor, size: 25))
		titleLabel.adjustsFontForContentSizeCategory = true
		
		searchButton.setImage(UIImage(systemName: "magnifyingglass", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)), for: .normal)
		searchButton.tintColor = view.tintColor
		searchButton.configuration = .tinted()
		searchButton.configuration?.cornerStyle = .capsule
		searchButton.accessibilityLabel = "Search articles"
		searchButton.addTarget(self, action: #selector(toggleSearch), for: .touchUpInside)
		
		searchField.placeholder = "Search stories, missions & agencies"
		searchField.returnKeyType = .search
		searchField.delegate = self
		searchField.font = .preferredFont(forTextStyle: .body)
		searchField.borderStyle = .none
		searchField.backgroundColor = .clear
		searchField.textColor = .label
		searchField.clearButtonMode = .whileEditing
		searchField.tintColor = view.tintColor
		searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
		
		searchContainer.backgroundColor = UIColor { traits in
			traits.userInterfaceStyle == .dark
			? UIColor(red: 0.15, green: 0.12, blue: 0.21, alpha: 1)
			: UIColor(red: 1, green: 1, blue: 1, alpha: 0.78)
		}
		searchContainer.layer.cornerCurve = .continuous
		searchContainer.layer.cornerRadius = 18
		searchContainer.layer.borderWidth = 1
		searchContainer.layer.borderColor = view.tintColor.withAlphaComponent(0.12).cgColor
		searchContainer.layer.shadowColor = UIColor.black.cgColor
		searchContainer.layer.shadowOpacity = 0.05
		searchContainer.layer.shadowRadius = 12
		searchContainer.layer.shadowOffset = CGSize(width: 0, height: 5)
		searchContainer.isHidden = true
		searchContainer.addSubview(searchField)
		searchField.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			searchField.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 12),
			searchField.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -12),
			searchField.topAnchor.constraint(equalTo: searchContainer.topAnchor, constant: 2),
			searchField.bottomAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: -2),
			searchContainer.heightAnchor.constraint(equalToConstant: 52)
		])
		
		let mark = UIImageView(image: UIImage(systemName: "sparkle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 23, weight: .bold)))
		mark.tintColor = .white
		mark.backgroundColor = view.tintColor
		mark.contentMode = .center
		mark.layer.cornerRadius = 12
		mark.isAccessibilityElement = false
		mark.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([mark.widthAnchor.constraint(equalToConstant: 40), mark.heightAnchor.constraint(equalToConstant: 40)])
		let masthead = UIStackView(arrangedSubviews: [mark, titleLabel, searchButton])
		masthead.alignment = .center
		masthead.spacing = 10
		headerStack.addArrangedSubview(masthead)
		headerStack.addArrangedSubview(searchContainer)
		configureTopics()
		headerStack.addArrangedSubview(topicScrollView)
		headerStack.axis = .vertical
		headerStack.spacing = 12
		
		collectionView.backgroundColor = .clear
		collectionView.alwaysBounceVertical = true
		collectionView.delegate = self
		refreshControl.tintColor = view.tintColor
		collectionView.keyboardDismissMode = .onDrag
		refreshControl.addTarget(self, action: #selector(refreshFeed), for: .valueChanged)
		collectionView.refreshControl = refreshControl
		collectionView.register(
			ArticleCardCell.self,
			forCellWithReuseIdentifier: ArticleCardCell.reuseIdentifier
		)
		collectionView.register(FeaturedArticleCell.self, forCellWithReuseIdentifier: FeaturedArticleCell.reuseIdentifier)
		collectionView.register(FeedSectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "FeedSectionHeader")
		collectionView.register(PaginationFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: PaginationFooterView.reuseIdentifier)
		
		messageLabel.font = .preferredFont(forTextStyle: .body)
		messageLabel.textColor = .secondaryLabel
		messageLabel.textAlignment = .center
		messageLabel.numberOfLines = 0
		messageLabel.isHidden = true
		retryButton.configuration = .filled()
		retryButton.configuration?.title = "Try Again"
		retryButton.addTarget(self, action: #selector(retry), for: .touchUpInside)
		retryButton.isHidden = true
		skeletonStack.axis = .vertical
		skeletonStack.spacing = 12
		skeletonStack.isHidden = true
		(0..<4).forEach { _ in skeletonStack.addArrangedSubview(makeSkeletonCard()) }
		
		view.addSubview(headerStack)
		view.addSubview(collectionView)
		view.addSubview(activityIndicator)
		view.addSubview(messageLabel)
		view.addSubview(skeletonStack)
		view.addSubview(retryButton)
		
		headerStack.translatesAutoresizingMaskIntoConstraints = false
		collectionView.translatesAutoresizingMaskIntoConstraints = false
		activityIndicator.translatesAutoresizingMaskIntoConstraints = false
		messageLabel.translatesAutoresizingMaskIntoConstraints = false
		skeletonStack.translatesAutoresizingMaskIntoConstraints = false
		retryButton.translatesAutoresizingMaskIntoConstraints = false
		
		NSLayoutConstraint.activate([
			headerStack.topAnchor.constraint(
				equalTo: view.safeAreaLayoutGuide.topAnchor,
				constant: 8
			),
			headerStack.leadingAnchor.constraint(
				equalTo: view.layoutMarginsGuide.leadingAnchor
			),
			headerStack.trailingAnchor.constraint(
				equalTo: view.layoutMarginsGuide.trailingAnchor
			),
			
			searchButton.widthAnchor.constraint(equalToConstant: 44),
			searchButton.heightAnchor.constraint(equalToConstant: 44),
			
			collectionView.topAnchor.constraint(
				equalTo: headerStack.bottomAnchor,
				constant: 20
			),
			collectionView.leadingAnchor.constraint(
				equalTo: view.leadingAnchor
			),
			collectionView.trailingAnchor.constraint(
				equalTo: view.trailingAnchor
			),
			collectionView.bottomAnchor.constraint(
				equalTo: view.bottomAnchor
			),
			
			activityIndicator.centerXAnchor.constraint(
				equalTo: view.centerXAnchor
			),
			activityIndicator.centerYAnchor.constraint(
				equalTo: view.centerYAnchor
			),
			
			messageLabel.centerYAnchor.constraint(
				equalTo: view.centerYAnchor
			),
			messageLabel.leadingAnchor.constraint(
				equalTo: view.layoutMarginsGuide.leadingAnchor
			),
			messageLabel.trailingAnchor.constraint(
				equalTo: view.layoutMarginsGuide.trailingAnchor
			),
			skeletonStack.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 20),
			skeletonStack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
			skeletonStack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
			retryButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 16),
			retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
		])
	}
	
		// MARK: - Topic Filters
	
	private func configureTopics() {
		topicScrollView.showsHorizontalScrollIndicator = false
		topicStack.axis = .horizontal
		topicStack.spacing = 8
		topicScrollView.addSubview(topicStack)
		topicStack.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			topicStack.topAnchor.constraint(equalTo: topicScrollView.contentLayoutGuide.topAnchor),
			topicStack.leadingAnchor.constraint(equalTo: topicScrollView.contentLayoutGuide.leadingAnchor),
			topicStack.trailingAnchor.constraint(equalTo: topicScrollView.contentLayoutGuide.trailingAnchor),
			topicStack.bottomAnchor.constraint(equalTo: topicScrollView.contentLayoutGuide.bottomAnchor),
			topicStack.heightAnchor.constraint(equalTo: topicScrollView.frameLayoutGuide.heightAnchor),
			topicScrollView.heightAnchor.constraint(equalToConstant: 36)
		])
		Topic.allCases.forEach { topic in
			let button = UIButton(type: .system)
			button.setTitle(topic.rawValue, for: .normal)
			button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
			button.configuration = .tinted()
			button.configuration?.cornerStyle = .capsule
			button.accessibilityIdentifier = topic.rawValue
			button.addTarget(self, action: #selector(selectTopic(_:)), for: .touchUpInside)
			topicStack.addArrangedSubview(button)
		}
		updateTopicButtons()
	}
	
	@objc private func selectTopic(_ sender: UIButton) {
		guard let topic = sender.title(for: .normal), topic != selectedTopic else { return }
		selectedTopic = topic
		shouldShowReplacementSkeleton = true
		UIImpactFeedbackGenerator(style: .light).impactOccurred()
		updateTopicButtons()
		Task { await viewModel.loadInitial(query: Topic(rawValue: topic)?.query) }
	}
	
	private func updateTopicButtons() {
		for case let button as UIButton in topicStack.arrangedSubviews {
			let topic = button.title(for: .normal) ?? button.configuration?.title ?? ""
			let selected = topic == selectedTopic
			var configuration = selected ? UIButton.Configuration.filled() : .tinted()
			configuration.title = topic
			configuration.cornerStyle = .capsule
			configuration.baseBackgroundColor = selected ? view.tintColor : nil
			configuration.baseForegroundColor = selected ? .white : view.tintColor
			button.configuration = configuration
		}
	}
	
		// MARK: - Actions & Search
	
	@objc private func toggleSearch() {
		let opening = searchContainer.isHidden
		searchContainer.isHidden = !opening
		searchButton.setImage(UIImage(systemName: opening ? "xmark" : "magnifyingglass"), for: .normal)
		searchButton.accessibilityLabel = opening ? "Close search" : "Search articles"
		UIView.animate(withDuration: 0.22, delay: 0, options: .curveEaseOut) { [weak self] in
			self?.view.layoutIfNeeded()
		}
		if opening { searchField.becomeFirstResponder() }
		else {
			searchField.resignFirstResponder()
			if !(searchField.text ?? "").isEmpty {
				searchField.text = ""
				viewModel.search(for: "")
			}
		}
	}
	
	@objc private func searchChanged() {
		viewModel.search(for: searchField.text ?? "")
	}
	
	@objc private func refreshFeed() {
		Task { [weak self] in
			await self?.viewModel.refresh()
			self?.refreshControl.endRefreshing()
		}
	}
	
	@objc private func retry() { Task { await viewModel.retry() } }
	
	private func makeSkeletonCard() -> UIView {
		ShimmerArticlePlaceholder()
	}
	
		// MARK: - Collection View Layout
	
	private func createLayout() -> UICollectionViewLayout {
		return UICollectionViewCompositionalLayout { sectionIndex, _ in
			let itemSize = NSCollectionLayoutSize(
				widthDimension: .fractionalWidth(1),
				heightDimension: .estimated(sectionIndex == Section.hero.rawValue ? 400 : 136)
			)
			
			let item = NSCollectionLayoutItem(layoutSize: itemSize)
			
			let groupSize = NSCollectionLayoutSize(
				widthDimension: .fractionalWidth(1),
				heightDimension: .estimated(sectionIndex == Section.hero.rawValue ? 400 : 136)
			)
			
			let group = NSCollectionLayoutGroup.vertical(
				layoutSize: groupSize,
				subitems: [item]
			)
			
			let section = NSCollectionLayoutSection(group: group)
			
			section.interGroupSpacing = FeedStyle.rowSpacing
			if sectionIndex == Section.latest.rawValue {
				section.boundarySupplementaryItems = [NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(48)), elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)]
				section.boundarySupplementaryItems.append(
					NSCollectionLayoutBoundarySupplementaryItem(
						layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(52)),
						elementKind: UICollectionView.elementKindSectionFooter,
						alignment: .bottom
					)
				)
			}
			section.contentInsets = NSDirectionalEdgeInsets(
				top: 0,
				leading: FeedStyle.outerMargin,
				bottom: 24,
				trailing: FeedStyle.outerMargin
			)
			
			return section
		}
	}
	
		// MARK: - Data Source Configuration
	
	private func makeDataSource()
	-> UICollectionViewDiffableDataSource<Int, FeedItem> {
		
		let source = UICollectionViewDiffableDataSource<Int, FeedItem>(
			collectionView: collectionView
		) { [weak self] collectionView, indexPath, item in
			
			guard let self, let article = self.displayedArticles[item.articleID] else { return nil }
			if case .hero = item {
				let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeaturedArticleCell.reuseIdentifier, for: indexPath) as! FeaturedArticleCell
				cell.configure(with: article)
				return cell
			}
			guard let cell = collectionView.dequeueReusableCell(
				withReuseIdentifier: ArticleCardCell.reuseIdentifier,
				for: indexPath
			) as? ArticleCardCell else {
				return nil
			}
			
			cell.configure(with: article)
			return cell
		}
		source.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
			if kind == UICollectionView.elementKindSectionFooter {
				let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PaginationFooterView.reuseIdentifier, for: indexPath) as! PaginationFooterView
				footer.configure(isLoading: self?.viewModel.isLoadingNextPage ?? false, error: self?.viewModel.paginationError)
				footer.onRetry = { Task { await self?.viewModel.retryNextPage() } }
				return footer
			}
			return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FeedSectionHeader", for: indexPath)
		}
		return source
	}
	
		// MARK: - ViewModel Binding
	
	private func observeViewModel() {
		viewModel.onStateChange = { [weak self] state in
			self?.render(state)
		}
		viewModel.onPaginationChange = { [weak self] _ in self?.collectionView.reloadData() }
		viewModel.onPaginationError = { [weak self] _ in self?.collectionView.reloadData() }
	}
	
		// MARK: - State Rendering
	
	private func render(_ state: FeedViewModel.State) {
		switch state {
		case .idle:
			break
			
		case .loading:
			collectionView.isHidden = false
			skeletonStack.isHidden = true
			retryButton.isHidden = true
			loadingFeedbackTask?.cancel()
			if shouldShowReplacementSkeleton {
				collectionView.isHidden = true
				skeletonStack.isHidden = false
			} else if viewModel.articles.isEmpty, !refreshControl.isRefreshing {
				loadingFeedbackTask = Task { [weak self] in
					try? await Task.sleep(nanoseconds: 250_000_000)
					guard !Task.isCancelled, let self, self.viewModel.articles.isEmpty else { return }
					self.skeletonStack.isHidden = false
					self.collectionView.isHidden = true
				}
			}
			messageLabel.isHidden = true
			
		case .loaded:
			loadingFeedbackTask?.cancel()
			shouldShowReplacementSkeleton = false
			retryButton.isHidden = true
			activityIndicator.stopAnimating()
			refreshControl.endRefreshing()
			messageLabel.isHidden = true
			applySnapshot { [weak self] in
				self?.collectionView.isHidden = false
				self?.skeletonStack.isHidden = true
			}
			
		case .empty:
			loadingFeedbackTask?.cancel()
			shouldShowReplacementSkeleton = false
			collectionView.isHidden = true
			skeletonStack.isHidden = true
			retryButton.isHidden = true
			activityIndicator.stopAnimating()
			refreshControl.endRefreshing()
			messageLabel.text = searchField.text?.isEmpty == false
			? "No stories match that search."
			: "No articles found."
			messageLabel.isHidden = false
			
		case .failed:
			loadingFeedbackTask?.cancel()
			shouldShowReplacementSkeleton = false
			collectionView.isHidden = true
			skeletonStack.isHidden = true
			retryButton.isHidden = false
			activityIndicator.stopAnimating()
			refreshControl.endRefreshing()
			messageLabel.text = "Unable to load news. Please try again."
			messageLabel.isHidden = false
		}
	}
	
		// MARK: - Snapshot Management
	
	private func applySnapshot(completion: (() -> Void)? = nil) {
		var snapshot = NSDiffableDataSourceSnapshot<Int, FeedItem>()
		
		for article in viewModel.articles {
			displayedArticles[article.id] = article
		}
		
		snapshot.appendSections([Section.hero.rawValue, Section.latest.rawValue])
		if let hero = viewModel.featuredArticle {
			snapshot.appendItems([.hero(hero.id)], toSection: Section.hero.rawValue)
		}
		snapshot.appendItems(viewModel.latestArticles.map { .latest($0.id) }, toSection: Section.latest.rawValue)
		
			// Topic replacements already use a shimmer transition. Avoid diffable's cell-move
			// animation, which can briefly place the old hero card in the latest section.
		dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
			let activeIDs = Set(snapshot.itemIdentifiers.map(\.articleID))
			self?.displayedArticles = self?.displayedArticles.filter { activeIDs.contains($0.key) } ?? [:]
			completion?()
		}
	}
}

	// MARK: - UITextFieldDelegate

extension FeedViewController: UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
}

	// MARK: - Supplementary Views

private final class FeedSectionHeader: UICollectionReusableView {
	override init(frame: CGRect) {
		super.init(frame: frame)
		let label = UILabel()
		label.text = "Latest"
		label.font = UIFontMetrics(forTextStyle: .title3).scaledFont(for: .systemFont(ofSize: 21, weight: .bold))
		label.adjustsFontForContentSizeCategory = true
		addSubview(label)
		label.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
			label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: FeedStyle.contentInset),
			label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -FeedStyle.contentInset),
			label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
		])
	}
	required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

	// MARK: - Skeleton View

private final class ShimmerArticlePlaceholder: UIView {
	private let gradientLayer = CAGradientLayer()
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		backgroundColor = .secondarySystemBackground
		layer.cornerRadius = 18
		layer.cornerCurve = .continuous
		heightAnchor.constraint(equalToConstant: 126).isActive = true
		
		let thumbnail = makeBlock(cornerRadius: 14)
		let source = makeBlock(cornerRadius: 5)
		let headlineOne = makeBlock(cornerRadius: 5)
		let headlineTwo = makeBlock(cornerRadius: 5)
		let metadata = makeBlock(cornerRadius: 5)
		let textStack = UIStackView(arrangedSubviews: [source, headlineOne, headlineTwo, metadata])
		textStack.axis = .vertical
		textStack.alignment = .leading
		textStack.spacing = 9
		addSubview(thumbnail)
		addSubview(textStack)
		thumbnail.translatesAutoresizingMaskIntoConstraints = false
		textStack.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			thumbnail.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
			thumbnail.centerYAnchor.constraint(equalTo: centerYAnchor),
			thumbnail.widthAnchor.constraint(equalToConstant: 92),
			thumbnail.heightAnchor.constraint(equalToConstant: 92),
			textStack.leadingAnchor.constraint(equalTo: thumbnail.trailingAnchor, constant: 14),
			textStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
			textStack.centerYAnchor.constraint(equalTo: centerYAnchor),
			source.widthAnchor.constraint(equalTo: textStack.widthAnchor, multiplier: 0.28),
			source.heightAnchor.constraint(equalToConstant: 11),
			headlineOne.heightAnchor.constraint(equalToConstant: 16),
			headlineTwo.widthAnchor.constraint(equalTo: textStack.widthAnchor, multiplier: 0.72),
			headlineTwo.heightAnchor.constraint(equalToConstant: 16),
			metadata.widthAnchor.constraint(equalTo: textStack.widthAnchor, multiplier: 0.42),
			metadata.heightAnchor.constraint(equalToConstant: 11)
		])
		
		gradientLayer.colors = [
			UIColor.clear.cgColor,
			AppTheme.brand.withAlphaComponent(0.14).cgColor,
			UIColor.clear.cgColor
		]
		gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
		gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
		layer.addSublayer(gradientLayer)
	}
	
	required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
	
	override func layoutSubviews() {
		super.layoutSubviews()
		gradientLayer.frame = bounds
	}
	
	override func didMoveToWindow() {
		super.didMoveToWindow()
		guard window != nil, gradientLayer.animation(forKey: "shimmer") == nil else { return }
		let animation = CABasicAnimation(keyPath: "locations")
		animation.fromValue = [-1.0, -0.5, 0.0]
		animation.toValue = [1.0, 1.5, 2.0]
		animation.duration = 1.15
		animation.repeatCount = .infinity
		gradientLayer.add(animation, forKey: "shimmer")
	}
	
	private func makeBlock(cornerRadius: CGFloat) -> UIView {
		let block = UIView()
		block.backgroundColor = UIColor { traits in traits.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.10) : UIColor(red: 0.84, green: 0.80, blue: 0.91, alpha: 1) }
		block.layer.cornerRadius = cornerRadius
		block.layer.cornerCurve = .continuous
		return block
	}
}

	// MARK: - UICollectionViewDelegate & UIScrollViewDelegate

extension FeedViewController: UICollectionViewDelegate {
		// MARK: - Selection
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let item = dataSource.itemIdentifier(for: indexPath), let article = displayedArticles[item.articleID] else { return }
		guard let index = viewModel.articles.firstIndex(where: { $0.id == article.id }) else { return }
		navigationController?.pushViewController(ArticleDetailViewController(articles: viewModel.articles, index: index), animated: true)
	}
	
		// MARK: - UIScrollViewDelegate (Pagination Trigger)
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
			// Pre-fetch next page when scrolling within 300 points of the bottom.
		let remaining = scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.bounds.height
		guard remaining < 300 else { return }
		Task { await viewModel.loadNextPage() }
	}
	
		// MARK: - Context Menu Actions
	
	func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		guard let item = dataSource.itemIdentifier(for: indexPath), let article = displayedArticles[item.articleID] else { return nil }
		return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
			let saved = BookmarkStore.shared.contains(article)
			let save = UIAction(title: saved ? "Remove from Saved" : "Save Story", image: UIImage(systemName: saved ? "bookmark.slash" : "bookmark")) { _ in BookmarkStore.shared.toggle(article) }
			let share = UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { _ in
				let controller = UIActivityViewController(activityItems: [article.title, article.url], applicationActivities: nil)
				controller.popoverPresentationController?.sourceView = collectionView
				self.present(controller, animated: true)
			}
			return UIMenu(children: [save, share])
		}
	}
}
