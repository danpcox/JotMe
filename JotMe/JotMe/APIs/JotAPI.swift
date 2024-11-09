//
//  JotAPI.swift
//  JotMe
//
//  Created by Dan Cox on 11/5/24.
//

import Foundation

class JotAPI: BaseAPI {
    init(authManager: AuthManager) {
        super.init(baseURL: "https://www.e-overhaul.com/jotme", authManager: authManager)
    }

    func addJot(transcribedText: String, completion: @escaping (Result<JotResponse, Error>) -> Void) {
        let endpoint = "/jots/addJotForUser.php"
        let jotData: [String: Any] = ["jotText": transcribedText]

        guard let request = createRequest(endpoint: endpoint, method: "POST", body: jotData) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid request"])))
            return
        }

        sendRequest(request) { result in
            switch result {
            case .success(let data):
                do {
                    let decodedResponse = try JSONDecoder().decode(JotResponse.self, from: data)
                    completion(.success(decodedResponse))
                } catch {
                    print("Failed to decode response: \(error)")
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    func getJotHistory(completion: @escaping (Result<JotHistoryResponse, Error>) -> Void) {
        let endpoint = "/jots/getUserJots.php" // API endpoint for retrieving jot history

        guard let request = createRequest(endpoint: endpoint, method: "POST") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid request"])))
            return
        }

        sendRequest(request) { result in
            switch result {
            case .success(let data):
                // Print the raw JSON response for debugging
/*
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON response: \(jsonString)")
                }
 */
                do {
                    let decodedResponse = try JSONDecoder().decode(JotHistoryResponse.self, from: data)
                    completion(.success(decodedResponse))
                } catch {
                    print("Decoding Error: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            case .failure(let error):
                print("Request Error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    // New function to mark a Todo as completed
    func completeTodo(todoId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let endpoint = "/jots/completeTodo.php"
        let body: [String: Any] = ["todoId": todoId]

        guard let request = createRequest(endpoint: endpoint, method: "POST", body: body) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid request"])))
            return
        }

        sendRequest(request) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                print("Request Error in completeTodo: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }


}
