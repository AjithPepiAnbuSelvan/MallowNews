//
//  SavedViewController.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 21/09/26.
//


import UIKit

final class SavedViewController: UITableViewController {
    // MARK: - Properties

    private let bookmarks = BookmarkStore.shared
    private let emptyLabel = UILabel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Saved"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "saved")
        emptyLabel.text = "No saved stories yet\nSave an article to read it later."
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.font = .preferredFont(forTextStyle: .body)
        tableView.backgroundView = emptyLabel
        _ = bookmarks.addObserver { [weak self] in self?.reloadContent() }
        reloadContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadContent()
    }

    // MARK: - State & Reload

    private func reloadContent() {
        emptyLabel.isHidden = !bookmarks.articles.isEmpty
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { bookmarks.articles.count }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { let article = bookmarks.articles[indexPath.row]; let cell = tableView.dequeueReusableCell(withIdentifier: "saved", for: indexPath); var content = cell.defaultContentConfiguration(); content.text = article.title; content.secondaryText = article.newsSite; content.textProperties.numberOfLines = 2; cell.contentConfiguration = content; cell.accessoryType = .disclosureIndicator; return cell }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { navigationController?.pushViewController(ArticleDetailViewController(articles: bookmarks.articles, index: indexPath.row), animated: true) }
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) { if editingStyle == .delete { bookmarks.toggle(bookmarks.articles[indexPath.row]); tableView.deleteRows(at: [indexPath], with: .automatic) } }
}
