//
//  BeenThereApp.swift
//  BeenThere
//
//  Created by Jared Jones on 10/16/23.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

class AuthViewModel: ObservableObject {
    @Published var isSignedIn = false
    @AppStorage("isAuthenticated") var isAuthenticated = false
    
    var authHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        authHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                print("Logged in as: \(user.uid)")
                self.isSignedIn = true
                self.isAuthenticated = true
            } else {
                print("Not logged in.")
                self.isSignedIn = false
                self.isAuthenticated = false
            }
        }
    }
    
    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}

@main
struct BeenThereApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase
    @StateObject var authViewModel = AuthViewModel()
    @StateObject var accountViewModel = AccountViewModel()

    @AppStorage("appState") var appState = "notAuthenticated"
    @AppStorage("username") var username = ""


//    init() {
//        setupTerminationObserver()
//    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                switch appState {
                case "authenticated":
                            ContentView()
                                .statusBarHidden()
                        
                       
                        
                    
                case "createUser":
                    CreateUsernameView()
                        .statusBarHidden()
                case "notAuthenticated":
                    LoginView()
                        .statusBarHidden()
                default:
                    LoginView()
                        .statusBarHidden()
                }
            }
            .preferredColorScheme(.dark)
            .task {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    determineUIState()
                }
                if username == "" {
                    accountViewModel.signOut()
                }
            }
        }
        .environmentObject(accountViewModel)
        .environmentObject(authViewModel)
    }
    
    func determineUIState() {
        Auth.auth().addStateDidChangeListener() { auth, user in
            if authViewModel.isAuthenticated && authViewModel.isSignedIn && user != nil && auth.currentUser != nil {
                if username != "" {
                    appState = "authenticated"
                } else {
                    appState = "createUser"
                }
            } else {
                accountViewModel.signOut()
                appState = "notAuthenticated"
            }
        }
    }
    
//    private func setupTerminationObserver() {
//        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: nil) { _ in
//            // The app is about to terminate, save your data here
//            showSplash = true
//            print("App is terminating. Saved data to UserDefaults.")
//        }
//    }
}


