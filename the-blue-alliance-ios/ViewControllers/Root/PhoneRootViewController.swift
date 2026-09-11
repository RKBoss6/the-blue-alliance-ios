import Foundation
import MyTBAKit
import UIKit

class PhoneRootViewController: UITabBarController, RootController {

    let dependencies: Dependencies
    let fcmTokenProvider: any FCMTokenProvider
    let pushService: any PushServiceProtocol

    private let tabBarFadeView = UIView()
    private let tabBarFadeGradient = CAGradientLayer()

    init(
        fcmTokenProvider: any FCMTokenProvider,
        pushService: any PushServiceProtocol,
        dependencies: Dependencies
    ) {
        self.dependencies = dependencies
        self.fcmTokenProvider = fcmTokenProvider
        self.pushService = pushService

        super.init(nibName: nil, bundle: nil)

        tabBarFadeView.isUserInteractionEnabled = false
        tabBarFadeView.backgroundColor = .clear
        tabBar.tintColor = UIColor.tabBarTintColor
        updateTabBarFadeColors()
        tabBarFadeGradient.locations = [0.0, 0.5, 1]
        tabBarFadeView.layer.addSublayer(tabBarFadeGradient)

        let dashboardEnabled = dependencies.appSettings.featureFlags.isEnabled(.dashboard)
        tabs = RootType.tabs(dashboardEnabled: dashboardEnabled).map { type in
            UITab(title: type.title, image: type.icon, identifier: type.tabIdentifier) {
                [unowned self] _ in
                UINavigationController(rootViewController: self.makeRootViewController(for: type))
            }
        }

        mode = .tabSidebar
    }

    private func updateTabBarFadeColors() {
        tabBarFadeGradient.colors = [
            UIColor.systemBackground.withAlphaComponent(0.0).cgColor,
            UIColor.systemBackground.withAlphaComponent(0.55).cgColor,
            UIColor.systemBackground.withAlphaComponent(0.9).cgColor
        ]
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateTabBarFadeColors()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tabBarFadeView) // stays a direct child of `view` permanently
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let fadeHeight: CGFloat = 140
        let bottomY = view.bounds.maxY

        tabBarFadeView.frame = CGRect(
            x: 0,
            y: bottomY - fadeHeight,
            width: view.bounds.width,
            height: fadeHeight
        )
        tabBarFadeGradient.frame = tabBarFadeView.bounds

        // Order relative to whichever of tabBar's ancestors is a direct
        // child of `view` — never reparent tabBarFadeView itself, or its
        // frame (computed in `view`'s coordinate space) becomes invalid.
        if let tabBarChromeRoot = directChild(of: view, ancestorOf: tabBar) {
            view.insertSubview(tabBarFadeView, belowSubview: tabBarChromeRoot)
        } else {
            view.bringSubviewToFront(tabBarFadeView)
        }
    }

    /// Walks up from `descendant` until it finds the ancestor that is a
    /// direct subview of `ancestor`, so ordering can be done within a
    /// single, known coordinate space.
    private func directChild(of ancestor: UIView, ancestorOf descendant: UIView) -> UIView? {
        var current: UIView? = descendant
        while let view = current, view.superview !== ancestor {
            current = view.superview
        }
        return current
    }

}
