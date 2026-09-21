//
//  MainTabBarController.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 21/09/26.
//


import UIKit

final class MainTabBarController: UITabBarController {
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        let feed = UINavigationController(rootViewController: FeedViewController())
        feed.setNavigationBarHidden(true, animated: false)
        feed.tabBarItem = UITabBarItem(title: "Feed", image: UIImage(systemName: "newspaper"), selectedImage: UIImage(systemName: "newspaper.fill"))

        let explore = UINavigationController(rootViewController: ExploreViewController())
        explore.tabBarItem = UITabBarItem(title: "Explore", image: UIImage(systemName: "safari"), selectedImage: UIImage(systemName: "safari.fill"))

        let saved = UINavigationController(rootViewController: SavedViewController())
        saved.tabBarItem = UITabBarItem(title: "Saved", image: UIImage(systemName: "bookmark"), selectedImage: UIImage(systemName: "bookmark.fill"))

        setViewControllers([feed, explore, saved], animated: false)
        tabBar.tintColor = AppTheme.brand

        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        let layouts = [
            appearance.stackedLayoutAppearance,
            appearance.inlineLayoutAppearance,
            appearance.compactInlineLayoutAppearance
        ]
        for layout in layouts {
            layout.normal.titleTextAttributes = [.foregroundColor: UIColor.secondaryLabel]
            layout.normal.titlePositionAdjustment = .zero
            layout.selected.titleTextAttributes = [.foregroundColor: tabBar.tintColor]
            layout.selected.titlePositionAdjustment = .zero
        }
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }
}
