//
//  SceneDelegate.swift
//  HealthKitWaterTracker
//
//  Created by David Wright on 2/22/21.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        let rootViewController = MainTabViewController()
        
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        
        self.window = window
    }
}

