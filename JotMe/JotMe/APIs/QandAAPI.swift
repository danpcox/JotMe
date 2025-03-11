//
//  QandAAPI.swift
//  JotMe
//
//  Created by Dan Cox on 3/11/25.
//


import Foundation

class QandAAPI: BaseAPI {
    init(authManager: AuthManager) {
        super.init(baseURL: "https://www.e-overhaul.com/jotme", authManager: authManager)
    }

    func askQuestion(question: String, completion: @escaping (Result<QandAResponse, Error>) -> Void) {
        let endpoint = "/qa/askQuestion.php" // Adjust this as needed for your backend.
        let parameters: [String: Any] = ["question": question]

        guard let request = createRequest(endpoint: endpoint, method: "POST", body: parameters) else {
            completion(.failure(NSError(domain: "", code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid request."])))
            return
        }

        sendRequest(request) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(QandAResponse.self, from: data)
                    completion(.success(response))
                } catch {
                    print("Failed to decode QandA response: \(error)")
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
