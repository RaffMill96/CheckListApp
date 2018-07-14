//
//  TodayViewController.swift
//  Widget
//
//  Created by R.M.R on 7/13/18.
//  Copyright © 2018 Jeremy Fleshman. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet weak var widgetLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        widgetLabel.numberOfLines = 0;
        // Do any additional setup after loading the view from its nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        let groupDefaults = UserDefaults(suiteName: "group.com.rafmillan.checklists")
        
        if let extensionText = groupDefaults?.value(forKey: "extensionText") as? String
        {
            widgetLabel.text = extensionText;
        }
        
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
}
