import SwiftUI
import FirebaseAuth
import AuthenticationServices
import AlertToast

struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: AccountViewModel
    @AppStorage("appState") var appState = "opening"

    @State private var showDeleteAccount = false
    @Binding var navigationPath: NavigationPath

    @Environment(\.dismiss) var dismiss
    
    @State private var userPhoto: Image = Image("background1")
    @State private var isUsernameTaken: Bool = false
    @State private var showFriendView = false
    
    var body: some View {
            VStack(alignment: .leading) {
                SettingsItemView(icon: Image("person"), text: "Edit Profile", destinationID: editProfileID, navigationPath: $navigationPath)
                Divider()
                SettingsItemView(icon: Image("people"), text: "Manage Friends", destinationID: manageFriendsID, navigationPath: $navigationPath)
                Divider()
                SettingsItemView(icon: Image(systemName: "person.slash.fill"), text: "Delete Account", destinationID: deleteAccountID, navigationPath: $navigationPath)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
            )
        
    }
}

//#Preview {
//    SettingsView()
//}
