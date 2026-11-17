import SwiftUI

struct EditProfileView: View {
    
    @Environment(BayanihanController.self) private var controller
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var username = ""
    @State private var email = ""
    @State private var location = ""

    @State private var showSaveAlert = false
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    
    var body: some View {
        
        ZStack {
            
            Color(
                red: 0.95,
                green: 0.98,
                blue: 0.97
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                
                VStack(
                    alignment: .leading,
                    spacing: 0
                ) {
                    
                    // MARK: - Profile Icon
                    
                    VStack(spacing: 8) {
                        
                        ZStack {
                            
                            Circle()
                                .fill(
                                    Color(
                                        red: 0.84,
                                        green: 0.93,
                                        blue: 0.90
                                    )
                                )
                            
                            Text(
                                initials(
                                    name.isEmpty
                                        ? controller.currentUser.name
                                        : name
                                )
                            )
                            .font(
                                .system(
                                    size: 24,
                                    weight: .bold
                                )
                            )
                            .foregroundStyle(
                                Color(
                                    red: 0.00,
                                    green: 0.55,
                                    blue: 0.45
                                )
                            )
                        }
                        .frame(
                            width: 78,
                            height: 78
                        )
                        
                        Text("Your Profile")
                            .font(
                                .system(
                                    size: 18,
                                    weight: .bold
                                )
                            )
                            .foregroundStyle(.black)
                    }
                    .frame(
                        maxWidth: .infinity
                    )
                    .padding(.top, 22)
                    
                    
                    // MARK: - Name
                    
                    Text("Full Name")
                        .font(
                            .system(
                                size: 14,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.black)
                        .padding(.top, 25)
                    
                    TextField(
                        "Enter your full name",
                        text: $name
                    )
                    .font(.system(size: 15))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12)
                    .frame(height: 45)
                    .background(.white)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 11
                        )
                    )
                    .padding(.top, 8)
                    
                    
                    // MARK: - Username
                    
                    Text("Username")
                        .font(
                            .system(
                                size: 14,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.black)
                        .padding(.top, 17)
                    
                    TextField(
                        "Enter your username",
                        text: $username
                    )
                    .font(.system(size: 15))
                    .foregroundStyle(.black)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal, 12)
                    .frame(height: 45)
                    .background(.white)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 11
                        )
                    )
                    .padding(.top, 8)


                    // MARK: - Email

                    Text("Email")
                        .font(
                            .system(
                                size: 14,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.black)
                        .padding(.top, 17)

                    TextField(
                        "Enter your email",
                        text: $email
                    )
                    .font(.system(size: 15))
                    .foregroundStyle(.black)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal, 12)
                    .frame(height: 45)
                    .background(.white)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 11
                        )
                    )
                    .padding(.top, 8)


                    // MARK: - Location

                    Text("Location")
                        .font(
                            .system(
                                size: 14,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.black)
                        .padding(.top, 17)

                    TextField(
                        "Enter your location",
                        text: $location
                    )
                    .font(.system(size: 15))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12)
                    .frame(height: 45)
                    .background(.white)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 11
                        )
                    )
                    .padding(.top, 8)


                    // MARK: - Save
                    
                    Button {
                        saveProfile()
                    } label: {
                        
                        HStack(spacing: 8) {
                            
                            Image(
                                systemName: "checkmark"
                            )
                            
                            Text("Save Changes")
                                .font(
                                    .system(
                                        size: 16,
                                        weight: .bold
                                    )
                                )
                        }
                        .foregroundStyle(.white)
                        .frame(
                            maxWidth: .infinity
                        )
                        .frame(height: 50)
                        .background(
                            Color(
                                red: 0.00,
                                green: 0.55,
                                blue: 0.45
                            )
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 14
                            )
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 23)
                    
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadProfile()
        }
        .alert(
            "Profile Updated",
            isPresented: $showSaveAlert
        ) {
            
            Button("OK") {
                dismiss()
            }
            
        } message: {

            Text("Your profile information has been updated.")
        }
        .alert(
            "Unable to Save Changes",
            isPresented: $showValidationAlert
        ) {

            Button("OK", role: .cancel) {

            }

        } message: {

            Text(validationMessage)
        }
    }
    
    
    // MARK: - Load Profile
    
    private func loadProfile() {
        name = controller.currentUser.name
        username = controller.currentUser.username
        email = controller.currentUser.email
        location = controller.currentUser.location
    }
    
    
    // MARK: - Save Profile
    
    private func saveProfile() {
        
        let cleanName = name
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        
        let cleanUsername = username
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let cleanEmail = email
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let cleanLocation = location
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanName.isEmpty else {
            showValidation(
                "Please enter your name."
            )
            return
        }

        guard !cleanUsername.isEmpty else {
            showValidation(
                "Please enter a username."
            )
            return
        }

        guard !cleanEmail.isEmpty else {
            showValidation(
                "Please enter your email."
            )
            return
        }

        guard !cleanLocation.isEmpty else {
            showValidation(
                "Please enter your location."
            )
            return
        }

        // Phase 2: the Controller/AuthService also checks the username and
        // email format and that no OTHER account already uses them. Any
        // problem is shown in the existing "Unable to Save Changes" alert.
        Task {

            do {
                try await controller.updateProfile(
                    name: cleanName,
                    username: cleanUsername,
                    email: cleanEmail,
                    location: cleanLocation
                )

                showSaveAlert = true

            } catch {
                showValidation(error.localizedDescription)
            }
        }
    }


    // MARK: - Validation

    private func showValidation(
        _ message: String
    ) {
        validationMessage = message
        showValidationAlert = true
    }
    
    
    // MARK: - Initials
    
    private func initials(
        _ name: String
    ) -> String {
        
        let words = name.split(separator: " ")
        
        let letters = words.prefix(2).compactMap {
            $0.first
        }
        
        if letters.isEmpty {
            return "?"
        }
        
        return String(letters)
    }
}


// MARK: - Preview

#Preview {
    
    NavigationStack {
        
        EditProfileView()
            .environment(BayanihanController())
    }
}