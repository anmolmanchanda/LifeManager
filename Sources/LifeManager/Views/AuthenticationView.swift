import SwiftUI

/// Authentication view for sign-in and sign-up
struct AuthenticationView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var callbackUrl = ""
    @State private var isProductionTesting = false // Toggle for real auth testing
    @FocusState private var focusedField: Field?
    
    enum Field: CustomStringConvertible {
        case email, password
        
        var description: String {
            switch self {
            case .email: return "email"
            case .password: return "password"
            }
        }
    }
    
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
                    TextField("Enter your email address", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($focusedField, equals: .email)
                        .disabled(viewModel.isLoading)
                        .onTapGesture {
                            focusedField = .email
                        }
                    
                    if !isSignUp {
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($focusedField, equals: .password)
                            .disabled(viewModel.isLoading)
                            .onTapGesture {
                                focusedField = .password
                            }
                    }
                }
                
                // Error message
                if let errorMessage = viewModel.authError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                
                // Success message
                if let successMessage = viewModel.authSuccess {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                
                // Development bypass section - always visible
                VStack(spacing: 8) {
                    Divider()
                    
                    HStack {
                        Text("Testing Mode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Toggle("Production Auth", isOn: $isProductionTesting)
                            .toggleStyle(.switch)
                            .scaleEffect(0.8)
                    }
                    
                    if isProductionTesting {
                        VStack(spacing: 6) {
                            Text("✅ Testing Real Supabase Auth")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            // Manual callback for magic links
                            VStack(spacing: 4) {
                                Text("📧 Email Link Not Working?")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                
                                Text("1. Right-click the email link → Copy Link\n2. Paste the FULL copied URL below:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                                
                                TextField("Paste magic link URL here (if needed)", text: $callbackUrl)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.caption)
                                
                                if !callbackUrl.isEmpty {
                                    Button("Process Magic Link") {
                                        Task {
                                            await processManualCallback()
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .font(.caption)
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 6) {
                            Text("🧪 Development Mode")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            // Manual callback for magic links
                            VStack(spacing: 4) {
                                Text("📧 Email Link Not Working?")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                
                                Text("1. Right-click the email link → Copy Link\n2. Paste the FULL copied URL below:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                                
                                TextField("Paste magic link URL here (if redirected to localhost)", text: $callbackUrl)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.caption)
                                
                                if !callbackUrl.isEmpty {
                                    Button("Process Magic Link") {
                                        Task {
                                            await processManualCallback()
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .font(.caption)
                                }
                            }
                            
                            // Development sign-in bypass
                            HStack(spacing: 8) {
                                Button("Skip Authentication (Development)") {
                                    viewModel.enableDevelopmentBypass()
                                }
                                .buttonStyle(.borderless)
                                .foregroundColor(.orange)
                                .font(.caption2)
                                
                                Button("Force Create Dev Account") {
                                    Task {
                                        await viewModel.forceCreateDevAccount()
                                    }
                                }
                                .buttonStyle(.borderless)
                                .foregroundColor(.green)
                                .font(.caption2)
                            }
                        }
                    }
                }
                .padding(.top, 8)
                
                // Sign in/up buttons
                VStack(spacing: 12) {
                    if isSignUp {
                        Text("Magic Link Sign In")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
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
                        
                        // Manual callback for testing
                        if viewModel.isLoading {
                            VStack(spacing: 8) {
                                Text("Check your email and click the magic link")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                
                                Text("Or use the manual callback section below if redirected to localhost")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 8)
                        }
                    } else {
                        Text("Account Management")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 8) {
                        Button("Sign In") {
                            Task {
                                await viewModel.signIn(email: email, password: password)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(email.isEmpty || password.isEmpty || viewModel.isLoading)
                            
                            Button("Create New Account") {
                                Task {
                                    await viewModel.signUp(email: email, password: password)
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(email.isEmpty || password.isEmpty || viewModel.isLoading)
                        }
                        
                        Text("Use any email/password to create an account")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Quick test account for development
                        Divider()
                            .padding(.vertical, 8)
                        
                        VStack(spacing: 4) {
                            Text("Quick Test Account")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button("Use Test Account") {
                                email = "dev@lifemanager.local"
                                password = "DevPass123!"
                                Task {
                                    // Try to sign in first, if that fails, create account
                                    await viewModel.signIn(email: email, password: password)
                                    
                                    // If sign in failed, try creating the account
                                    if !viewModel.isAuthenticated {
                                        await viewModel.signUp(email: email, password: password)
                                    }
                                }
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.blue)
                            .font(.caption)
                        }
                    }
                    
                    HStack(spacing: 16) {
                        Button(isSignUp ? "Back to Password Sign In" : "Use Magic Link Instead") {
                            isSignUp.toggle()
                            viewModel.authError = nil
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.blue)
                        
                        if !isSignUp {
                            Button("Reset Password") {
                                Task {
                                    await viewModel.resetPassword(email: email)
                                }
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.orange)
                            .disabled(email.isEmpty)
                        }
                    }
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
        .onAppear {
            // Auto-focus email field when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedField = .email
            }
        }
    }
    
    private func processManualCallback() async {
        var urlToProcess = callbackUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If user pasted just the scheme without parameters, guide them
        if urlToProcess == "lifemanager://auth/callback" || urlToProcess.isEmpty {
            viewModel.authError = "Please paste the FULL URL from the email link, including any parameters after '?'"
            return
        }
        
        // Check if this is a Supabase verification URL
        if urlToProcess.contains("supabase.co/auth/v1/verify") {
            viewModel.authError = "This is a verification URL. Please:\n1. Open this URL in Safari first\n2. Safari will try to redirect to the app\n3. If that fails, copy the final redirect URL and paste it here"
            
            // Optionally open the URL in browser automatically
            if let url = URL(string: urlToProcess) {
                #if os(macOS)
                NSWorkspace.shared.open(url)
                #endif
            }
            return
        }
        
        // Handle localhost redirect by converting to our custom scheme
        if urlToProcess.contains("localhost:3000") {
            // Extract the code parameter
            if let url = URL(string: urlToProcess),
               let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems,
               let code = queryItems.first(where: { $0.name == "code" })?.value {
                // Convert to our custom scheme
                urlToProcess = "lifemanager://auth/callback?code=\(code)"
            } else {
                viewModel.authError = "Could not extract authentication code from localhost URL"
                return
            }
        }
        
        // Validate URL format
        guard let url = URL(string: urlToProcess) else {
            viewModel.authError = "Invalid URL format. Please check and try again."
            return
        }
        
        // Check if URL has required parameters
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              !queryItems.isEmpty else {
            viewModel.authError = "URL missing authentication parameters. Please copy the complete link from your email."
            return
        }
        
        do {
            try await SupabaseService.shared.handleMagicLinkCallback(url: url)
            viewModel.authError = nil
            viewModel.authSuccess = "✅ Successfully authenticated!"
            callbackUrl = "" // Clear the field on success
        } catch {
            viewModel.authError = "Failed to process callback: \(error.localizedDescription)"
        }
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