// UIApplication+topMostController.swift
// Medication Reminder
//
// Created by Alex Rublov on 08/12/2025.
// Copyright © 2025 Alex Rublov. All rights reserved.
//
// ========================================================

import UIKit

extension UIApplication {
    var topMostController: UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            if let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                return Self.findTop(from: root)
            }
        }
        return nil
    }

    private static func findTop(from vc: UIViewController) -> UIViewController {
        if let presented = vc.presentedViewController {
            return findTop(from: presented)
        }
        if let nav = vc as? UINavigationController, let top = nav.topViewController {
            return findTop(from: top)
        }
        if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
            return findTop(from: selected)
        }
        return vc
    }
}
