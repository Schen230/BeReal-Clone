//
//  AppDelegate.swift
//  project2-BeReal
//
//  Created by Sunny Chen on 9/14/24.
//

import UIKit
import ParseSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        // TODO: Pt 1 - Initialize Parse SDK
        ParseSwift.initialize(applicationId: "MINKbqG4FiICwfR2LbzyGz8dq38o9B9l60BYy1sR", clientKey: "6O2BBKCvS2E27QU5pyVG81vJsCDBKMomApmfKBBb", serverURL: URL(string: "https://parseapi.back4app.com")!)


        // TODO: Pt 1: - Instantiate and save a test parse object to your server
        //var score = GameScore()
        //score.playerName = "Kingsley"
        //score.points = 23
        //
        //score.save { result in
        //    switch result {
        //    case .success(let savedScore):
        //        print("😳 Parse Object SAVED!: Player: \(String(describing: savedScore.playerName)), Score: \(String(describing: savedScore.points))")
        //    case . failure(let error):
        //        assertionFailure("Error saving: \(error)")
        //    }
        //}


        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

// TODO: Pt 1 - Create Test Parse Object

//struct GameScore: ParseObject {
//    var objectId: String?
//    var createdAt: Date?
//    var updatedAt: Date?
//    var ACL: ParseACL?
//    var originalData: Data?
//
//    var playerName: String?
//    var points: Int?
//}
//
//extension GameScore {
//    init(playerName: String, points: Int) {
//        self.playerName = playerName
//        self.points = points
//    }
//}
