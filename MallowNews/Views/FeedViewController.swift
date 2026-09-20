//
//  FeedViewController.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 21/09/26.
//


import UIKit

final class FeedViewController: UIViewController {
    private enum Section: Int { case hero, latest }

    private let viewModel = FeedViewModel()

    private let titleLabel = UILabel()
    private let searchButton = UIButton(type: .system)
    private let headerStack = UIStackView()
	private let searchField = UISearchTextField()
    private let activityIndicator = UIActivityIndicatorView(
        style: .large
    )
    private let messageLabel = UILabel()
    private let refreshControl = UIRefreshControl()
    private let paginationIndicator = UIActivityIndicatorView(style: .medium)
	private let retryButton = UIButton(type: .system)
	private let skeletonStack = UIStackView()

    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createLayout()
    )

    private lazy var dataSource = makeDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        observeViewModel()

        Task {
            await viewModel.loadArticles()
        }
    }

    private func setupUI() {
        view.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.08, green: 0.065, blue: 0.12, alpha: 1)
                : UIColor(red: 0.955, green: 0.94, blue: 0.99, alpha: 1)
        }
        view.tintColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.73, green: 0.60, blue: 1, alpha: 1)
                : UIColor(red: 0.33, green: 0.18, blue: 0.55, alpha: 1)
        }
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

		searchField.placeholder = "Search articles"
        searchField.isHidden = true
        searchField.returnKeyType = .search
        searchField.delegate = self
		searchField.font = .preferredFont(forTextStyle: .body)
		searchField.backgroundColor = .secondarySystemBackground
		searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)

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
        headerStack.addArrangedSubview(searchField)
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
        view.addSubview(paginationIndicator)
		view.addSubview(skeletonStack)
		view.addSubview(retryButton)

        headerStack.translatesAutoresizingMaskIntoConstraints = false
		searchField.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        paginationIndicator.translatesAutoresizingMaskIntoConstraints = false
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
			paginationIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			paginationIndicator.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
			skeletonStack.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 20),
			skeletonStack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
			skeletonStack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
			retryButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 16),
			retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func toggleSearch() {
        let opening = searchField.isHidden
        searchField.isHidden = !opening
        searchButton.setImage(UIImage(systemName: opening ? "xmark" : "magnifyingglass"), for: .normal)
        searchButton.accessibilityLabel = opening ? "Close search" : "Search articles"
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
		let card = UIView()
		card.backgroundColor = .secondarySystemBackground
		card.layer.cornerRadius = 16
		card.heightAnchor.constraint(equalToConstant: 122).isActive = true
		return card
	}

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
		
		section.interGroupSpacing = 12
        if sectionIndex == Section.latest.rawValue {
            section.boundarySupplementaryItems = [NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(48)), elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)]
        }
		section.contentInsets = NSDirectionalEdgeInsets(
			top: 0,
			leading: 20,
			bottom: 24,
			trailing: 20
		)
		
        return section
        }
	}

    private func makeDataSource()
        -> UICollectionViewDiffableDataSource<Int, Int> {

        let source = UICollectionViewDiffableDataSource<Int, Int>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, articleID in

            guard let self, let article = self.viewModel.article(withID: articleID) else { return nil }
            if indexPath.section == Section.hero.rawValue {
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
        source.supplementaryViewProvider = { collectionView, kind, indexPath in
            collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FeedSectionHeader", for: indexPath)
        }
        return source
    }

    private func observeViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
		viewModel.onPaginationChange = { [weak self] isLoading in
			isLoading ? self?.paginationIndicator.startAnimating() : self?.paginationIndicator.stopAnimating()
		}
    }

    private func render(_ state: FeedViewModel.State) {
        switch state {
        case .idle:
            break

        case .loading:
			collectionView.isHidden = !viewModel.articles.isEmpty ? false : true
			skeletonStack.isHidden = !viewModel.articles.isEmpty
			retryButton.isHidden = true
			if !refreshControl.isRefreshing {
				activityIndicator.startAnimating()
			}
            messageLabel.isHidden = true

        case .loaded:
			collectionView.isHidden = false
			skeletonStack.isHidden = true
			retryButton.isHidden = true
            activityIndicator.stopAnimating()
			refreshControl.endRefreshing()
            messageLabel.isHidden = true
            applySnapshot()

        case .empty:
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
			collectionView.isHidden = true
			skeletonStack.isHidden = true
			retryButton.isHidden = false
            activityIndicator.stopAnimating()
			refreshControl.endRefreshing()
            messageLabel.text = "Unable to load news. Please try again."
            messageLabel.isHidden = false
        }
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()

        snapshot.appendSections([Section.hero.rawValue, Section.latest.rawValue])
        if let hero = viewModel.featuredArticle {
            snapshot.appendItems([hero.id], toSection: Section.hero.rawValue)
        }
        snapshot.appendItems(viewModel.latestArticles.map(\.id), toSection: Section.latest.rawValue)

        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

extension FeedViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

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
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

extension FeedViewController: UICollectionViewDelegate {
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let articleID = dataSource.itemIdentifier(for: indexPath), let article = viewModel.article(withID: articleID) else { return }
		guard let index = viewModel.articles.firstIndex(where: { $0.id == article.id }) else { return }
		navigationController?.pushViewController(ArticleDetailViewController(articles: viewModel.articles, index: index), animated: true)
	}

	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let remaining = scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.bounds.height
		guard remaining < 300 else { return }
		Task { await viewModel.loadNextPage() }
	}
}
