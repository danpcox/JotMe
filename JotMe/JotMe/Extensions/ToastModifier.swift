//
//  ToastModifier.swift
//  JotMe
//
//  Created by Dan Cox on 11/5/24.
//

import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    var message: String

    func body(content: Content) -> some View {
        ZStack {
            content
            if isShowing {
                VStack {
                    Spacer()
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(10)
                        .padding(.bottom, 20)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.5), value: isShowing)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isShowing = false
                    }
                }
            }
        }
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, message: String) -> some View {
        self.modifier(ToastModifier(isShowing: isShowing, message: message))
    }
}
