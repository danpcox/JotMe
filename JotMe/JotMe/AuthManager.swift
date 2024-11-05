//
//  AuthManager.swift
//  JotMe
//
//  Created by Dan Cox on 11/5/24.
//

import Foundation
import GoogleSignIn

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var userId: Int?
    @Published var googleAccessToken: String? // Store the Google access token
    @Published var startupMessage: String? // Store the startup message from the API
    @Published var isStartupLoading: Bool = true // Indicates loading state

    init() {
        if let savedUserId = UserDefaults.standard.value(forKey: "userId") as? Int,
           let savedUserName = UserDefaults.standard.string(forKey: "userName"),
           let savedUserEmail = UserDefaults.standard.string(forKey: "userEmail") {
            self.userId = savedUserId
            self.userName = savedUserName
            self.userEmail = savedUserEmail
            self.isAuthenticated = true // Assume user is authenticated if we have their details
        }
        checkAuthentication() // Ensure authentication on startup
    }

    func checkAuthentication() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error restoring previous sign-in: \(error.localizedDescription)")
                    self.isAuthenticated = false
                    self.isStartupLoading = false
                } else if let user = user {
                    self.isAuthenticated = true
                    self.userName = user.profile?.name ?? "User"
                    self.userEmail = user.profile?.email ?? ""
                    
                    // Access token from Google user object
                    self.googleAccessToken = user.accessToken.tokenString
                    UserDefaults.standard.set(self.googleAccessToken, forKey: "googleAccessToken")

                    print("Refreshed Google Access Token: \(self.googleAccessToken ?? "")")
                    
                    // Only register the user if userId doesn't exist
                    if self.userId == nil {
                        print("checkAuthentication() - userId is empty, registering with backend")
                        self.registerUserWithBackend()
                    } else {
                        // If already registered, proceed with other startup tasks
                        self.checkStartup()
                    }
                }
            }
        }
    }

    // Function to register the user with the backend
    func registerUserWithBackend() {
        let userAPI = UserAPI(authManager: self)
        let userData = ["userName": self.userName, "userEmail": self.userEmail]
        
        userAPI.registerUser(userData: userData) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let userId = json["userId"] as? Int {
                        self.storeUserDetails(userId: userId, userName: self.userName, userEmail: self.userEmail)
                        print("User registered with userId: \(userId)")
                        
                        // Now proceed with startup check
                        self.checkStartup()
                    } else {
                        print("Failed to parse userId from registration response.")
                    }
                case .failure(let error):
                    print("Failed to register user: \(error.localizedDescription)")
                }
            }
        }
    }

    // Check if the user is already registered by checking if userId exists
    func isUserRegistered() -> Bool {
        return UserDefaults.standard.value(forKey: "userId") != nil
    }

    // Call the userAPI's checkStartup method
    func checkStartup() {
        let userAPI = UserAPI(authManager: self)
        userAPI.checkStartup { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let message = json["message"] as? String {
                        self.startupMessage = message
                    } else {
                        self.startupMessage = "Failed to parse message from response."
                    }
                case .failure(let error):
                    self.startupMessage = "Startup check failed: \(error.localizedDescription)"
                }
                self.isStartupLoading = false
            }
        }
    }

    // Function to store user details after registration
    func storeUserDetails(userId: Int, userName: String, userEmail: String) {
        DispatchQueue.main.async {
            self.userId = userId
            self.userName = userName
            self.userEmail = userEmail
            self.isAuthenticated = true

            // Save user details to UserDefaults
            UserDefaults.standard.set(userId, forKey: "userId")
            UserDefaults.standard.set(userName, forKey: "userName")
            UserDefaults.standard.set(userEmail, forKey: "userEmail")

            print("Stored user data: \(userId), \(userName), \(userEmail)")
        }
    }

    // Function to sign out and clear stored user data
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.userId = nil
            self.userName = ""
            self.userEmail = ""
            self.googleAccessToken = nil // Clear the access token on sign out

            // Clear user data from UserDefaults
            UserDefaults.standard.removeObject(forKey: "userId")
            UserDefaults.standard.removeObject(forKey: "userName")
            UserDefaults.standard.removeObject(forKey: "userEmail")
            UserDefaults.standard.removeObject(forKey: "googleAccessToken")

            print("Cleared user data and signed out.")
        }
    }
}

