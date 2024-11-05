//
//  JotAPI.swift
//  JotMe
//
//  Created by Dan Cox on 11/5/24.
//

import Foundation

struct JotResponse: Codable {
    let success: Bool
    let message: String
    let jot: JotDetails
}

struct JotDetails: Codable {
    let id: Int
    let jot_text: String
    let created_at: String
}

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
}
