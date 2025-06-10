import SwiftUI

/// Authentication view for sign-in and sign-up
struct AuthenticationView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    
    var body: some View {
        VStack(spacing: 30) {
            // App logo and title
            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("LifeManager")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("AI-Powered PARA Productivity System")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // Authentication form
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    if !isSignUp {
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.password)
                    }
                }
                
                // Error message
                if let errorMessage = viewModel.authError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                
                // Sign in/up buttons
                VStack(spacing: 12) {
                    if isSignUp {
                        Button("Send Magic Link") {
                            Task {
                                await viewModel.signInWithMagicLink(email: email)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(email.isEmpty || viewModel.isLoading)
                        
                        Text("We'll send you a secure sign-in link")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Button("Sign In") {
                            Task {
                                await viewModel.signIn(email: email, password: password)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(email.isEmpty || password.isEmpty || viewModel.isLoading)
                    }
                    
                    Button(isSignUp ? "Already have an account? Sign In" : "New user? Get Magic Link") {
                        isSignUp.toggle()
                        viewModel.authError = nil
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.blue)
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .frame(maxWidth: 300)
            
            Spacer()
            
            // Features preview
            VStack(spacing: 12) {
                Text("Features")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 8) {
                    FeatureRow(icon: "brain", title: "AI-Powered Organization", description: "Automatic PARA categorization")
                    FeatureRow(icon: "target", title: "Natural Language Input", description: "Just type what you need to do")
                    FeatureRow(icon: "magnifyingglass", title: "Smart Search", description: "Find anything across all content")
                    FeatureRow(icon: "archivebox", title: "Complete History", description: "Never lose track of anything")
                }
            }
            .frame(maxWidth: 400)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

/// Feature row for authentication screen
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(MainViewModel())
} 