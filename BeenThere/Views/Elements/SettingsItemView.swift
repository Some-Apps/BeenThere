//
//  SettingsItemView.swift
//  BeenThere
//
//  Created by Jared Jones on 12/15/23.
//

import SwiftUI

struct SettingsItemView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let icon: Image
    let text: String
    let destinationID: DestinationID
    @Binding var navigationPath: NavigationPath

    var body: some View {
        Button {
            navigationPath.append(destinationID)
        } label: {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundStyle(Color(uiColor: UIColor(red: 0.29, green: 0.47, blue: 0.94, alpha: 1)))
                        .frame(width: 45, height: 45)
                    icon
                        .font(.title)
                        .foregroundStyle(Color.mutedPrimary)
                }
                
                Text(text)
                    .foregroundStyle(colorScheme == .light ? .black : .white)
                    .padding(.leading)
                Spacer()
            }
            .padding(.vertical, 5)
        }
    }
}


//#Preview {
//    SettingsItemView(icon: Image(systemName: "person"), text: "Profile", destination: EditProfileView())
//}
