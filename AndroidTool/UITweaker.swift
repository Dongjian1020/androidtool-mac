//
//  UITweaker.swift
//  AndroidTool
//
//  Created by Morten Just Petersen on 11/16/15.
//  Copyright © 2015 Morten Just Petersen. All rights reserved.
//

import Cocoa

protocol UITweakerDelegate {
    func UITweakerStatusChanged(status: String)
}

class UITweaker: NSObject {
    var adbIdentifier:String!
    var delegate:UITweakerDelegate?

    
    init(adbIdentifier:String){
        self.adbIdentifier = adbIdentifier;
    }
    
    struct Tweak {
        var command:String!
        var description:String!
    }
    
    func start(callback:()->Void){
        var cmdString = ""
        for tweak in collectAllTweaks() {
            cmdString = "\(tweak.command)~\(cmdString)"
        }
        
        ShellTasker(scriptFile: "setDemoModeOptions").run(arguments: [self.adbIdentifier, cmdString], isUserScript: false, isIOS: false) { (output) -> Void in
//            print("Done executing \(cmdString)")
            print(output)
            callback()
        }
    }
    
    
    func collectAllTweaks() -> [Tweak] {
        let ud = NSUserDefaults.standardUserDefaults()
        var tweaks = [Tweak]()
        
        for prop in C.tweakProperties {
            switch prop {
                case "airplane", "nosim", "carriernetworkchange": // network showhide
                    let cmd = "network"
                    var show = "hide"
                    if ud.boolForKey(prop) { show = "show" }
                    let tweak = Tweak(command: "\(cmd) -e \(prop) \(show)", description: "\(show) \(prop)")
                    tweaks.append(tweak)
                    break
                case "location", "alarm", "sync", "tty", "eri", "mute", "speakerphone": // status showhide
                    let cmd = "status"
                    var show = "hide"
                    if ud.boolForKey(prop) { show = "show" }
                    let tweak = Tweak(command: "\(cmd) -e \(prop) \(show)", description: "\(show) \(prop)")
                    tweaks.append(tweak)
                    break
                case "bluetooth":
                    var show = "hide"
                    if ud.boolForKey("bluetooth") {
                        show = "connected"
                    }
                    let tweak = Tweak(command: "status -e bluetooth \(show)", description: "Tweaking Bluetooth")
                    tweaks.append(tweak)
                    break
                case "notifications":
                    var visible = "false"
                    if ud.boolForKey(prop) {
                        visible = "true"
                    }
                    let tweak = Tweak(command: "\(prop) -e visible \(visible)", description: "Tweaking notfications")
                    tweaks.append(tweak)
                    break
                case "clock":
                    if ud.boolForKey(prop) {
                        let hhmm = formatTime(ud.stringForKey("timeValue")!)
                        let tweak = Tweak(command: "clock -e hhmm \(hhmm)", description: "Setting time to \(ud.stringForKey("timeValue"))")
                        tweaks.append(tweak)
                    }
                    break
                case "wifi":
                    var show = "hide"
                    var level = ""
                    if ud.boolForKey("wifi") {
                        show = "show"
                        level = " -e level 4"
                    }
                    let tweak = Tweak(command: "network -e \(prop) \(show) \(level)", description: "\(show) \(prop)")
                    tweaks.append(tweak)
                    break
                case "mobile":
                    var tweak:Tweak!
                    if ud.boolForKey(prop){
                        let mobileDatatype = ud.stringForKey("mobileDatatype")
                        let mobileLevel = ud.stringForKey("mobileLevel")!.stringByReplacingOccurrencesOfString(" bars", withString: "").stringByReplacingOccurrencesOfString(" bar", withString: "")
                        tweak = Tweak(command: "network -e mobile show -e datatype \(mobileDatatype) -e level \(mobileLevel)", description: "Turn cell icon on")
                    } else {
                        tweak = Tweak(command: "network -e mobile hide", description: "Turn cell icon off")
                    }
                    tweaks.append(tweak)
                    break
                case "batteryCharging":
                    var showCharging = "false"
                    var description = "Set battery not charging"
                    let batLevel = ud.stringForKey("batteryLevel")?.stringByReplacingOccurrencesOfString("%", withString: "")
                    if ud.boolForKey("batteryCharging") {
                        showCharging = "true"
                        description = "Set battery charging"
                    }
                    let tweak = Tweak(command: "battery -e plugged \(showCharging) -e level \(batLevel!)", description: description)
                    tweaks.append(tweak)
                break
                default:
                    break
            }
        }
        return tweaks

    }
    
    
    func formatTime(t:String) -> String { // remove : in hh:mm
        return t.stringByReplacingOccurrencesOfString(":", withString: "")
    }
    
    func end(){
        
        ShellTasker(scriptFile: "exitDemoMode").run(arguments: [self.adbIdentifier], isUserScript: false, isIOS: false) { (output) -> Void in
            ///aaaaand done
        }
    }
}
