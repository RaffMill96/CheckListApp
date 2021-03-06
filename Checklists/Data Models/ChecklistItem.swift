//
//  ChecklistItem.swift
//  Checklists
//
//  Created by Rafael Millan on 7/13/18.
//  Copyright © 2018 Rafael Millan. All rights reserved.
//

import Foundation
import UserNotifications

// inherited NSObject to add "equatable" properties to object
// inherited Codable to allow encode/decode (serialization) for saving
class ChecklistItem: NSObject, Codable {
    init(text: String, checked: Bool = false, desc: String) {
        self.text = text
        self.checked = checked
        self.desc = desc
        itemID = DataModel.nextChecklistItemID()
        super.init()
    }
    
    //remove any notifications on the checklist item if its deleted
    deinit {
        removeNotification()
    }
    
    var text = ""
    var checked = false
    var dueDate = Date()
    var shouldRemind = false
    var itemID: Int
    var desc = ""
    
    func toggleChecked() {
        checked = !checked
    }
    
    func scheduleNotification() {
        // clears any scheduled notifications for the item to handle editing an item
        removeNotification()
        
        if shouldRemind && dueDate > Date() {
            // make notification content
            let content = UNMutableNotificationContent()
            content.title = "Reminder"
            if desc == "Description..." || desc == ""
            {
                content.body = text
            }
            else
            {
                content.body = text + ":\n" + desc
            }
            content.sound = UNNotificationSound.default()
            
            // extract date from obj prop
            let calendar = Calendar(identifier: .gregorian)
            let components = calendar.dateComponents([.month, .day, .hour, .minute], from: dueDate)
            
            // make date trigger
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            // create request with content and trigger
            let request = UNNotificationRequest(identifier: "\(itemID)", content: content, trigger: trigger)
            
            // register request with notificationCenter
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.add(request)
        }
    }

    func removeNotification() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["\(itemID)"])
    }
}
