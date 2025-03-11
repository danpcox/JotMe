//
//  BaseAPI.swift
//  JotMe
//
//  Created by Dan Cox on 11/5/24.
//

import Foundation
import GoogleSignIn

class BaseAPI {
    let baseURL: String
    let authManager: AuthManager // Store the AuthManager instance

    // Constants for multipart/form-data
    let boundary = "Boundary-\(UUID().uuidString)"
    let lineBreak = "\r\n"

    // Modify initializer to accept authManager instead of individual arguments
    init(baseURL: String, authManager: AuthManager) {
        self.baseURL = baseURL
        self.authManager = authManager
    }

    // Function to create a URL request (POST or GET)
    func createRequest(endpoint: String, method: String = "GET", body: [String: Any]? = nil) -> URLRequest? {
        // Handle relative endpoints
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type") // Form-encoded data

        // Add authorization header if your API requires it
        if let token = authManager.googleAccessToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Add user email and userId to the request body along with any other parameters
        var finalBody = body ?? [:]
        finalBody["userEmail"] = authManager.userEmail // Add userEmail from authManager
        finalBody["userId"] = authManager.userId ?? 0  // Add userId from authManager

        // Serialize body as form-encoded data for POST/PUT requests
        if method == "POST" || method == "PUT" {
            let formData = finalBody.compactMap { key, value -> String in
                guard let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                    return ""
                }
                return "\(key)=\(escapedValue)"
            }.joined(separator: "&")
            print("Final Request body: \(formData)")
            request.httpBody = formData.data(using: .utf8) // Convert the form data to Data
        }
        print("Final URL Request: \(url)")

        return request
    }

    // **Modified Function: Create Multipart/Form-Data Request**
    /// Creates a URLRequest configured for multipart/form-data.
    /// Automatically includes `userEmail` and `userId` in the form fields.
    /// - Parameters:
    ///   - endpoint: The API endpoint.
    ///   - method: HTTP method (e.g., "POST").
    ///   - parameters: Dictionary of additional form fields.
    ///   - fileData: Data of the file to upload.
    ///   - fileName: Name of the file (e.g., "image.jpg").
    ///   - mimeType: MIME type of the file (e.g., "image/jpeg").
    /// - Returns: Configured URLRequest or nil if failed.
    func createMultipartFormDataRequest(endpoint: String,
                                        method: String = "POST",
                                        parameters: [String: Any],
                                        fileData: Data,
                                        fileName: String,
                                        mimeType: String) -> URLRequest? {
        // Handle absolute URLs differently
        let urlString: String
        if endpoint.starts(with: "http://") || endpoint.starts(with: "https://") {
            urlString = endpoint
        } else {
            urlString = "\(baseURL)\(endpoint)"
        }

        guard let url = URL(string: urlString) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Add authorization header if required
        if let token = authManager.googleAccessToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // **Automatically Include `userEmail` and `userId`**
        var finalParameters = parameters
        finalParameters["userEmail"] = authManager.userEmail // Add userEmail from authManager
        finalParameters["userId"] = authManager.userId ?? 0  // Add userId from authManager

        // Start constructing the HTTP body
        var body = Data()

        // Append form fields
        for (key, value) in finalParameters {
            body.append("--\(boundary)\(lineBreak)")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak)\(lineBreak)")
            body.append("\(value)\(lineBreak)")
        }

        // Append the file data
        body.append("--\(boundary)\(lineBreak)")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\(lineBreak)")
        body.append("Content-Type: \(mimeType)\(lineBreak)\(lineBreak)")
        body.append(fileData)
        body.append(lineBreak)

        // End the multipart/form-data
        body.append("--\(boundary)--\(lineBreak)")

        request.httpBody = body

        return request
    }

    // Existing sendRequest function...
    func sendRequest(_ request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network-level errors
            if let error = error {
                if let data = data, let rawOutput = String(data: data, encoding: .utf8) {
                    print("Raw API error response: \(rawOutput)")
                }
                completion(.failure(error))
                return
            }

            // Ensure we have a valid HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError.invalidResponse))
                return
            }
            
            // Log raw output if status code is not in the success range
            if !(200...299).contains(httpResponse.statusCode),
               let data = data,
               let rawOutput = String(data: data, encoding: .utf8) {
                print("Raw API error response (status code \(httpResponse.statusCode)):\n\(rawOutput)")
            }
            
            // Handle specific HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                if let data = data {
                    completion(.success(data))
                } else {
                    completion(.failure(APIError.noData))
                }
                
            case 401:
                print("Token expired, attempting to refresh...")
                self.refreshToken { success in
                    if success {
                        guard let originalURL = request.url?.absoluteString else {
                            completion(.failure(APIError.invalidRequestURL))
                            return
                        }
                        guard let newRequest = self.createRequest(endpoint: originalURL, method: request.httpMethod ?? "GET") else {
                            completion(.failure(APIError.invalidRequest))
                            return
                        }
                        self.sendRequest(newRequest, completion: completion) // Retry the request
                    } else {
                        completion(.failure(APIError.tokenRefreshFailed))
                    }
                }
                
            case 400:
                completion(.failure(APIError.badRequest))
            case 403:
                completion(.failure(APIError.forbidden))
            case 404:
                completion(.failure(APIError.notFound))
            case 500...599:
                completion(.failure(APIError.serverError(statusCode: httpResponse.statusCode)))
            default:
                completion(.failure(APIError.unhandledStatusCode(statusCode: httpResponse.statusCode)))
            }
        }
        task.resume()
    }


    // Function to refresh the Google token
    func refreshToken(completion: @escaping (Bool) -> Void) {
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error refreshing token: \(error.localizedDescription)")
                    completion(false)
                } else if let user = user {
                    self.authManager.googleAccessToken = user.accessToken.tokenString
                    print("Token refreshed successfully: \(self.authManager.googleAccessToken ?? "No Token")")
                    completion(true)
                } else {
                    print("Unable to refresh token: No user signed in")
                    completion(false)
                }
            }
        }
    }

    // Define your APIError enum
    enum APIError: Error, LocalizedError {
        case invalidURL
        case invalidRequest
        case invalidRequestURL
        case noData
        case invalidResponse
        case tokenRefreshFailed
        case badRequest
        case forbidden
        case notFound
        case serverError(statusCode: Int)
        case unhandledStatusCode(statusCode: Int)
        case apiError(message: String)
        case imageConversionFailed // Added in previous step

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL."
            case .invalidRequest:
                return "Invalid request parameters."
            case .invalidRequestURL:
                return "Invalid request URL."
            case .noData:
                return "No data received from the server."
            case .invalidResponse:
                return "Invalid response from the server."
            case .tokenRefreshFailed:
                return "Unable to refresh token."
            case .badRequest:
                return "Bad request. Please check your input."
            case .forbidden:
                return "Forbidden. You don't have permission to perform this action."
            case .notFound:
                return "Resource not found."
            case .serverError(let statusCode):
                return "Server error with status code: \(statusCode). Please try again later."
            case .unhandledStatusCode(let statusCode):
                return "Received unexpected status code: \(statusCode)."
            case .apiError(let message):
                return message
            case .imageConversionFailed:
                return "Failed to convert the selected image to the desired format."
            }
        }
    }
}

// MARK: - Data Extension to Append String
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
