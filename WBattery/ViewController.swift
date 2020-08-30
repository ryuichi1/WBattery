//
//  ViewController.swift
//  WBattery
//
//  Created by ryuichi1 on 2020/08/30.
//  Copyright © 2020 jp.co.aidaryuichi. All rights reserved.
//

import Cocoa
import UserNotifications
import IOKit

class ViewController: NSViewController, UNUserNotificationCenterDelegate {
    @IBOutlet weak var percentComboBox: NSComboBox!
    @IBOutlet weak var batteryStatusTextField: NSTextField!
    @IBOutlet weak var watchingTextField: NSTextField!
    
    private let percentArray: [Int] = [
        10,
        20,
        30,
        40,
        50,
        60,
        70,
        80,
        90
    ]
    private var targetPercent: Int = 0
    private var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setBatteryStatus()
        setPercentComboBox()
    }

    override var representedObject: Any? {
        didSet {
        }
    }
    
    func setBatteryStatus() {
        let blob = IOPSCopyPowerSourcesInfo()
        guard let list = IOPSCopyPowerSourcesList(blob?.takeRetainedValue()) else { return }
        let cfList = list.takeRetainedValue()
        let nsList = cfList as NSArray
        guard let keyList = nsList[0] as? NSDictionary,
            let powerSourceStatus = keyList["Power Source State"] as? String else {
                return
        }
        switch powerSourceStatus {
        case "AC Power":
            batteryStatusTextField.stringValue = "充電しています"
            
        default:
            batteryStatusTextField.stringValue = "充電していません"
        }
    }
    
    func setPercentComboBox() {
        percentComboBox.isEditable = false
        percentComboBox.addItems(withObjectValues: percentArray)
    }


    @IBAction func watchingButtonDidTap(_ sender: Any) {
        guard let targetPercent = percentComboBox.objectValueOfSelectedItem as? Int else { return }
        self.targetPercent = targetPercent
        watchingTextField.stringValue = "\(targetPercent)%以下でアラートします"
        timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(checkBattery), userInfo: nil, repeats: true)
    }
    
    @objc
    func checkBattery() {
        let blob = IOPSCopyPowerSourcesInfo()
        guard let list = IOPSCopyPowerSourcesList(blob?.takeRetainedValue()) else { return }
        let cfList = list.takeRetainedValue()
        let nsList = cfList as NSArray
        guard let keyList = nsList[0] as? NSDictionary,
            let currentCapacity = keyList["Current Capacity"] as? Int,
            let powerSourceStatus = keyList["Power Source State"] as? String else {
                return
        }
        
        switch powerSourceStatus {
        case "AC Power":
            batteryStatusTextField.stringValue = "充電しています"
            break
            
        default:
            batteryStatusTextField.stringValue = "充電していません"
            if currentCapacity <= targetPercent {
                showNotification()
            }
        }
    }
        
    func showNotification() -> Void {
        let content = UNMutableNotificationContent()
        content.title = "バッテリーが少なくなりました"
        content.body = "\(targetPercent)%以下です、充電してください。"
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: "immediately", content: content, trigger: nil)
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request, withCompletionHandler: nil)
    }
}
