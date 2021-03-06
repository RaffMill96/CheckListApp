//
//  AllListsViewController.swift
//  Checklists
//
//  Created by Rafael Millan on 7/13/18.
//  Copyright © 2018 Rafael Millan. All rights reserved.
//

import UIKit

class AllListsViewController: UITableViewController,
                              ListDetailViewControllerDelegate,
                              UINavigationControllerDelegate {
    var dataModel: DataModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundView = UIImageView(image: UIImage(named: "background.jpg"))

        // seems this should only be set for the initial parent view
        // and additional vcs in the stack should only set the 'navigationItem' prop
        navigationController?.navigationBar.prefersLargeTitles = true
        
        //DEBUG: output documents directory
        //print(documentsDirectory())
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .white
    }
    
    //adding viewDidAppear() to handle saving last checklist viewed -- UX improvement
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //set the nav controller delegate to this VC
        navigationController?.delegate = self
        
        //grab the stored index
//        let index = UserDefaults.standard.integer(forKey: "ChecklistIndex")
        let index = dataModel.indexOfSelectedChecklist
        
//        if index != -1 {
        // made this a more robust check to resolve crash when UserDefaults became out of sync with dataModel
        if index >= 0 && index < dataModel.lists.count {
            // set appropriate checklist by index
            let checklist = dataModel.lists[index]
            // segue to correct checklist
            performSegue(withIdentifier: "ShowChecklist", sender: checklist)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // reloading table view to update the "remaining" count
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataModel.lists.count
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //storing the row indexpath in user defaults to persist current viewed checklist if app terminates
//        UserDefaults.standard.set(indexPath.row, forKey: "ChecklistIndex")
        dataModel.indexOfSelectedChecklist = indexPath.row
        
        // store the current checklist object so that it can be passed to the Checklist View Controller
        let checklist = dataModel.lists[indexPath.row]
        // manually segue to the checklist VC
        performSegue(withIdentifier: "ShowChecklist", sender: checklist) // establishes the sender prop on 'self'
    }
    
    // configuring cells to be drawn
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = makeCell(for: tableView)
        let countMessage: String
        
        // get checklist item from data source to configure cell
        let checklist = dataModel.lists[indexPath.row]
        cell.textLabel!.text = checklist.name
        cell.accessoryType = .detailButton
        
        //setting subtitle message for Checklist cells
        if checklist.items.count == 0 {
            countMessage = "(No Items)"
        } else if checklist.countItems() == 0 {
            countMessage = "All Done!"
        } else {
            countMessage = "\(checklist.countItems()) Remaining"
        }
        cell.detailTextLabel!.text = countMessage
        
        return cell
    }
    
    // delegate method to allow 'swipe-to-delete'
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        //remove the object from the data source array
        dataModel.lists.remove(at: indexPath.row)
        //delete rows from the tableView
        let indexPaths = [indexPath]
        tableView.deleteRows(at: indexPaths, with: .automatic)
    }
    
    //loading a view controller from code instead of an IB segue
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        //create controller
        let controller = storyboard!.instantiateViewController(withIdentifier: "ListDetailViewController") as! ListDetailViewController
        
        //set delegate
        controller.delegate = self
        
        // set the 'ChecklistToEdit' object
        let checklist = dataModel.lists[indexPath.row]
        controller.checklistToEdit = checklist
        
        // push new VC to nav stack
        navigationController?.pushViewController(controller, animated: true)
    }
    
    // method allows parent VC to set up initial data for new VC before it renders
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // verify that the segue is from checklists to a specific checklist
        if segue.identifier == "ShowChecklist" {
            // grab a reference to the destination segue and cast as the proper VC
            let controller = segue.destination as! ChecklistViewController
            // finally, set the exposed 'checklist' var in the Checklist VC to the sender 'Checklist' object
            controller.checklist = sender as! Checklist
        } else if segue.identifier == "AddChecklist" {
            // set ListDetailViewController as the destination
            let controller = segue.destination as! ListDetailViewController
            // set self as delegate
            controller.delegate = self
        }
    }
    
    func makeCell(for tableView: UITableView) -> UITableViewCell {
        let cellIdentifier = "Cell"
        
        // returns recyclable cell for reuse if a reusable cell exists
        if let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) {
            return cell
        } else {
        // returns a new recyclable cell
            return UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }
    }
    
    // MARK: - ListDetailViewDelegate Methods
    func listDetailViewControllerDidCancel(_ controller: ListDetailViewController) {
        navigationController?.popViewController(animated: true)
    }
    
    func listDetailViewController(_ controller: ListDetailViewController, didFinishAdding checklist: Checklist) {
        // updated algorithm with a reload to avoid manual updating
        dataModel.lists.append(checklist)
        dataModel.sortChecklists()
        // replaced manually updating UI with a reload
        // will call the delegates to recreate the cells from the data source again
        tableView.reloadData()
        navigationController?.popViewController(animated: true)
    }
    
    // TODO: - REVIEW HOW THIS WORKS
    func listDetailViewController(_ controller: ListDetailViewController, didFinishEditing checklist: Checklist) {
        dataModel.sortChecklists()
        // reload replaces having to update in place -> less performant at scale?
        tableView.reloadData()
        navigationController?.popViewController(animated: true)
    }

    // MARK: - UINavigationControllerDelegate methods
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        // checks if the back button is tapped
        // sets the "remembered index" to an invalid value (UserDefaults does not support optionals)
        // whenever the nav VC stack currently shows the initial view(AllListsVC VC)
//        if navigationController.visibleViewController === self {
        if viewController === self {
//            UserDefaults.standard.set(-1, forKey: "ChecklistIndex")
            dataModel.indexOfSelectedChecklist = -1
        }
    }
}
