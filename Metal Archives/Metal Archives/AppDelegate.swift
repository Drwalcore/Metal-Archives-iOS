//
//  AppDelegate.swift
//  Metal Archives
//
//  Created by Thanh-Nhon Nguyen on 09/01/2019.
//  Copyright © 2019 Thanh-Nhon Nguyen. All rights reserved.
//

import UIKit
import SlideMenuControllerSwift
import Alamofire
import Toaster
import SDWebImage
import Firebase
import Crashlytics
import UserNotifications
import Siren

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.initAppSettings()
        self.initAppearance()
        self.initSlideMenuController()
        self.askForReview()
        self.checkNewVersion()
        application.registerForRemoteNotifications()
        return true
    }
}

//MARK: Left menu
extension AppDelegate {
    fileprivate func initSlideMenuController() {
        let leftMenuViewController = UIStoryboard(name: "LeftMenu", bundle: Bundle.main).instantiateViewController(withIdentifier: "LeftMenuViewController") as! LeftMenuViewController
        let homepageViewController = UIStoryboard(name: "Home", bundle: Bundle.main).instantiateViewController(withIdentifier: "HomepageNavigationController") as! UINavigationController
        SlideMenuOptions.leftViewWidth = 215
        SlideMenuOptions.contentViewOpacity = 0.3
        // Prevent user from swiping menu up and down and closing the slide menu in the same time
        SlideMenuOptions.simultaneousGestureRecognizers = false
        SlideMenuOptions.opacityViewBackgroundColor = Settings.currentTheme.slideMenuControllerOpacityBackgroundColor
        
        let slideMenuController = SlideMenuController(mainViewController: homepageViewController, leftMenuViewController: leftMenuViewController)
        slideMenuController.delegate = leftMenuViewController
    
        self.window?.rootViewController = slideMenuController
        self.window?.makeKeyAndVisible()
    }
}

//MARK: - Perform shorcut action
extension AppDelegate {
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        switch shortcutItem.type {
        case "search":
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                NotificationCenter.default.post(name: NSNotification.Name.OpenSearchModule, object: nil)
            }
            Analytics.logEvent(AnalyticsEvent.OpenFromShortcut, parameters: [AnalyticsParameter.Shortcut: "Search"])
            
        case "random":
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                NotificationCenter.default.post(name: NSNotification.Name.ShowRandomBand, object: nil)
            }
            Analytics.logEvent(AnalyticsEvent.OpenFromShortcut, parameters: [AnalyticsParameter.Shortcut: "Random"])
            
        default:
            break
        }
    }
}

//MARK: - Perform url scheme action
extension AppDelegate {
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        switch url.host {
        case "band":
            let bandURLString = url.absoluteString.replacingOccurrences(of: "ma://band/", with: "")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                NotificationCenter.default.post(name: NSNotification.Name.ShowBandDetail, object: bandURLString)
            }
            Analytics.logEvent(AnalyticsEvent.OpenFromWidget, parameters: [AnalyticsParameter.WidgetItem: "Band"])
            
        case "review":
            let reviewURLString = url.absoluteString.replacingOccurrences(of: "ma://review/", with: "")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                NotificationCenter.default.post(name: NSNotification.Name.ShowReviewDetail, object: reviewURLString)
            }
            Analytics.logEvent(AnalyticsEvent.OpenFromWidget, parameters: [AnalyticsParameter.WidgetItem: "Review"])
            
        case "release":
            let releaseURLString = url.absoluteString.replacingOccurrences(of: "ma://release/", with: "")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                NotificationCenter.default.post(name: NSNotification.Name.ShowReleaseDetail, object: releaseURLString)
            }
            Analytics.logEvent(AnalyticsEvent.OpenFromWidget, parameters: [AnalyticsParameter.WidgetItem: "Release"])
            
        default:
            break
        }
        
        return true
    }
}

//MARK: Network Reachability
//extension AppDelegate {
//    private func addNetworkReachabilityListener() {
//        self.networkReachabilityManager?.listener = { status in
//            switch status {
//            case .reachable(_):
//                NotificationCenter.default.post(name: .InternetIsReachable, object: nil)
//            default:
//                NotificationCenter.default.post(name: .InternetIsUnreachable, object: nil)
//            }
//        }
//        self.networkReachabilityManager?.startListening()
//    }
//}

//MARK: - Appearance
extension AppDelegate {
    private func initAppSettings() {
        UserDefaults.registerDefaultValues()
        FirebaseApp.configure()
        
        Settings.currentTheme = UserDefaults.selectedTheme()
        Settings.currentFontSize = UserDefaults.selectedFontSize()
        Settings.thumbnailEnabled = UserDefaults.thumbnailEnabled()
        
        
        var choosenWidgetsString = ""
        UserDefaults.choosenWidgetSections().forEach({
            choosenWidgetsString += $0.description
            choosenWidgetsString += ", "
        })
        Analytics.logEvent(AnalyticsEvent.OpenWithSettings, parameters: ["theme": Settings.currentTheme.description, "font_size": Settings.currentFontSize.description,"thumbnail_enabled": UserDefaults.thumbnailEnabled(), "widget_sections": choosenWidgetsString, "num_of_sessions": UserDefaults.numberOfSessions()])
        
        SDWebImageManager.shared().imageDownloader?.maxConcurrentDownloads = 10
        
        //Register for Push Notification
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { (allow, error) in
            if allow {
                Analytics.logEvent(AnalyticsEvent.AllowPushNotification, parameters: nil)
            } else {
                Analytics.logEvent(AnalyticsEvent.NotAllowPushNotification, parameters: nil)
            }
        }
        Messaging.messaging().delegate = self
    }
    
    private func initAppearance() {
        window?.tintColor = Settings.currentTheme.titleColor
        
        ToastView.appearance().font = UIFont.systemFont(ofSize: 18, weight: .medium)
        ToastView.appearance().bottomOffsetLandscape = 50
        ToastView.appearance().bottomOffsetPortrait = 70
        ToastView.appearance().textColor = Settings.currentTheme.backgroundColor
        ToastView.appearance().backgroundColor = Settings.currentTheme.bodyTextColor
    }
}

//MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
}

//MARK: - MessagingDelegate
extension AppDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
    }
}

//MARK: - Ask for review
extension AppDelegate {
    private func askForReview() {
        defer {
            UserDefaults.increaseNumberOfSessions()
        }
        
        let numberOfSessions = UserDefaults.numberOfSessions()
        if (numberOfSessions == 10 || numberOfSessions == 20 || numberOfSessions == 50) && !UserDefaults.didMakeAReview() {
            //Ask for review after 1 minute
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                NotificationCenter.default.post(name: NSNotification.Name.AskForReview, object: nil)
            }
        }
    }
}

//MARK: - Check new version
extension AppDelegate {
    private func checkNewVersion() {
        Siren.shared.wail { (result, error) in
            if let `result` = result {
                switch result.alertAction {
                case .appStore:
                    Analytics.logEvent(AnalyticsEvent.OpenAppStoreToUpdate, parameters: nil)
                case .nextTime:
                    Analytics.logEvent(AnalyticsEvent.UpdateNextTime, parameters: nil)
                case .skip:
                    Analytics.logEvent(AnalyticsEvent.SkipUpdate, parameters: nil)
                case .unknown:
                    return
                }
            } else if let `error` = error {
                Analytics.logEvent(AnalyticsEvent.ErrorCheckingUpdate, parameters: ["error": error.localizedDescription])
            }
        }
    }
}
