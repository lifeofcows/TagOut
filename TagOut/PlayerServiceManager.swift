import Foundation
import MultipeerConnectivity
import CoreLocation

protocol PlayerServiceManagerDelegate {
    func connectedDevicesChanged(connectedDevices: [String])
    func roomsChanged(rooms: [[String: [String]]])
    func getRooms()->[[String: [String]]];
    func gameBegin();
}

class PlayerServiceManager : NSObject {
    // Service type must be a unique string, at most 15 characters long
    // and can contain only ASCII lowercase letters, numbers and hyphens.
    private let PlayerServiceType = "tagout-service"
    
    private var myPeerId: MCPeerID;// = MCPeerID(displayName: UIDevice.current.name);
    
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
    
    init(name: String) {
        myPeerId = MCPeerID(displayName: name);
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
    }
   
    func send(obj : Any, peerStr: String) {
        if session.connectedPeers.count > 0 {
            do {
                //let string = String(data: obj as! Data, encoding: .ascii)!
                let json = try? JSONSerialization.data(withJSONObject: ["OBJ": obj], options: [])
                if peerStr == "" { //if peer name not given, assume to message all connected peers
                    try self.session.send(json!, toPeers: session.connectedPeers, with: .reliable)
                }
                else {
                    for peer in session.connectedPeers {
                        if peer.displayName == peerStr {
                            try self.session.send(json!, toPeers: [peer], with: .reliable)
                        }
                    }
                }
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
                send(obj: (delegate?.getRooms())!, peerStr: "");
            }
            print("connectedPeers are: ")
        }
        NSLog("%@", "peer \(peerID) didChangeState: \(stateStr): \(state.rawValue)")
        
        self.delegate?.connectedDevicesChanged(connectedDevices:
            session.connectedPeers.map{$0.displayName})
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data)")        
        let fromJson = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        if let requester = fromJson?["OBJ"] as? String { //send coordinate data to requester
            let coords = (GameViewController.instance?.coordinates[(MasterViewController.instance?.userName)!])! as! CLLocationCoordinate2D;
            let dict = ["LATITUDE": coords.latitude, "LONGITUDE": coords.longitude, "NAME" : (MasterViewController.instance?.userName)!] as [String : Any]
            send(obj: dict as Any, peerStr: requester);
        }
        else if let coordinates = fromJson?["OBJ"] as? [String: Any] {
            let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(coordinates["LATITUDE"] as! CLLocationDegrees, coordinates["LONGITUDE"] as! CLLocationDegrees);
            GameViewController.instance?.coordinates[coordinates["NAME"] as! String] = coordinate
        }
        else if let roomObject = (fromJson?["OBJ"] as? [[String: [String]]]) { //send room update
            self.delegate?.roomsChanged(rooms: roomObject)
        }
        else if let _ = fromJson?["OBJ"] as? Bool {  //game began
            self.delegate?.gameBegin()
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
