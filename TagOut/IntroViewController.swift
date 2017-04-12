//
//  IntroViewController.swift
//  TagOut
//
//  Created by Maxim Kuzmenko on 2017-04-10.
//  Copyright © 2017 Maxim Kuzmenko. All rights reserved.
//

import UIKit

//IntroViewController: Class is responsible for showing the main image, as well as asking the user for a username
class IntroViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    weak var nameAction : UIAlertAction?
    var name: String = "";
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = #imageLiteral(resourceName: "fullSize"); //set image to intro image
        imageView.frame = self.view.frame
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false;
    }

    override func viewDidAppear(_ animated: Bool) { //as soon as view is loaded, prompt the user for their username
        promptForUsername();
    }
    
    func promptForUsername() {
        let alert = UIAlertController(title: "Welcome!", message: "Enter Username Below", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addTextField(configurationHandler: {(textField: UITextField) in
            textField.placeholder = "Enter User Name Here"
            textField.addTarget(self, action: #selector(self.textChanged(_:)), for: .editingChanged)
        })
        
        let action = UIAlertAction(title: "Done!", style: UIAlertActionStyle.default, handler: { (_) -> Void in
            let textfield = alert.textFields!.first!
            self.name = textfield.text!;
            self.performSegue(withIdentifier: "showMaster", sender: self)
        })
        
        alert.addAction(action)
        
        self.nameAction = action
        action.isEnabled = false
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc private func textChanged(_ sender:Any) {
        let text = (sender as! UITextField).text
        self.nameAction?.isEnabled = (text! != "") // check if nothing entered.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) { //pass the username when segue occurs
        if (segue.identifier == "showMaster") {
            let destinationVC :MasterViewController = segue.destination as! MasterViewController
            destinationVC.userName = name
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
