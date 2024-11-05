//
//  UserAPI.swift
//  JotMe
//
//  Created by Dan Cox on 11/5/24.
//

import Foundation
class UserAPI: BaseAPI {

    init(authManager: AuthManager) {
        // Pass authManager to BaseAPI instead of individual parameters
        super.init(baseURL: "https://www.e-overhaul.com/jotme", authManager: authManager)
    }

    func registerUser(userData: [String: Any], completion: @escaping (Result<Data, Error>) -> Void) {
        guard let request = createRequest(endpoint: "/user/register.php", method: "POST", body: userData) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid request"])))
            return
        }

        sendRequest(request) { result in
            switch result {
            case .success(let data):
                // Parse the response to extract the userId
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let userId = json["userId"] as? Int {
                    print("User registered with userId: \(userId)")
                    
                    // Store the userId, userName, and userEmail in AuthManager
                    if let userName = userData["userName"] as? String,
                       let userEmail = userData["userEmail"] as? String {
                        self.authManager.storeUserDetails(userId: userId, userName: userName, userEmail: userEmail)
                    }
                } else {
                    print("Failed to parse userId from response.")
                }
                completion(.success(data))
            case .failure(let error):
                print("Error registering user: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    // API Called when user starts the App and is registered
    func checkStartup(completion: @escaping (Result<Data, Error>) -> Void) {
        guard let request = createRequest(endpoint: "/user/startup.php", method: "POST", body: ["userEmail": authManager.userEmail]) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid request"])))
            return
        }

        sendRequest(request) { result in
            switch result {
            case .success(let data):
                // Print the raw API response for debugging
                if let rawResponse = String(data: data, encoding: .utf8) {
                    print("Raw API Response: \(rawResponse)")
                } else {
                    print("Unable to convert data to string.")
                }

                // Try parsing the response
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let message = json["message"] as? String {
                    print("Parsed Startup Response: \(message)")
                } else {
                    print("Failed to parse message from response.")
                }
                completion(.success(data))

            case .failure(let error):
                // Print the error message for debugging
                print("Error during startup check: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

}
