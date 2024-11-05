//
//  JotAPI.swift
//  JotMe
//
//  Created by Dan Cox on 11/5/24.
//

import Foundation

class JotAPI: BaseAPI {
    init(authManager: AuthManager) {
        // Pass authManager to BaseAPI for authorization handling
        super.init(baseURL: "https://www.e-overhaul.com/jotme", authManager: authManager)
    }

    // Function to post the transcribed jot data
    func addJot(transcribedText: String, completion: @escaping (Result<Data, Error>) -> Void) {
        // Define the endpoint and the parameters
        let endpoint = "/jots/addJotForUser.php"
        let jotData: [String: Any] = ["jotText": transcribedText]
        
        // Create the request
        guard let request = createRequest(endpoint: endpoint, method: "POST", body: jotData) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid request"])))
            return
        }

        // Send the request
        sendRequest(request) { result in
            switch result {
            case .success(let data):
                print("Successfully posted jot: \(transcribedText)")
                completion(.success(data))
            case .failure(let error):
                print("Error posting jot: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}
