//
//  Login.swift
//  JotMe
//
//  Created by Dan Cox on 11/5/24.
//

import SwiftUI
import GoogleSignIn

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var userAPI: UserAPI?
    @State private var isSigningIn: Bool = false
    @State private var sparkles: [CGFloat] = Array(repeating: 0, count: 3) // Three sparkles
    @State private var sparkleRotation: [Double] = Array(repeating: 0, count: 3) // State for sparkle rotation
    @State private var sparkleTimer: Timer? // Timer to control the sparkle animations
    @State private var currentSparkleIndex: Int = 0 // Track which sparkle is currently animating

    // Define colors for the sparkles
    private let sparkleColors: [Color] = [.white] // Customize colors here

    var body: some View {
        ZStack {
            // Gradient background from white to black
            LinearGradient(gradient: Gradient(colors: [.white, .black]),
                           startPoint: .top,
                           endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 40) {
                // Welcome text
                Text("Welcome to JotMe!")
                    .font(.largeTitle)
                    .foregroundColor(.black)
                    .bold()

                // Animated logo with sparkle effect
                ZStack {
                    Image("Logo") // Replace "Logo" with your actual image asset name
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 300)

                    ForEach(0..<sparkles.count, id: \.self) { index in
                        // Star sparkle effect
                        StarShape()
                            .foregroundColor(.white) // Sparkle color
                            .frame(width: 25, height: 25) // Adjust size of the star
                            .opacity(sparkles[index]) // Use opacity for sparkling effect
                            .rotationEffect(.degrees(sparkleRotation[index])) // Apply rotation effect
                            .position(getSparklePosition(for: index)) // Position stars
                            .onAppear {
                                // Start the animation sequence when the view appears
                                startSparkleAnimation()
                            }
                    }
                }

                Spacer().frame(height: 40)

                // Show "Logging you in" message or sign-in button
                if isSigningIn {
                    Text("Logging you in...")
                        .frame(width: 200, height: 44)
                        .background(Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                } else {
                    Button(action: {
                        signInWithGoogle()
                    }) {
                        Text("Sign in with Google")
                            .frame(width: 200, height: 44)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Center the content both vertically and horizontally
        }
    }

    // Function to get sparkle positions based on index
    private func getSparklePosition(for index: Int) -> CGPoint {
        let positions = [
            CGPoint(x: 97, y: 184), // Position 1
            CGPoint(x: 185, y: 210), // Position 2
            CGPoint(x: 277, y: 190), // Position 3
        ]
        return positions[index % positions.count]
    }

    // Function to start the sparkle animation sequence
    private func startSparkleAnimation() {
        currentSparkleIndex = 0 // Reset to first sparkle
        sparkleTimer?.invalidate() // Invalidate any existing timers
        
        sparkleTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
            // Animate current sparkle
            animateSparkle(index: currentSparkleIndex)
            
            // Move to the next sparkle
            currentSparkleIndex += 1
            
            // Stop timer when all sparkles have been animated
            if currentSparkleIndex >= sparkles.count {
                timer.invalidate() // Stop the timer
            }
        }
    }

    // Function to animate the sparkle effect
    private func animateSparkle(index: Int) {
        withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            sparkles[index] = 1.0 // Fully visible sparkle
        }

        withAnimation(Animation.linear(duration: 1.2).repeatForever(autoreverses: false)) {
            sparkleRotation[index] = 360 // Rotate continuously
        }
    }

    func signInWithGoogle() {
        isSigningIn = true
        let scopes = ["https://www.googleapis.com/auth/calendar"]
        GIDSignIn.sharedInstance.signIn(withPresenting: getRootViewController(), hint: nil, additionalScopes: scopes) { signInResult, error in
            if let error = error {
                print("Error signing in with Google: \(error.localizedDescription)")
                isSigningIn = false
                return
            }

            guard let user = signInResult?.user else {
                print("Error: User object is nil after sign-in.")
                isSigningIn = false
                return
            }

            authManager.isAuthenticated = true
            authManager.userName = user.profile?.name ?? "User"
            authManager.userEmail = user.profile?.email ?? "No Email Available"
            authManager.googleAccessToken = user.accessToken.tokenString

            print("User email: \(authManager.userEmail)")
            print("Google Access Token: \(authManager.googleAccessToken ?? "No Access Token")")

            userAPI = UserAPI(authManager: authManager)
            let userData: [String: Any] = [
                "userName": authManager.userName,
                "userEmail": authManager.userEmail
            ]

            userAPI?.registerUser(userData: userData) { result in
                switch result {
                case .success(let data):
                    print("User registered successfully: \(data)")
                case .failure(let error):
                    print("Error registering user: \(error.localizedDescription)")
                }
            }

            isSigningIn = false
        }
    }

    func getRootViewController() -> UIViewController {
        let keyWindow = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .map { $0 as? UIWindowScene }
            .compactMap { $0 }
            .first?.windows
            .filter { $0.isKeyWindow }
            .first
        return keyWindow?.rootViewController ?? UIViewController()
    }
}

// Star Shape definition
struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let pointsOnStar = 7 // Increase for a spikier look
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius: CGFloat = min(rect.width, rect.height) / 2
        let adjustment = CGFloat.pi / 2 * 3 // Start at the top

        for i in 0..<pointsOnStar {
            let angle = adjustment + CGFloat(i) * (CGFloat.pi * 2 / CGFloat(pointsOnStar))
            let x = center.x + cos(angle) * radius
            let y = center.y + sin(angle) * radius
            
            // Move to the first point
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }

            // Inner points for spikes
            let innerRadius = radius / 3 // Adjust this value for inner spike length
            let innerAngle = angle + CGFloat.pi / CGFloat(pointsOnStar) // Alternate angles for spikes
            let innerX = center.x + cos(innerAngle) * innerRadius
            let innerY = center.y + sin(innerAngle) * innerRadius
            
            path.addLine(to: CGPoint(x: innerX, y: innerY))
        }
        path.closeSubpath()

        return path
    }
}
