//
//  ProfileViewController.swift
//  macroChallengeApp
//
//  Created by Beatriz Duque on 08/09/22.
//

import UIKit
import CoreData

protocol SignOutDelegate: AnyObject {
    func reloadScreenStatus()
}

class ProfileViewController: UIViewController, NSFetchedResultsControllerDelegate {
    weak var coordinator: ProfileCoordinator?
    weak var exploreCoordinator: ExploreCoordinator?
    let designSystem: DesignSystem = DefaultDesignSystem.shared
    let profileView = ProfileView()
    var roadmaps: [RoadmapLocal] = []
    var dataManager = DataManager.shared
    // MARK: Cloud User
    var user: User?
    let network: NetworkMonitor = NetworkMonitor.shared
    
    private lazy var fetchResultController: NSFetchedResultsController<RoadmapLocal> = {
        let request: NSFetchRequest<RoadmapLocal> = RoadmapLocal.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \RoadmapLocal.createdAt, ascending: false)]
        let frc = NSFetchedResultsController(fetchRequest: request,
                                             managedObjectContext: RoadmapRepository.shared.context,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        frc.delegate = self
        return frc
    }()

    override func viewDidLoad() {
        // long press gesture
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
        profileView.myRoadmapCollectionView.addGestureRecognizer(longPress)

        self.roadmaps = RoadmapRepository.shared.getRoadmap()
        profileView.roadmaps = self.roadmaps
        
        super.viewDidLoad()
        network.startMonitoring()
        self.view.backgroundColor = .backgroundPrimary
        self.setupProfileView()
        profileView.updateConstraintsCollection()
        
        self.tutorialTimer()
        profileView.tutorialTitle.addTarget(self, action: #selector(tutorial), for: .touchUpInside)
        
        profileView.bindColletionView(delegate: self, dataSource: self)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gearshape.fill"), style: .plain, target: self, action: #selector(profileSettings))
        self.setContextMenu()
        do {
            try fetchResultController.performFetch()
            self.roadmaps = fetchResultController.fetchedObjects ?? []
        } catch {
            fatalError("Não foi possível atualizar conteúdo")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        network.startMonitoring()
        
        if !UserDefaults.standard.bool(forKey: "isUserLoggedIn") { coordinator?.startLogin() }
        self.profileView.updateConstraintsCollection()
        self.profileView.myRoadmapCollectionView.reloadData()
        self.profileView.myRoadmapCollectionView.layoutIfNeeded()

        if let data = UserDefaults.standard.data(forKey: "user") {
            do {
                let decoder = JSONDecoder()
                self.user = try decoder.decode(User.self, from: data)
                if let user = self.user {
                    self.changeToUserInfo(user: user)
                }
                
            } catch {
                print("Unable to decode")
            }
        } else {
            getDataCloud()
        }        
    }
    
    @objc func profileSettings() {
        coordinator?.settings(profileVC: self)
    }
    
    func tutorialTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.profileView.tutorialView.isHidden = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.profileView.tutorialView.removeFromSuperview()
        }
    }
    
    @objc func tutorial() {
        profileView.tutorialView.removeFromSuperview()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // let newRoadmaps = RoadmapRepository.shared.getRoadmap()
        guard let newRoadmaps = controller.fetchedObjects as? [RoadmapLocal] else { return }
        self.roadmaps = newRoadmaps
        profileView.setup()
        profileView.roadmaps = newRoadmaps
        profileView.myRoadmapCollectionView.reloadData()
        profileView.updateConstraintsCollection()
        
    }
    
    // MARK: Manage Data Cloud
    func getDataCloud() {
        if let data = KeychainManager.shared.read(service: "username", account: "explorer") {
            let userID = String(data: data, encoding: .utf8)!
            DataManager.shared.getUser(username: userID, { user in
                self.user = user
                if let user = self.user {
                    self.changeToUserInfo(user: user)
                    do {
                        let encoder = JSONEncoder()

                        let data = try encoder.encode(user)

                        UserDefaults.standard.set(data, forKey: "user")
                    } catch {
                        print("Unable to Encode")
                    }
                }
                
            })
        }
    }
    
    func changeToUserInfo(user: User) {
        self.profileView.getName().text = user.name
        self.profileView.getUsernameApp().text = "@\(user.usernameApp)"
        self.profileView.getTable().reloadData()
        self.profileView.getImage().image = UIImage(named: "icon")
        _ = UserRepository.shared.createUser(user: user)
    }
}

extension ProfileViewController: SignOutDelegate {
    func reloadScreenStatus() {
        self.coordinator?.backPage()
    }
}
