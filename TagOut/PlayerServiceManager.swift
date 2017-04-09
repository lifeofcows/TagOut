import Foundation
import MultipeerConnectivity

protocol PlayerServiceManagerDelegate {
    func connectedDevicesChanged(manager : PlayerServiceManager, connectedDevices: [String])
    func roomsChanged(manager : PlayerServiceManager, rooms: [[String: [String]]])
    func getRooms()->[[String: [String]]];
}

class PlayerServiceManager : NSObject {

    // Service type must be a unique string, at most 15 characters long
    // and can contain only ASCII lowercase letters, numbers and hyphens.
    private let PlayerServiceType = "tagout-service"
    
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    
    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    private let serviceBrowser : MCNearbyServiceBrowser
    
    var isFirst: Bool = true;
    var Verified: Bool = false;
    var delegate : PlayerServiceManagerDelegate?
    
    lazy var session : MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.none)
        session.delegate = self
        return session
    }()
    
    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: PlayerServiceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: PlayerServiceType)
        
        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5, execute: { //wait for operations to complete on other ends before allowing the creation of a new room
            MasterViewController.instance?.navigationItem.rightBarButtonItem?.isEnabled = true;
        })

        print("started browsing for peers")
    }
    
    func send(rooms : [[String: [String]]]) {
        if session.connectedPeers.count > 0 {
            do {
                let roomData = try? JSONSerialization.data(withJSONObject: rooms, options: [])
                try self.session.send(roomData!, toPeers: session.connectedPeers, with: .reliable)
            }
            catch let error {
                NSLog("%@", "Error for sending: \(error)")
            }
        }
        
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
}

extension PlayerServiceManager : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)
        isFirst = false;
        //send(rooms: (delegate?.getRooms())!); //send rooms to newly connected peer
    }
}

extension PlayerServiceManager : MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer and invitePeer: \(peerID)")
        if (isFirst) { Verified = true; }
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
    }
}


extension PlayerServiceManager : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        var stateStr: String;
        if state.rawValue == 0 {
            stateStr = "Not Connected"
        }
        else if state.rawValue == 1 {
            stateStr = "Connecting..."
        }
        else {
            stateStr = "Connected!"
            if (!Verified) { //a mobile device connected, so send all apps an update in roomData.
                //print("sending data to peers again...");
                send(rooms: (delegate?.getRooms())!);
            }
        }
        NSLog("%@", "peer \(peerID) didChangeState: \(stateStr): \(state.rawValue)")
        
        self.delegate?.connectedDevicesChanged(manager: self, connectedDevices:
            session.connectedPeers.map{$0.displayName})
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data)")
        print("got room data!!");
        if let roomObject = try? JSONSerialization.jsonObject(with: data, options: []) as! [[String: [String]]] {
            self.delegate?.roomsChanged(manager: self, rooms: roomObject)
        }
        else { //other object (position)
            
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveStream")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
    
}
