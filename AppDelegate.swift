//
//  AppDelegate.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/04.
//
import UIKit
import FirebaseCore
import GoogleGenerativeAI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}




