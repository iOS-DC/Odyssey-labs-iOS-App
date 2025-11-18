//
//  ProfileStep1ViewController.swift
//  UniRide
//
//  Created by Krish Bahukhandi on 16/11/25.
//

import UIKit

class ProfileStep1ViewController: UIViewController {

    @IBOutlet weak var dropDownButton: UIButton! // Connect your UIButton here

    @IBOutlet weak var yearDropDownButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCourseDropDownMenu()
        setupYearDropDownMenu()
    }

    func setupCourseDropDownMenu() {
        // 1. Define the options
        let options = ["CSE", "ECE", "Mechanical", "Civil", "Electrical", "Arts","Chemical Engineering","Reset"]
        
        // 2. Create UIAction for each option
        let menuActions = options.map { option in
            return UIAction(title: option) { action in
                // This block runs when an option is selected
                print("Selected: \(action.title)")
                
                // Update the button's title to show the selected option
                self.dropDownButton.setTitle(action.title, for: .normal)
                
                // You can add logic specific to an option if needed
                if action.title == "Reset" {
                    // Perform reset logic
                }
            }
        }
        
        // 3. Create UIMenu from the actions
        let menu = UIMenu(title: "Select your course", children: menuActions)
        
        // 4. Assign the menu to the button
        dropDownButton.menu = menu
        
        // This ensures the button's title changes to the selected option
        dropDownButton.changesSelectionAsPrimaryAction = true
    }
        
    func setupYearDropDownMenu() {
        // 1. Define the options
        let options = ["1", "2", "3", "4"]
        
        // 2. Create UIAction for each option
        let menuActions = options.map { option in
            return UIAction(title: option) { action in
                // This block runs when an option is selected
                print("Selected: \(action.title)")
                
                // Update the button's title to show the selected option
                self.yearDropDownButton.setTitle(action.title, for: .normal)
                
                // You can add logic specific to an option if needed
                if action.title == "Reset" {
                    // Perform reset logic
                }
            }
        }
        
        // 3. Create UIMenu from the actions
        let menu = UIMenu(title: "Select your year", children: menuActions)
        
        // 4. Assign the menu to the button
        yearDropDownButton.menu = menu
        
        // This ensures the button's title changes to the selected option
        yearDropDownButton.changesSelectionAsPrimaryAction = true
        
    }
        

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
