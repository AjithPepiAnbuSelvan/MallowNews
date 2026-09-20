import SafariServices
import UIKit

final class ArticleDetailViewController: UIViewController {
    private let articles: [Article]
    private var index: Int
    private var article: Article { articles[index] }
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
    private var imageTask: Task<Void, Never>?
    private var imageRequestID = UUID()

    init(articles: [Article], index: Int) {
        self.articles = articles; self.index = index
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var brand: UIColor { UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.73, green: 0.60, blue: 1, alpha: 1)
            : UIColor(red: 0.33, green: 0.18, blue: 0.55, alpha: 1)
    }}

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.08, green: 0.065, blue: 0.12, alpha: 1)
                : UIColor(red: 0.955, green: 0.94, blue: 0.99, alpha: 1)
        }
        view.tintColor = brand
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareArticle))
        setupViews()
        let next = UISwipeGestureRecognizer(target: self, action: #selector(showNext)); next.direction = .left
        let previous = UISwipeGestureRecognizer(target: self, action: #selector(showPrevious)); previous.direction = .right
        view.addGestureRecognizer(next); view.addGestureRecognizer(previous)
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
        summaryLabel.font = .preferredFont(forTextStyle: .body); summaryLabel.numberOfLines = 0
        readButton.configuration = .filled(); readButton.configuration?.title = "Read original story"; readButton.configuration?.baseBackgroundColor = brand; readButton.configuration?.cornerStyle = .large
        readButton.addTarget(self, action: #selector(openOriginal), for: .touchUpInside)
	    positionLabel.font = .preferredFont(forTextStyle: .caption1); positionLabel.textColor = .secondaryLabel; positionLabel.textAlignment = .center; positionLabel.numberOfLines = 0;
        let stack = UIStackView(arrangedSubviews: [imageView, sourceLabel, titleLabel, metadataLabel, summaryLabel, readButton, positionLabel])
        stack.axis = .vertical; stack.spacing = 16; stack.setCustomSpacing(22, after: metadataLabel); stack.setCustomSpacing(24, after: summaryLabel)
        view.addSubview(scrollView); scrollView.addSubview(surface); surface.addSubview(stack); imageView.addSubview(imageActivity)
        [scrollView, surface, stack, imageView, imageActivity].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor), scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor), scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            surface.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16), surface.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16), surface.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16), surface.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: surface.topAnchor, constant: 16), stack.leadingAnchor.constraint(equalTo: surface.leadingAnchor, constant: 16), stack.trailingAnchor.constraint(equalTo: surface.trailingAnchor, constant: -16), stack.bottomAnchor.constraint(equalTo: surface.bottomAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.62), imageActivity.centerXAnchor.constraint(equalTo: imageView.centerXAnchor), imageActivity.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
        ])
    }

    private func renderArticle() {
        imageTask?.cancel(); imageRequestID = UUID()
        let requestID = imageRequestID; let current = article
        title = current.newsSite; sourceLabel.text = current.newsSite.uppercased(); titleLabel.text = current.title; summaryLabel.text = current.summary
        positionLabel.text = "\(index + 1) of \(articles.count) \n· Swipe for the next story"
        let author = current.authors.map(\.name).joined(separator: ", ")
        var metadata = (author.isEmpty ? current.newsSite : author) + " · " + current.publishedAt.formatted(date: .abbreviated, time: .shortened)
        if current.updatedAt > current.publishedAt { metadata += "\nUpdated " + current.updatedAt.formatted(date: .abbreviated, time: .shortened) }
        metadataLabel.text = metadata; scrollView.setContentOffset(.zero, animated: false)
        imageView.image = nil; imageView.contentMode = .scaleAspectFill; imageView.backgroundColor = .secondarySystemBackground; imageActivity.startAnimating()
        guard let url = current.imageURL else { showImageFallback(); return }
        imageTask = Task { [weak self] in
            guard let image = try? await ImageLoader.shared.image(from: url), !Task.isCancelled, let self, self.imageRequestID == requestID else { return }
            self.imageView.image = image; self.imageView.backgroundColor = .clear; self.imageActivity.stopAnimating()
        }
    }
    private func showImageFallback() { imageView.contentMode = .center; imageView.tintColor = .tertiaryLabel; imageView.image = UIImage(systemName: "photo", withConfiguration: UIImage.SymbolConfiguration(pointSize: 32)); imageActivity.stopAnimating() }
    @objc private func openOriginal() { present(SFSafariViewController(url: article.url), animated: true) }
    @objc private func shareArticle() { let controller = UIActivityViewController(activityItems: [article.title, article.url], applicationActivities: nil); controller.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem; present(controller, animated: true) }
    @objc private func showNext() { navigate(to: index + 1) }
    @objc private func showPrevious() { navigate(to: index - 1) }
    private func navigate(to newIndex: Int) { guard articles.indices.contains(newIndex) else { UINotificationFeedbackGenerator().notificationOccurred(.warning); return }; index = newIndex; UIImpactFeedbackGenerator(style: .light).impactOccurred(); UIView.transition(with: view, duration: 0.22, options: .transitionCrossDissolve) { self.renderArticle() } }
    deinit { imageTask?.cancel() }
}
