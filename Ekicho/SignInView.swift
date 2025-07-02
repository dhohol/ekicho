//
//  SignInView.swift
//  Ekicho
//
//  Created by Daniele Hohol on 6/30/25.
//

import SwiftUI
import AuthenticationServices
import CryptoKit
import FirebaseAuth

struct SignInView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var currentNonce: String?

    var body: some View {
        VStack(spacing: 20) {
            // Logo
            LogoView()
                .padding(.top, 40)
            
            Spacer()
            
            // Sign in button
            VStack(spacing: 16) {
                if authViewModel.isLoading {
                    ProgressView("Setting up your account...")
                        .padding()
                } else {
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            let nonce = randomNonceString()
                            currentNonce = nonce
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = sha256(nonce)
                        },
                        onCompletion: handleSignInWithApple
                    )
                    .frame(height: 45)
                    .signInWithAppleButtonStyle(.black)
                }
                
                if let error = authViewModel.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding()
            
            Spacer()
        }
        .background(Color(.systemBackground))
    }

    private func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authResults):
            guard
                let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential,
                let identityToken = appleIDCredential.identityToken,
                let tokenString = String(data: identityToken, encoding: .utf8),
                let nonce = currentNonce
            else {
                print("❌ Error retrieving token or nonce")
                return
            }

            let credential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: tokenString,
                rawNonce: nonce
            )

            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error = error {
                    print("❌ Firebase sign in failed: \(error.localizedDescription)")
                    return
                }
                print("✅ Signed in as: \(authResult?.user.uid ?? "")")
                // No need to set isSignedIn; AuthViewModel will update automatically
            }

        case .failure(let error):
            print("❌ Sign in with Apple failed: \(error.localizedDescription)")
        }
    }
}

func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: Array<Character> =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            return random
        }

        randoms.forEach { random in
            if remainingLength == 0 { return }
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }

    return result
}

func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashed = SHA256.hash(data: inputData)
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
}
