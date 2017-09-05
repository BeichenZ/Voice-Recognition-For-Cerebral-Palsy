//
//  CommandDetailViewController.swift
//  VoiceRecognitionApp
//
//  Created by BC on 2017-02-25.
//  Copyright © 2017 BC. All rights reserved.
//

import UIKit
import AVFoundation
import Foundation.NSTimer
import Speech
import os.log

class CommandDetailViewController: UIViewController,UITextFieldDelegate,UITableViewDelegate,UITableViewDataSource,AVAudioPlayerDelegate{
    
    //flag to track how this view was activated
    //1: when user want to edit existing command
    //2: when user want to add new command
    
    var callingType=0
    
    var audioRecorder:AVAudioRecorder!
    var audioChecker:AVAudioRecorder!
    var audioPlayer:AVAudioPlayer!
    var ListeningTimer = Timer()
    var checkFinishCounter = 0.0
    var noiseLevelCounter = Float(0)
    var noisePeakPower = Float(0)
    var avgNoisePeakPower = Float(0)
    var noisePeakPowerSD = Float(15)
    var holdingCounter = 20.0
    var peakPower = Float(0)
    var fileCounter = Int(0)
    var currentPlayButton: UIButton!
    
    
    //Display,Temporary Store, external fetch all happened here
    var command: Command?
    //MARK:Outlet
    
    //List of sample names
    //var list = [String]()
    
    //Sample Destination
    //var sampleURLs = [NSURL]()
    var sampleURLs = [String]()
    var detectedWord = String()
    
    var latestAudioFileLocation = String()
    var documentsUrl: URL{
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var commandNameTextField: UITextField!
    @IBOutlet weak var commandNameLabel: UILabel!
    @IBOutlet weak var addSampleButton: UIButton!
    @IBOutlet weak var sampleListTableView: UITableView!
    @IBOutlet weak var detectedWordLabel: UILabel!
    
    
////////////////////////////////////////////////////////////////////////
//TableView

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return(sampleURLs.count)
    }
    

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        guard let sampleCell = tableView.dequeueReusableCell(withIdentifier: "SampleCell", for: indexPath) as? CommandTableViewCell else {
            fatalError("The dequeued cell is not an instance of SampleCell")
        }
        
        //sampleCell.textLabel?.text = sampleURLs[indexPath.row].lastPathComponent
        sampleCell.textLabel?.text = sampleURLs[indexPath.row]
        sampleCell.playSampleButton.tag = indexPath.row
        sampleCell.playSampleButton.addTarget(self, action: #selector(playSampleButtonPressed), for: UIControlEvents.touchUpInside)
        
        return(sampleCell)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath){
        
        if editingStyle == UITableViewCellEditingStyle.delete{            
            sampleURLs.remove(at: indexPath.row)
            sampleListTableView.reloadData()
        }
    }
    
    @IBAction func playSampleButtonPressed(sender: UIButton){
        currentPlayButton = sender
        
        if currentPlayButton.currentTitle == "Play" {
            let audioSession = AVAudioSession.sharedInstance()
            do{
                try audioSession.setCategory(AVAudioSessionCategoryPlayback)
                
                let audioSampleURL = documentsUrl.appendingPathComponent(sampleURLs[sender.tag])
                //try audioPlayer = AVAudioPlayer(contentsOf: sampleURLs[sender.tag] as URL)
                try audioPlayer = AVAudioPlayer(contentsOf: audioSampleURL)
                
                
                audioPlayer.delegate = self
                audioPlayer.prepareToPlay()
            }catch{
                print(error)
            }
            sender.setTitle("Stop", for: .normal)
            audioPlayer.play()
        }
        else {
            audioPlayer.stop()
            sender.setTitle("Play", for: .normal)
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag == true {
            player.stop()
            print("finished playing")
            currentPlayButton.setTitle("Play", for: .normal)
        }
    }
    
    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
    
////////////////////////////////////////////////////////////////////
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Handle the text field's user input through delegate callbacks
        commandNameTextField.delegate=self
        self.addSampleButton.isEnabled=false
        
        if let command = command {
            commandNameTextField.text = command.name
            detectedWordLabel.text = command.detectedWord
            sampleURLs = command.commandSamplesURLStringList
            
            detectedWord = command.detectedWord
            
            sampleListTableView.reloadData()
            self.prepareAudioChecker()
            //self.prepareAudioRecorder()
            self.addSampleButton.isEnabled = true
        }
        
        updateViewBasedOnData()
        
        //Enable the save button only if the text field has a valid command name
        updateSaveButtonState()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
////////////////////////////////////////////////////////////////
//Collect Sample

    
    @IBAction func addSampleButtonPressed(_ sender: Any) {

        let currentTitle = self.addSampleButton.currentTitle
        
        if currentTitle == "Listening"{
            
            audioRecorder.stop()
            ListeningTimer.invalidate()
            audioChecker.stop()
            addSampleButton.setTitle("Add Sample", for: .normal)
            
            let audioSession = AVAudioSession.sharedInstance()
            do{
                try audioSession.setActive(false)
            } catch {
                print(error)
            }
        }else if currentTitle == "Add Sample"{

            self.prepareAudioRecorder()
            self.recordButtonCalled()
        }
        
    }
    
    
    func recordButtonCalled(){
        
        noiseLevelCounter = 0
        noisePeakPower = 0
        avgNoisePeakPower = 0
        
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
            
            //MARK:Start Saving Check
            if self.verifyFileExists(){
                
                print("file exists")
                //sampleURLs.append(URL(fileURLWithPath: latestAudioFileLocation) as NSURL)
                sampleURLs.append(latestAudioFileLocation)
                self.addNewSample()
                self.requestSpeechAuth()
            } else{
                print("there was a problem recording.")
            }
            
            let audioSession = AVAudioSession.sharedInstance()
            do{
                try audioSession.setActive(false)
            } catch {
                print(error)
            }
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////
    ////////this section does the voice detection and recording/////////////////////////////
    //Mark: auto detect voice command
    
    func enableMetering(){
        ListeningTimer = Timer.scheduledTimer(timeInterval: 0.05,
                                              target: self,
                                              selector: #selector(checkEnvironmentMeters),
                                              userInfo: nil,
                                              repeats: true)
    }
    
    func checkEnvironmentMeters(){
        audioChecker!.updateMeters()
        peakPower = audioChecker!.peakPower(forChannel:0)
        
        if noiseLevelCounter < 2 || peakPower < (avgNoisePeakPower + noisePeakPowerSD){
            noiseLevelCounter += 1
            print("noiseLevelCounter: \(String(noiseLevelCounter))")
            audioChecker!.updateMeters()
            noisePeakPower = noisePeakPower + audioChecker!.peakPower(forChannel:0)
            avgNoisePeakPower = noisePeakPower/noiseLevelCounter
            
            if audioRecorder.isRecording{
                self.checkFinishCommand()
                //addSampleButton.setTitle("Saving", for: .normal)
            }
        }
        else if peakPower > (avgNoisePeakPower + noisePeakPowerSD){
            if audioRecorder.isRecording{
                checkFinishCounter = 0.0
                //addSampleButton.setTitle("Listening", for: .normal)
            }
            else{
                //playButton.isHidden = true
                self.startRecording()
            }
        }
        
    }
    
    func checkFinishCommand(){
        checkFinishCounter += 1
        if checkFinishCounter > holdingCounter{
            checkFinishCounter = 0.0
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
    
    
    //MARK: Prepare to record
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
        let audioFileLocation = self.audioFileLocation()
        latestAudioFileLocation = audioFileLocation
        
        let audioSession = AVAudioSession.sharedInstance()
        do{
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioRecorder = AVAudioRecorder(url: documentsUrl.appendingPathComponent(audioFileLocation), settings: self.audioRecorderSettings())
            //try audioRecorder = AVAudioRecorder(url: audioFileLocation as! URL, settings: self.audioRecorderSettings())
            audioRecorder.prepareToRecord()
        }catch{
            print(error)
        }
    }
    
    
    //Helper functions
    //returns a string value that contains the path to the temporary directory and append file name
    
    
    func audioFileLocation() -> String {
        //let randomString = UUID.init()
        let date = Date()
        let calendar = Calendar.current
        
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        
        let currentTime = "_"+String(year)+"-"+String(month)+"-"+String(day)+"("+String(hour)+":"+String(minutes)+":"+String(seconds)+")"
        print(currentTime)
        
        //let audioRecorderFileLocation = NSTemporaryDirectory().appending((command?.name)!+currentTime+".m4a")
        //let fileManager = FileManager.default
        //let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = (command?.name)!+currentTime+".m4a"
        print(fileName)
        return fileName
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
            addSampleButton.setTitle("Listening", for: .normal)
        } else {
            addSampleButton.setTitle("Add Sample", for: .normal)
        }
    }
    
    func verifyFileExists() -> Bool{
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: documentsUrl.appendingPathComponent(latestAudioFileLocation).path)
        /*
        let randomURL = latestAudioFileLocation.path
        print(randomURL!)
        let exists = fileManager.fileExists(atPath: randomURL!)
        print(exists)
        return exists
 */
    }

    func addNewSample(){
        sampleListTableView.reloadData()
    }



    
    
/////////////////////////////////////////////////////////////////////////////////////
//BC coded//
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        
        //Configure the destination view controller only when the save button is pressed
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
        
//        if audioChecker.isRecording {
//            
//            audioRecorder.stop()
//            ListeningTimer.invalidate()
//            audioChecker.stop()
//            
//            //MARK:Start Saving Check
//            let audioSession = AVAudioSession.sharedInstance()
//            do{
//                try audioSession.setActive(false)
//            } catch {
//                print(error)
//            }
//        }
        
        let name = commandNameTextField.text ?? ""
        let sampleURLs = self.sampleURLs
        let detectedWord = self.detectedWord
        
        command = Command(name: name, commandSamplesURLStringList: sampleURLs, detectedWord: detectedWord)
    }
    
    
    //MARK: View Action
    
    @IBAction func cancel(_ sender: UIBarButtonItem)
    {
        
        //depending on the style of presentation, this view controller needs to be dismissed in two different ways
//        let isPresentingInAddCommandMode = presentingViewController is UINavigationBar
//        
        //if isPresentingInAddCommandMode {
            
        switch callingType{
        case 1:
            dismiss(animated:true,completion:nil)
        case 2:
            dismiss(animated:true,completion:nil)
        default:
            dismiss(animated:true,completion:nil)
            }
        
//        if audioChecker.isRecording {
//
//            audioRecorder.stop()
//            ListeningTimer.invalidate()
//            audioChecker.stop()
//            
//            //MARK:Start Saving Check
//            let audioSession = AVAudioSession.sharedInstance()
//            do{
//                try audioSession.setActive(false)
//            } catch {
//                print(error)
//            }
//        }
        
    }
    
    //MARK:TextField Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder() //what is this for?
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateSaveButtonState()
        commandNameLabel.text=textField.text
        
        let name=commandNameLabel.text!
        
        command = Command(name: name, commandSamplesURLStringList: sampleURLs, detectedWord: detectedWord)
        
        
        print(command?.name as Any)
        
        self.prepareAudioChecker()
        //self.prepareAudioRecorder()
        
        self.addSampleButton.isEnabled=true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        //Disable the save button while editing
        saveButton.isEnabled = false
    }
    //MARK: Private Funcs
    private func updateViewBasedOnData()
    {
        commandNameLabel.text=command?.name
        switch callingType{
        case 1:
            navigationBar.topItem?.title="Edit"
        case 2:
            navigationBar.topItem?.title="Add New"
        default:
            break
            
        }
    }
    
    private func updateSaveButtonState(){
        let text = commandNameTextField.text ?? ""
        saveButton.isEnabled = !text.isEmpty
    }
    
    func requestSpeechAuth(){
        SFSpeechRecognizer.requestAuthorization { authStatus in
            if authStatus == SFSpeechRecognizerAuthorizationStatus.authorized{
                
                let recognizer = SFSpeechRecognizer()
                //let request = SFSpeechURLRecognitionRequest(url: self.sampleURLs[0] as URL)
                let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(self.sampleURLs[0])
                print(fileURL)
                let request = SFSpeechURLRecognitionRequest(url: fileURL)
                recognizer?.recognitionTask(with: request){ (result, error) in
                    if let error = error {
                        print("There was an error: \(error)")
                        //self.transcribeLabel!.text = "Could not recognize"
                    } else {
                        let theResult = result!.bestTranscription.formattedString
                        print(theResult)
                        //self.transcribeLabel!.text = "\(theResult)"
                        if result!.isFinal{
                            self.detectedWord = theResult
                            self.detectedWordLabel!.text = self.detectedWord
                        }
                    }
                }
            }
            else{
                
                //If speech-to-text conversion denied, end recording session
                //and reset all parameters and inactive the Record button
                //self.transcribeLabel!.text = "Permission denied. Unable to Transcribe"
                self.audioRecorder.stop()
                self.ListeningTimer.invalidate()
                self.audioChecker.stop()

            }
        }
    }
    
}
