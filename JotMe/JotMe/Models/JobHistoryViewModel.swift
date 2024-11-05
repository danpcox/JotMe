//
//  JobHistoryViewModel.swift
//  JotMe
//
//  Created by Dan Cox on 11/5/24.
//

import Foundation
import SwiftUI

class JotHistoryViewModel: ObservableObject {
    @Published var jots: [JotDetails] = [] // Holds the retrieved jots
    @Published var loading = true // Track loading state
    @Published var errorMessage: String? // Display error messages if fetching fails
    private var isFirstLoad = true // Track if this is the first load

    private let authManager: AuthManager

    init(authManager: AuthManager) {
        self.authManager = authManager
    }

    // Fetch jot history only on the first load
    func fetchJotHistoryIfNeeded() {
        guard isFirstLoad else { return }
        fetchJotHistory()
    }

    // Manual refresh for pull-to-refresh action
    func refreshJotHistory() {
        fetchJotHistory()
    }

    // Private function to call the API and load data
    private func fetchJotHistory() {
        loading = true
        let jotAPI = JotAPI(authManager: authManager)
        jotAPI.getJotHistory { result in
            DispatchQueue.main.async {
                self.loading = false
                self.isFirstLoad = false
                switch result {
                case .success(let jots):
                    self.jots = jots
                    self.errorMessage = nil
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
