import Foundation
import MultipeerConnectivity
import CoreLocation

protocol PlayerServiceManagerDelegate {
    func connectedDevicesChanged(connectedDevices: [String])
    func roomsChanged(rooms: [[String: [String]]])
    func getRooms()->[[String: [String]]];
    func gameBegin();
}

//Class: PlayerServiceManager. Responsible for the Multipeer Connectivity; responsible for passing ALL information between different users.
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
        
    }
    
    func send(obj : Any, peerStr: String, type: String) { //function wraps data in a JSON object and sends to designated peers
        if session.connectedPeers.count > 0 {
            do {
                let json = try? JSONSerialization.data(withJSONObject: ["TYPE": type, "OBJ": obj], options: [])
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
//A delegate for the session. Functions implemented below.
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
                //wait half a second before updating
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.send(obj: (self.delegate?.getRooms())!, peerStr: "", type: "UPDATE_ROOMS");
                });
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
        
        let type = fromJson?["TYPE"] as! String //get the type
        
        if type == "GET_COORDS" { //send coordinate data to requester
            let requester = fromJson?["OBJ"] as! String; //sent to user, now the user will send back the requester their coordinates
            let coords = (GameViewController.instance?.coordinates[(MasterViewController.instance?.userName)!])! as! CLLocationCoordinate2D;
            if coords != nil { //if coordinates for the other player haven't been loaded yet, don't send anything
                let dict = ["LATITUDE": coords.latitude, "LONGITUDE": coords.longitude, "NAME" : (MasterViewController.instance?.userName)!] as [String : Any]
                send(obj: dict as Any, peerStr: requester, type: "SEND_COORDS");
            }
        }
        else if type == "SEND_COORDS" { //receives coordinates; updates their coordinates in their GameViewController.
            let coordinates = fromJson?["OBJ"] as! [String: Any];
            let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(coordinates["LATITUDE"] as! CLLocationDegrees, coordinates["LONGITUDE"] as! CLLocationDegrees);
            GameViewController.instance?.coordinates[coordinates["NAME"] as! String] = coordinate
        }
        else if type == "UPDATE_LIVES" { //players receive lives update.
            let playerLives = fromJson?["OBJ"] as! [String: Int];
            if (GameViewController.instance != nil) {
                GameViewController.instance?.playerLives = playerLives;
            }
        }
        else if type == "UPDATE_ROOMS" { //send room update
            let roomObject = fromJson?["OBJ"] as! [[String: [String]]];
            self.delegate?.roomsChanged(rooms: roomObject);
        }
        else if type == "GAME_BEGIN" {  //game began
            self.delegate?.gameBegin()
        }
        else { //other object. If reaches here then there is an error!
            print("OTHER. ERROR!");
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
