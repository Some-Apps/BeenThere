import SwiftUI
//import Kingfisher

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: ProfileViewModel
    @AppStorage("appState") var appState = "authenticated"
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
//                if let imageUrl = viewModel.profileImageUrl {
//                    KFImage(imageUrl)
//                        .resizable()
//                        .placeholder {
//                            ProgressView()
//                        }
//                        .scaledToFill()
//                        .frame(width: 150, height: 150)
//                        .clipShape(Circle())
//                        .shadow(radius: 10)
//                } else {
//                    Image(systemName: "person.crop.circle")
//                        .resizable()
//                        .scaledToFill()
//                        .frame(width: 150, height: 150)
//                        .clipShape(Circle())
//                        .shadow(radius: 10)
//                }
                VStack(spacing: 10) {
                    Text("@\(viewModel.username)")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(viewModel.locations.count == 1 ? "\(viewModel.locations.count) Chunk Explored" : "\(viewModel.locations.count) Chunks Explored")
                        .fontWeight(.regular)
                        .foregroundStyle(.secondary)
                    Text("(\(Double(viewModel.locations.count) / 1036800 * 100, specifier: "%.3f")% of the Earth)")
                        .fontWeight(.regular)
                        .foregroundStyle(.secondary)
                    SettingsView(navigationPath: $navigationPath)
                        .padding()
                    Button {
                        viewModel.signOut()
                        dismiss()
                        appState = "notAuthenticated"
                    } label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.forward")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .padding(.bottom, 30)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationDestination(for: DestinationID.self) { id in
                            switch id {
                            case editProfileID:
                                EditProfileView()
                            case manageFriendsID:
                                ManageFriendsView()
                            case sharingID:
                                EmptyView()
                            case deleteAccountID:
                                ConfirmDeleteAccountView()
                            default:
                                EmptyView()
                            }
                        }
        }
        
    }
}

struct DestinationID: Hashable {
    let id: String
}

let editProfileID = DestinationID(id: "Edit Profile")
let manageFriendsID = DestinationID(id: "Manage Friends")
let sharingID = DestinationID(id: "Sharing")
let deleteAccountID = DestinationID(id: "Delete Account")

