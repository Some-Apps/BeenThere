import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class LeaderboardViewModel: ObservableObject {
    @Published var me: Person?
    @ObservedObject var authViewModel = AuthViewModel()
    @AppStorage("appState") var appState = ""
    @Published var usernameChanged = false
    @Published var usernameForUID: [String: String] = [:]
    @Published var isFetchingUsernames = false
    @Published var users: [[String: Any]] = []
    @Published var uid = ""
    @Published var newUsername = ""
    @AppStorage("username") var username = ""
    @AppStorage("firstName") var firstName = ""
    @AppStorage("lastName") var lastName = ""
    @AppStorage("lowercaseUsername") var lowercaseUsername = ""
    
    @Published var locations: [Location] = []
    
    @Published var isCheckingUsername: Bool = false
    @Published var isUsernameTaken: Bool = false
    @Published var friends: [[String: Any]] = []
    @Published var sentFriendRequests: [String] = []
    @Published var receivedFriendRequests: [String] = []
    @Published var profileImageUrl: URL?
    @Published var profileImageUrls: [String: URL] = [:]
    
    var userLocations: [Location] {
        let tempLocations = users.flatMap { user -> [Location] in
            guard let locationDictionaries = user["locations"] as? [[String: Double]] else {
                return []
            }
            return locationDictionaries.compactMap {
                guard let lowLatitude = $0["lowLatitude"],
                      let highLatitude = $0["highLatitude"],
                      let lowLongitude = $0["lowLongitude"],
                      let highLongitude = $0["highLongitude"] else {
                    return nil
                }
                return Location(lowLatitude: lowLatitude,
                                highLatitude: highLatitude,
                                lowLongitude: lowLongitude,
                                highLongitude: highLongitude)
            }
        }
        let finalLocations = Array(Set(tempLocations))
        return finalLocations
    }

    private var accountListener: ListenerRegistration?
    var listeners: [ListenerRegistration] = []
    private var db = Firestore.firestore()
    
    var isUsernameValid: Bool {
        let regex = "^[a-zA-Z0-9]{4,15}$"
        return newUsername.range(of: regex, options: .regularExpression) != nil
    }
    var friendList: [Friend] {
        friends.compactMap(Friend.init)
            .sorted(by: { $0.locations.count > $1.locations.count })
    }
 



    
    init() {
        self.setUpFirestoreListener()
    }
    deinit {
        accountListener?.remove()
        for listener in listeners {
            listener.remove()
        }
    }
    
    func updateProfileImages() {
        let uids = users.compactMap { $0["uid"] as? String }
        fetchProfileImageUrls(for: uids)
    }
    
    
    func fetchProfileImageUrls(for uids: [String]) {
        let storageRef = Storage.storage().reference()

        for uid in uids {
            if let cachedUrl = profileImageUrls[uid] {
                // Use cached URL
                continue
            }
            
            let profileImageRef = storageRef.child("\(uid)/profile.jpg")
            profileImageRef.downloadURL { [weak self] url, _ in
                DispatchQueue.main.async {
                    self?.profileImageUrls[uid] = url
                }
            }
        }
    }


    
    func fetchUsernamesForUIDs(uids: [String]) {
            isFetchingUsernames = true
            
            let dispatchGroup = DispatchGroup()
            
            for uid in uids {
                dispatchGroup.enter()
                let userRef = db.collection("users").document(uid)
                userRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        let username = document.data()?["username"] as? String ?? "Unknown"
                        DispatchQueue.main.async {
                            self.usernameForUID[uid] = username
                        }
                    } else {
                        print("Document does not exist")
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.isFetchingUsernames = false
            }
        }
        
        // Call this function when the view appears or the friend requests arrays are updated
        func updateUsernames() {
            let uids = (self.sentFriendRequests + self.receivedFriendRequests)
            fetchUsernamesForUIDs(uids: uids)
        }
    
    func sortedUsersByLocationCount() -> [[String: Any]] {
        return users.sorted { userA, userB in
            let locationsCountA = (userA["locations"] as? [[String: Any]])?.count ?? 0
            let locationsCountB = (userB["locations"] as? [[String: Any]])?.count ?? 0
            return locationsCountA > locationsCountB
        }
    }
    
    func removeListeners() {
        for listener in listeners {
            listener.remove()
        }
    }
    
    func listenForGlobalLeaderboardUpdates() {
        
        let leaderboardRef = db.collection("leaderboards").document("globalLeaderboard")
        
        // This listener will keep updating `users` whenever the globalLeaderboard document changes.
        let listener = leaderboardRef.addSnapshotListener { [weak self] (documentSnapshot, error) in
            if let error = error {
                print("Error fetching global leaderboard: \(error.localizedDescription)")
                return
            }

            guard let document = documentSnapshot, document.exists, let data = document.data(), let users = data["users"] as? [[String: Any]] else {
                print("No global leaderboard found or there was an error.")
                return
            }
            
            self?.users = users.map { user in
                var userData = user
                if let uid = user["uid"] as? String {
                    userData["uid"] = uid
                }
                return userData
            }
            self?.updateProfileImages()
        }
        
        // Add the listener to your listeners array so you can remove it later if needed.
        listeners.append(listener)
    }


    
    func sortedFriendsByLocationCount() -> [[String: Any]] {
        var friendsAndMe = friends
        
        // Convert your [Location] to [[String: Any]]
        let myLocations: [[String: Any]] = locations.map { location in
            do {
                let encodedData = try JSONEncoder().encode(location)
                let dictionary = try JSONSerialization.jsonObject(with: encodedData, options: .allowFragments) as! [String: Any]
                return dictionary
            } catch {
                print("Error encoding location: \(error)")
                return [:]
            }
        }
        
        friendsAndMe.append(["username": self.username, "locations": myLocations, "uid": self.uid, "firstName": self.firstName, "lastName": self.lastName])
        return friendsAndMe.sorted { friendA, friendB in
            let locationsCountA = (friendA["locations"] as? [[String: Any]])?.count ?? 0
            let locationsCountB = (friendB["locations"] as? [[String: Any]])?.count ?? 0
            return locationsCountA > locationsCountB
        }
    }


    
    func fetchFriendsData() {
        print(friends)
        for friend in friends {
            print(friend)
            guard let friendUID = friend["uid"] as? String else { continue }
            
            let friendRef = db.collection("users").document(friendUID)
            
            let listener = friendRef.addSnapshotListener { [weak self] (snapshot, error) in
                guard var data = snapshot?.data() else {
                    print("Failed to fetch data for friend: \(friendUID)")
                    return
                }
                
                data["uid"] = friendUID
                
                if let friendIndex = self?.friends.firstIndex(where: { ($0["uid"] as? String) == friendUID }) {
                    self?.friends[friendIndex] = data
                    self?.me?.friends[friendIndex].id = data["uid"] as? String ?? ""
                    self?.me?.friends[friendIndex].firstName = data["firstName"] as? String ?? ""
                    self?.me?.friends[friendIndex].lastName = data["lastName"] as? String ?? ""
                    self?.me?.friends[friendIndex].username = data["username"] as? String ?? ""
                    self?.me?.friends[friendIndex].locations = data["locations"] as? [[String: Any]] ?? []
                }
            }
            
            listeners.append(listener)
        }
    }


    func setUpFirestoreListener() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user found")
            return
        }
        
        accountListener = db.collection("users").document(userID).addSnapshotListener { [weak self] (documentSnapshot, error) in
            guard let data = documentSnapshot?.data() else {
                print("No data in document")
                return
            }
            
            self?.me?.username = data["username"] as? String ?? ""
            self?.me?.lowercaseUsername = data["lowercaseUsername"] as? String ?? ""
            self?.me?.friends = data["friends"] as? [Friend] ?? []
            self?.me?.id = userID
            self?.me?.sentFriendRequests = data["sentFriendRequests"] as? [String] ?? []
            self?.me?.receivedFriendRequests = data["receivedFriendRequests"] as? [String] ?? []
            self?.me?.firstName = data["firstName"] as? String ?? ""
            self?.me?.lastName = data["lastName"] as? String ?? ""
            
            self?.username = data["username"] as? String ?? ""
            self?.lowercaseUsername = data["lowercaseUsername"] as? String ?? ""
            self?.friends = data["friends"] as? [[String: Any]] ?? []
            self?.uid = userID
            self?.sentFriendRequests = data["sentFriendRequests"] as? [String] ?? []
            self?.receivedFriendRequests = data["receivedFriendRequests"] as? [String] ?? []
            self?.fetchFriendsData()
            self?.firstName = data["firstName"] as? String ?? ""
            self?.lastName = data["lastName"] as? String ?? ""
            


            if let locationData = data["locations"] as? [[String: Any]] {
                self?.locations = locationData.compactMap { locationDict in
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: locationDict, options: [])
                        let location = try JSONDecoder().decode(Location.self, from: jsonData)
                        return location
                    } catch {
                        print("Error decoding location: \(error)")
                        return nil
                    }
                }
            }
        }
        listenForGlobalLeaderboardUpdates()
    }
}
