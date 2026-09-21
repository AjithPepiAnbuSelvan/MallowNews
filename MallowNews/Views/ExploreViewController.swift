//
//  ExploreViewController.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 21/09/26.
//

import UIKit

final class ExploreViewController: UIViewController {
    // MARK: - Properties

    private let topics = Topic.allCases.filter { $0 != .all }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Explore"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.largeTitleDisplayMode = .always
        let collection = UICollectionView(frame: .zero, collectionViewLayout: Self.layout())
        collection.backgroundColor = .clear
        collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "topic")
        collection.dataSource = self
        collection.delegate = self
        view.addSubview(collection)
        collection.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([collection.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), collection.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor), collection.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor), collection.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
    }

    // MARK: - Layout

	private static func layout() -> UICollectionViewLayout { UICollectionViewCompositionalLayout { _, _ in let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(96)));
		item.contentInsets = .init(top: 6, leading: 6, bottom: 6, trailing: 6);
		let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(108)), subitems: [item]);
		return NSCollectionLayoutSection(group: group)
	}}
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegate

extension ExploreViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
	    topics.count
    }
	
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
	    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "topic", for: indexPath);
	    var content = UIListContentConfiguration.cell();
	    content.text = topics[indexPath.item].rawValue;
	    content.textProperties.font = .preferredFont(forTextStyle: .headline);
	    content.textProperties.color = .white;
	    cell.contentConfiguration = content;
	    cell.contentView.backgroundColor = AppTheme.brand;
	    cell.contentView.layer.cornerRadius = 20;
	    return cell
    }
	
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
	    let feed = FeedViewController(initialQuery: topics[indexPath.item].query);
	    navigationController?.pushViewController(feed, animated: true)
    }
}
