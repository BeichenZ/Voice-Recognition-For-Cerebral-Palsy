//
//  CommandDataModel.swift
//  VoiceRecognitionApp
//
//  Created by BC on 2017-02-23.
//  Copyright © 2017 BC. All rights reserved.
//

import UIKit
import os.log

class Command: NSObject, NSCoding{
    
    //MARK: Properties
    var name: String
    //var commandSamplesURLList = [NSURL]()
    var commandSamplesURLStringList = [String]()
    var detectedWord : String

    
    //Mark: Archiving Paths
    //static means they belong to the class instead of an instance of the class 
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("commands")
    
    //MARK: Types
    struct PropertyKey {
        static let name = "name"
        //static let commandSamplesURLList = "commandSamplesURLList"
        static let commandSamplesURLStringList = "commandSamplesURLStringList"
        static let detectedWord = "detectedWord"
    }
    
    //MARK: Initialization
    init?(name:String, commandSamplesURLStringList: [String], detectedWord: String)
    {
        guard !name.isEmpty else{return nil}
        self.name = name
        //self.commandSamplesURLList = commandSamplesURLList
        self.commandSamplesURLStringList = commandSamplesURLStringList
        self.detectedWord = detectedWord
    }
    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder){
        aCoder.encode(name, forKey: PropertyKey.name)
        //aCoder.encode(commandSamplesURLList, forKey: PropertyKey.commandSamplesURLList)
        aCoder.encode(commandSamplesURLStringList, forKey: PropertyKey.commandSamplesURLStringList)
        aCoder.encode(detectedWord, forKey: PropertyKey.detectedWord)
    }
    
    required convenience init?(coder aDecoder: NSCoder){
        //The name is required. If we cannot decode a name string, the initializer should fail.
        guard let name = aDecoder.decodeObject(forKey: PropertyKey.name) as? String
            else{
                os_log("Unable to decode the name for a VoiceSample object.", log: OSLog.default, type: .debug)
                return nil
        }
        
        /*
        guard let commandSamplesURLList = aDecoder.decodeObject(forKey: PropertyKey.commandSamplesURLList) as? [NSURL]
            else{
                os_log("Unable to decode the url list for a VoiceSample object.", log: OSLog.default, type: .debug)
                return nil
        }
        */
        guard let commandSamplesURLStringList = aDecoder.decodeObject(forKey: PropertyKey.commandSamplesURLStringList) as? [String]
            else{
                os_log("Unable to decode the String url list for a VoiceSample object.", log: OSLog.default, type: .debug)
                return nil
        }
        
        guard let detectedWord = aDecoder.decodeObject(forKey: PropertyKey.detectedWord) as? String
            else{
                os_log("Unable to decode the detected word for a VoiceSample object.", log: OSLog.default, type: .debug)
                return nil
        }
        
        //Must call designated initializer
        self.init(name: name, commandSamplesURLStringList: commandSamplesURLStringList, detectedWord: detectedWord)
        
    }
    
}


