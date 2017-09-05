//
//  ViewController.swift
//  RecordFunction
//
//  Created by Beck on 2017-02-05.
//  Copyright © 2017 Beck. All rights reserved.
//

import UIKit
import AVFoundation
import Foundation.NSTimer
import Speech

class StartRecognitionCommandController: UIViewController {
    

    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var MeterLabel: UILabel!
    @IBOutlet weak var HoldCounterLabel: UILabel!
    @IBOutlet weak var HoldingCountLabel: UILabel!
    @IBOutlet weak var noisePeakPowerLabel: UILabel!
    @IBOutlet weak var transcribeLabel: UILabel!
    @IBOutlet weak var customCommandsSwitch: UISwitch!
    
    

    
    var audioRecorder:AVAudioRecorder!
    var audioChecker:AVAudioRecorder!
    var audioPlayer:AVAudioPlayer!
    var ListeningTimer = Timer()
    var checkNoiseLevelTimer = Timer()
    var checkFinishCounter = 0.0
    //var checkRecognitionFinishCounter = 0
    var noiseLevelCounter = Float(0)
    var noisePeakPower = Float(0)
    var avgNoisePeakPower = Float(0)
    var noisePeakPowerSD = Float(40)
    var currentNoisePeakPowerSD = Float(0)
    var holdingCounter = 20.0
    var peakPower = Float(0)
    var fileCounter = Int(0)
    var customCommandSwitch = Bool()
    var savedCommands = [Command]()
    var transcribeResult = String()
    
    //var isRecordPressed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.prepareAudioChecker()
        self.prepareAudioRecorder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func recordButtonPressed(_ sender: Any) {
        
        let currentTitle = self.recordButton.currentTitle
        
        if currentTitle == "Record"{
            self.recordButton.setTitle("Listening", for: .normal)
            self.transcribeLabel!.text = ""
            self.recordButtonCalled()
        }
        else if currentTitle == "Listening"{
            audioRecorder.stop()
            ListeningTimer.invalidate()
            audioChecker.stop()
            
            noiseLevelCounter = 0
            noisePeakPower = 0
            avgNoisePeakPower = 0
            
            recordButton.setTitle("Record", for: .normal)
        }
        customCommandSwitch = customCommandsSwitch.isOn
    }
    
    @IBAction func customCommandSwitch(_ sender: UISwitch) {
        customCommandSwitch = customCommandsSwitch.isOn
    }

    func recordButtonCalled(){
        self.updateRecordButtonTitle()
        if !audioRecorder.isRecording{
            //start recording
            //self.transcribeLabel!.text = "Listening..."
            let audioSession = AVAudioSession.sharedInstance()
            do{
                try audioSession.setActive(true)
                if !ListeningTimer.isValid{
                    audioChecker.isMeteringEnabled = true
                    audioChecker.record()
                    self.enableMetering()
                }
            }catch{
                print(error)
            }
        } else{
            //stop recording
            
            audioRecorder.stop()
            ListeningTimer.invalidate()
            audioChecker.stop()
            
            //Check
            if self.verifyFileExists(){
                print("file exists")
                self.requestSpeechAuth()
                //playButton.isHidden = false
            } else{
                print("there was a problem recording.")
            }
        
            
            //            let audioSession = AVAudioSession.sharedInstance()
            //            do{
            //                try audioSession.setActive(false)
            //            } catch {
            //                print(error)
            //            }
            
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////
    ////////this section does the voice detection and recording/////////////////////////////
    func enableMetering(){
        ListeningTimer = Timer.scheduledTimer(timeInterval: 0.05,
                                              target: self,
                                              selector: #selector(checkRecordingMeters),
                                              userInfo: nil,
                                              repeats: true)
    }
    
    func checkRecordingMeters(){
        audioChecker!.updateMeters()
        peakPower = audioChecker!.peakPower(forChannel:0)
        currentNoisePeakPowerSD = -(noisePeakPowerSD/160)*avgNoisePeakPower
        MeterLabel!.text = "Peak Power \(String(peakPower))"
        
        print("\(String(currentNoisePeakPowerSD)) ;  \(String(avgNoisePeakPower))")
        
        if noiseLevelCounter < 2 || peakPower < (avgNoisePeakPower + currentNoisePeakPowerSD){
            noiseLevelCounter += 1
            //print("noiseLevelCounter: \(String(noiseLevelCounter))")
            audioChecker!.updateMeters()
            noisePeakPower = noisePeakPower + audioChecker!.peakPower(forChannel:0)
            avgNoisePeakPower = noisePeakPower/noiseLevelCounter
            noisePeakPowerLabel!.text = "Avg Noise Power: \(String(avgNoisePeakPower))"
            
            if audioRecorder.isRecording{
                self.checkFinishCommand()
            }
        }
        else if peakPower > (avgNoisePeakPower + currentNoisePeakPowerSD){
            if audioRecorder.isRecording{
                checkFinishCounter = 0.0
            }
            else{
                //playButton.isHidden = true
                self.startRecording()
            }
        }
        
    }
    
    func checkFinishCommand(){
        checkFinishCounter += 1
        HoldCounterLabel!.text = "Pause Counter: \(String(checkFinishCounter))"
        HoldingCountLabel!.text = "Pause Threshold: \(String(holdingCounter))"
        if checkFinishCounter > holdingCounter{
            self.recordButtonCalled()
        }
    }
    
    func startRecording(){
        let audioSession = AVAudioSession.sharedInstance()
        do{
            try audioSession.setActive(true)
            audioRecorder.record()
        }catch{
            print(error)
        }
    }
    /////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////
    
    //Main
    //steps to prepare AVAudioRecorder for recording
    func prepareAudioChecker(){
        let audioSession = AVAudioSession.sharedInstance()
        do{
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioChecker = AVAudioRecorder(url: URL(fileURLWithPath: self.checkerFileLocation()), settings: self.audioRecorderSettings())
            audioChecker.prepareToRecord()
        }catch{
            print(error)
        }
    }
    
    func prepareAudioRecorder(){
        let audioSession = AVAudioSession.sharedInstance()
        do{
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioRecorder = AVAudioRecorder(url: URL(fileURLWithPath: self.audioFileLocation()), settings: self.audioRecorderSettings())
            audioRecorder.prepareToRecord()
        }catch{
            print(error)
        }
        
    }
    
    //    func playAudio(){
    //        let audioSession = AVAudioSession.sharedInstance()
    //        do{
    //            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
    //            try audioPlayer = AVAudioPlayer(contentsOf: URL(fileURLWithPath: self.audioFileLocation()))
    //            audioPlayer.prepareToPlay()
    //            audioPlayer.play()
    //        }catch{
    //            print(error)
    //        }
    //    }
    
    //    func callCheckNoiseLevelTimer(){
    //        checkNoiseLevelTimer = Timer.scheduledTimer(timeInterval: 0.1,
    //                                              target: self,
    //                                              selector: #selector(checkNoiseLevel),
    //                                              userInfo: nil,
    //                                              repeats: true)
    //    }
    
    
    //    func checkNoiseLevel(){
    //        noiseLevelCounter += 1
    //        print("noiseLevelCounter: \(String(noiseLevelCounter))")
    //        audioChecker!.updateMeters()
    //        noisePeakPower = noisePeakPower + audioChecker!.peakPower(forChannel:0)
    //        avgNoisePeakPower = noisePeakPower/noiseLevelCounter
    //        noisePeakPowerLabel!.text = "NoisePeakPower: \(String(avgNoisePeakPower))"
    //    }
    
    
    
    //Helper functions
    //returns a string value that contains the path to the temporary directory and append file name
    func audioFileLocation() -> String {
        //let randomString = UUID.init()
        let audioRecorderFileLocation = NSTemporaryDirectory().appending(String(fileCounter)+"audioRecording.m4a")
        print(audioRecorderFileLocation)
        return audioRecorderFileLocation
        
    }
    
    func checkerFileLocation() -> String {
        return NSTemporaryDirectory().appending("checkerRecorder.m4a")
    }
    
    //returns a dictionary of keys used to determine recording settings of the AVAudioRecorder Object
    func audioRecorderSettings() -> [String:Any] {
        let settings = [AVFormatIDKey : NSNumber.init(value: kAudioFormatAppleLossless),
                        AVSampleRateKey : NSNumber.init(value: 44100.0),
                        AVNumberOfChannelsKey : NSNumber.init(value: 1),
                        AVLinearPCMBitDepthKey : NSNumber.init(value: 16),
                        AVEncoderAudioQualityKey : NSNumber.init(value: AVAudioQuality.high.rawValue) ]
        return settings
    }
    
    
    func updateRecordButtonTitle(){
        if !audioRecorder.isRecording {
            recordButton.setTitle("Listening", for: .normal)
        }
    }
    
    func verifyFileExists() -> Bool{
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: self.audioFileLocation())
    }
    //Speech to Text functions
    func requestSpeechAuth(){
        SFSpeechRecognizer.requestAuthorization { authStatus in
            if authStatus == SFSpeechRecognizerAuthorizationStatus.authorized{
                
                let recognizer = SFSpeechRecognizer()
                let request = SFSpeechURLRecognitionRequest(url: URL(fileURLWithPath: self.audioFileLocation()))
                recognizer?.recognitionTask(with: request){ (result, error) in
                    if let error = error {
                        print("There was an error: \(error)")
                        self.transcribeLabel!.text = "Could not recognize"
                        self.fileCounter += 1
                        self.prepareAudioRecorder()
                        self.recordButtonCalled()
                    } else {
                        let theResult = result!.bestTranscription.formattedString
                        self.transcribeResult = theResult
                        //print(theResult) 
                        if self.customCommandSwitch == false {
                            self.transcribeLabel!.text = "\(theResult)"
                            if result!.isFinal{
                                self.fileCounter += 1
                                self.prepareAudioRecorder()
                                self.recordButtonCalled()
                            }
                        }
                        else if self.customCommandSwitch == true {
                            self.requestCustomCommand()
                        }
                    }
                }
            }
            else{
                
                //If speech-to-text conversion denied, end recording session
                //and reset all parameters and inactive the Record button
                self.transcribeLabel!.text = "Permission denied. Unable to Transcribe"
                self.audioRecorder.stop()
                self.ListeningTimer.invalidate()
                self.audioChecker.stop()
                
                self.noiseLevelCounter = 0
                self.noisePeakPower = 0
                self.avgNoisePeakPower = 0
                
                let audioSession = AVAudioSession.sharedInstance()
                do{
                    try audioSession.setActive(false)
                } catch {
                    print(error)
                }
                
                self.recordButton.setTitle("Record", for: .normal)
                self.recordButton.isEnabled = false
            }

        }
    }
    
    func requestCustomCommand(){
        if let savedCommands = loadCommands(){
            print("requestCustomCommand")
            print("\(String(savedCommands.count))")
            var i = 0
            while i < savedCommands.count {
                print(transcribeResult + savedCommands[i].detectedWord)
                if transcribeResult == savedCommands[i].detectedWord {
                    print("matched")
                    transcribeLabel!.text = savedCommands[i].name
                    i = savedCommands.count + 1
                }
                else{
                    i += 1
                }
            }
            
            if i == savedCommands.count {
                transcribeLabel!.text = ("Found no match, could not transcribe")
            }
            
        }
        self.prepareAudioRecorder()
        self.recordButtonCalled()
    }
    
    private func loadCommands() -> [Command]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Command.ArchiveURL.path) as? [Command]
    }
    
}




