//
//  DetailViewController.swift
//  NotesSaving
//
//  Created by Andres Garcia on 7/15/19.
//  Copyright © 2019 Andres Garcia. All rights reserved.
//

import UIKit
import CoreData
import Foundation
import AVFoundation
import IQKeyboardManagerSwift


var loaded:Bool = false
var currentButtonState:Int = 0
var recording:Bool = false
var string_seconds:String = "00"
var string_minutes:String = "00"
var AudioTimer = Timer()


class DetailViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate, UITextViewDelegate {
    
    var playerLoaded:Bool = false
    var time_stamps = Array<Double>()
    var alert_index = -1
    
    @IBOutlet weak var detailDescriptionLabel: UILabel!

    @IBOutlet weak var exportButtonOutlet: UIBarButtonItem!
    
    @IBOutlet weak var PleaseSelectBlock: UILabel!
    @IBOutlet weak var Write: UITextView!
    @IBOutlet weak var TitleTextBox: UITextField!
    
    @IBAction func TitleChange(_ sender: Any) {
        if(loaded){
            if self.TitleTextBox.text != ""{
                let cnote = foundData[0]
                cnote.name = self.TitleTextBox.text!
            }
        }
    }
    @IBOutlet weak var MaxTime: UILabel!
    @IBOutlet weak var TimeReader: UILabel!
    @IBOutlet weak var Slider: UISlider!
    @IBAction func Slid(_ sender: Any) {
        if recording == false && currentButtonState >= 1{
            soundPlayer.pause()
            currentButtonState = 1
            buttonModification()
            if TimeInterval(Slider.value) >= soundPlayer.duration-0.1{
                soundPlayer.currentTime = soundPlayer.duration - 0.1
            }
            else{
                soundPlayer.currentTime = TimeInterval(Slider.value)
            }
            
            updatePlayTimer()
        }
    }
    
    
    @IBAction func Back10(_ sender: Any) {
        if recording == false && currentButtonState >= 1{
            soundPlayer.pause()
            currentButtonState = 1
            buttonModification()
            soundPlayer.currentTime -= TimeInterval(10)
            //print(soundPlayer.currentTime)
            updatePlayTimer()
        }
    }
    
    @IBAction func Forward10(_ sender: Any) {
        if recording == false && currentButtonState >= 1{
            soundPlayer.pause()
            currentButtonState = 1
            buttonModification()
            
            let postModification = soundPlayer.currentTime + TimeInterval(10)
            if postModification >= soundPlayer.duration{
                soundPlayer.currentTime = soundPlayer.duration-0.01
            }
            else{
                soundPlayer.currentTime = postModification
            }
            //print(soundPlayer.currentTime)
            updatePlayTimer()
        }
    }
    

    @IBAction func PrevAlert(_ sender: Any) {
        if recording == false && currentButtonState >= 1{
            if(time_stamps.count > 0){
                alert_index -= 1
            }
            if(alert_index < 0){
                alert_index = time_stamps.count - 1
            }
            updateAudioFromAlert()
        }
    }
    
    @IBAction func NextAlert(_ sender: Any) {
        if recording == false && currentButtonState >= 1{
            if(time_stamps.count > 0){
                alert_index += 1
            }
            if(alert_index >= time_stamps.count){
                alert_index = 0
            }
            updateAudioFromAlert()
        }
    }
    
    func updateAudioFromAlert(){
        if(time_stamps.count > 0){
            soundPlayer.pause()
            currentButtonState = 1
            buttonModification()
            //print(alert_index)
            soundPlayer.currentTime = time_stamps[alert_index]
            updatePlayTimer()
        }
    }

    @IBAction func exportButton(_ sender: Any) {
        let cnote = foundData[0]
        
        //getDocumentsDirectory().appendingPathComponent("\(cnote.max_id)AudioFile.m4a")
        do {
            let originPath = getDocumentsDirectory().appendingPathComponent(cnote.end_url!)
            if(TitleTextBox.text != ""){
                cnote.end_url = "\(TitleTextBox.text!).m4a"
            }
            let destinationPath = getDocumentsDirectory().appendingPathComponent(cnote.end_url!)
            try FileManager.default.moveItem(at: originPath, to: destinationPath)
        } catch let error as NSError {
            print(error)
        }
        
        let audioTrackURL = getDocumentsDirectory().appendingPathComponent(cnote.end_url!)
        /*do{
            audioTrack = try Data(contentsOf: soundRecorder.url)
        } catch {
            audioTrack = nil
        }*/
        
        let activityVC = UIActivityViewController(activityItems: [Write.text ?? "", audioTrackURL], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view
        
        self.present(activityVC, animated: true, completion: nil)
    }
    
    @IBOutlet weak var MultiButton: UIButton!
    
    var soundRecorder : AVAudioRecorder!
    var soundPlayer : AVAudioPlayer!
    
    
    //Audio Editing Functions
    
    @IBAction func MultiPress(_ sender: Any) {//0 = record, 1 = pause, 2= play
        
        if currentButtonState == 0{ // record
            recording = true
            timeStampColor()
            soundRecorder.record()
            initRecTimer()
            
        }
        
        if currentButtonState == 1{ // stop recording/stop playing
            if recording == true{
                wrapUpRecordingProtocol()
            }
            
            else if recording == false{
                soundPlayer.pause()
                stopPlayTimer()
            }
        }
        
        if currentButtonState == 2{// play audio
            initPlayTimer()
            //print("slider_max = \(Slider.maximumValue),duration= \(Float(soundPlayer.duration))")
            //print("SP currentButtonState time = \(soundPlayer.currentTime), Slider.val = \(TimeInterval(Slider.value))")
            soundPlayer.play()
        }
        
        buttonModification()
        
    }
    
    func initPlayTimer(){
        AudioTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updatePlayTimer), userInfo: nil, repeats: true)
    }
    
    func stopPlayTimer(){
        AudioTimer.invalidate()
    }
    
    func initRecTimer(){
        AudioTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateRecTimer), userInfo: nil, repeats: true)
    }
    
    func stopRecTimer(){
        AudioTimer.invalidate()
    }
    
    @objc func updatePlayTimer(){
        let minutes = floor(soundPlayer.currentTime/60)
        let seconds = floor(soundPlayer.currentTime - minutes * 60)
        if minutes < 10{//converts single digits numbers to 0X and keeps double digit numbers as is
            string_minutes = "0\(Int(minutes))"
            //print("sec: \(string_minutes)")
        }
        else{
            string_minutes = "\(Int(minutes))"
        }
            
        if seconds < 10{
            string_seconds = "0\(Int(seconds))"
                //print("sec: \(string_seconds)")
        }
        else{
            string_seconds = "\(Int(seconds))"
        }
        self.TimeReader.text = ("\(string_minutes):\(string_seconds)")
        Slider.value = Float(soundPlayer.currentTime)
    }
    
    
    @objc func updateRecTimer(){
        let minutes = floor(soundRecorder.currentTime/60)
        let seconds = floor(soundRecorder.currentTime - minutes * 60)
        if minutes < 10{//converts single digits numbers to 0X and keeps double digit numbers as is
            string_minutes = "0\(Int(minutes))"
            //print("sec: \(string_minutes)")
        }
        else{
            string_minutes = "\(Int(minutes))"
        }
            
        if seconds < 10{
            string_seconds = "0\(Int(seconds))"
                //print("sec: \(string_seconds)")
        }
        else{
            string_seconds = "\(Int(seconds))"
        }
        self.MaxTime.text = ("\(string_minutes):\(string_seconds)")
        print("\(string_minutes):\(string_seconds)")
    }
    
    func updateMaxTimer(){
        let minutes = floor(soundPlayer.duration/60)
        let seconds = floor(soundPlayer.duration - minutes * 60)
        if minutes < 10{//converts single digits numbers to 0X and keeps double digit numbers as is
            string_minutes = "0\(Int(minutes))"
            //print("sec: \(string_minutes)")
        }
        else{
            string_minutes = "\(Int(minutes))"
        }
            
        if seconds < 10{
            string_seconds = "0\(Int(seconds))"
                //print("sec: \(string_seconds)")
        }
        else{
            string_seconds = "\(Int(seconds))"
        }
        self.MaxTime.text = ("\(string_minutes):\(string_seconds)")
    }
    
    func buttonModification(){
        if currentButtonState == 0 || currentButtonState == 2{
            if #available(iOS 13.0, *) {
                let pauseImage = UIImage(systemName: "pause.circle")
                self.MultiButton.setBackgroundImage(pauseImage, for: [])
                //self.MultiButton.tintColor = UIColor.systemGray
                currentButtonState = 1
            }
        }
        else if currentButtonState == 1{
            if #available(iOS 13.0, *) {
                let playImage = UIImage(systemName: "play.circle")
                self.MultiButton.setBackgroundImage(playImage, for: [])
                //self.MultiButton.tintColor = UIColor.systemBlue
                currentButtonState = 2
            }
        }
        
    }
    
    @objc func backPedal(){
        if(currentButtonState != 2){
            let minutes = floor(soundRecorder.currentTime/60)
            let seconds = floor(soundRecorder.currentTime - minutes * 60)
            if minutes < 10{//converts single digits numbers to 0X and keeps double digit numbers as is
                string_minutes = "0\(Int(minutes))"
                //print("sec: \(string_minutes)")
            }
            else{
                string_minutes = "\(Int(minutes))"
            }
                
            if seconds < 10{
                string_seconds = "0\(Int(seconds))"
                    //print("sec: \(string_seconds)")
            }
            else{
                string_seconds = "\(Int(seconds))"
            }
            Write.text += ("\n\(string_minutes):\(string_seconds)\n")
            
            time_stamps.append(soundRecorder.currentTime)
        }
    }
    
    func timeStampColor(){
        /*if recording == true{
            TimeReader.textColor = UIColor(named: "OrangeRedCustom")
            TimeReader.text = "REC"
        }
        else{
            TimeReader.textColor = UIColor.white
            TimeReader.text = "00:00"
        }*/
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if #available(iOS 13.0, *) {
            soundPlayer.pause()
            //soundPlayer.currentTime = soundPlayer.duration
            let playImage = UIImage(systemName: "play.circle")
            self.MultiButton.setBackgroundImage(playImage, for: [])
            currentButtonState = 2
        }
    }
    
    
    //View Functions
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            if let label = detailDescriptionLabel {
                label.text = detail.timestamp!.description
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        IQKeyboardManager.shared.enable = false
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTextView(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
            
        NotificationCenter.default.addObserver(self, selector: #selector(updateTextView(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(detailWillResignActive), name: UIApplication.willResignActiveNotification,object: nil)
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        
        let backpedalButton = UIBarButtonItem(image: UIImage(systemName: "exclamationmark.square"), style: .plain, target: self, action: #selector(backPedal))
        
        //UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.action, target: self, action: #selector(backPedal))
        
        backpedalButton.tintColor = UIColor(named: "CoolGreen")
        //backpedalButton.image = UIImage(systemName: "exclamationmark.square")
        
        //let lastTimeStamp = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.action, target: self, action: #selector(backPedal))
        
        /*if #available(iOS 13.0, *) {
            let playImage = UIImage(systemName: "play.circle")
            backpedalButton.setImage(playImage, for: [], barMetrics: .default)
        } else {}*/
        
        toolbar.setItems([flexibleSpace, backpedalButton], animated: false)
        
        Write.inputAccessoryView = toolbar
        
        
        let recordingSession = AVAudioSession.sharedInstance()
        do {
            // Set the audio session category, mode, and options.
            try recordingSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try recordingSession.setActive(true)
        } catch {
            print("Failed to set audio session category.")
        }
        configureView()
        // Do any additional setup after loading the view.
        //print(notesTitle)
        //print("DETAIL")
        
        if(foundData.count > 0){
            PleaseSelectBlock.isHidden = true
            TitleTextBox.isHidden = false
            exportButtonOutlet.isEnabled = true
            let cnote = foundData[0]
            if(cnote.audio == nil){
                currentButtonState = 0
                setupRecorder()
            }
            else{
                setupPlayer()
                currentButtonState = 1
                buttonModification()
                Slider.maximumValue = Float(soundPlayer.duration)
                Slider.isUserInteractionEnabled = true
                updateMaxTimer()
                let alert_string_pulled:String = cnote.alerts ?? ""
                //print("alert_string \(alert_string_pulled)")
                let time_stamps_strings = alert_string_pulled.split(separator: ",")
                //print("time_stamps_strings \(time_stamps_strings)")
                for alert in time_stamps_strings{
                    if(alert != ""){
                        //print("alert: \(alert)")
                        time_stamps.append(Double(alert)!)
                    }
                }
                //print("time stamps: \(time_stamps)")
            }
            self.TitleTextBox.text = cnote.name
            self.Write.text = cnote.content
            loaded = true
        }
        else{
            PleaseSelectBlock.isHidden = false
            TitleTextBox.isHidden = true
            exportButtonOutlet.isEnabled = false
            
        }
        
    
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if (loaded){
            var cnote = foundData[0]
            if UIDevice.current.userInterfaceIdiom == .pad{
                print("ipad")
                cnote = lastData[0]
            }
            if self.TitleTextBox.text != ""{
                cnote.name = self.TitleTextBox.text!
            }
            cnote.content = self.Write.text
            loaded = false
            
            var alert_string:String = ""
            
            for alert in time_stamps{
                alert_string += "\(alert),"
            }
            cnote.alerts = alert_string
            //print("cnote.alerts: \(cnote.alerts)")
            
            do{
                //print("save dis")
                try managedObjectContext.save()
            } catch {
                print("failed to save in dis")
            }
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        wrapUpRecordingProtocol()
    }
    
    func wrapUpRecordingProtocol(){
        if(recording == true){
            recording = false;
            soundRecorder.stop()
            saveAudioToCD()
            stopRecTimer()
            timeStampColor()
            setupPlayer()
            updateMaxTimer()
            Slider.maximumValue = Float(soundPlayer.duration)
            Slider.isUserInteractionEnabled = true
            
        }
    }
    
    @objc private func detailWillResignActive(){
        if (loaded){
            var cnote = foundData[0]
            if UIDevice.current.userInterfaceIdiom == .pad{
                print("ipad")
                cnote = lastData[0]
            }
            if self.TitleTextBox.text != ""{
                cnote.name = self.TitleTextBox.text!
            }
            cnote.content = self.Write.text
            
            //if(playerLoaded) {soundPlayer.pause()}
            
            
            do{
                print("save resign")
                try managedObjectContext.save()
            } catch {
                print("failed to save in resign")
            }
        }
    }
    
    
    @objc func updateTextView(notification : Notification)
    {
        var _kbSize:CGSize!
                
        if let info = notification.userInfo {

        let frameEndUserInfoKey = UIResponder.keyboardFrameEndUserInfoKey
        
        //  Getting UIKeyboardSize.
        if let kbFrame = info[frameEndUserInfoKey] as? CGRect {
            
            let screenSize = UIScreen.main.bounds
            
            //Calculating actual keyboard displayed size, keyboard frame may be different when hardware keyboard is attached (Bug ID: #469) (Bug ID: #381)
            let intersectRect = kbFrame.intersection(screenSize)
            
                if intersectRect.isNull {
                    _kbSize = CGSize(width: screenSize.size.width, height: 0)
                } else {
                    _kbSize = intersectRect.size
                }
            }
        }

        if notification.name == UIResponder.keyboardWillHideNotification{
            Write.contentInset = UIEdgeInsets.zero
        }
        else
        {
            Write.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: _kbSize.height - 73, right: 0)
            Write.scrollIndicatorInsets = Write.contentInset
        }

        let screensize: CGRect = UIScreen.main.bounds
        //print(screensize)
        //print(_kbSize.height)
        Write.scrollRangeToVisible(Write.selectedRange)

    }
    
    var detailItem: Event? {
        didSet {
            // Update the view.
            configureView()
        }
    }
    
    //Audio Setup Functions
    
    func saveAudioToCD(){
        let cnote = foundData[0]
        
        var audioTrack: Data?
        
        do{
            audioTrack = try Data(contentsOf: soundRecorder.url)
        } catch {
            audioTrack = nil
        }
        
        cnote.audio = audioTrack
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func setupRecorder() {
        let cnote = foundData[0]
        let audioFilename = getDocumentsDirectory().appendingPathComponent(cnote.end_url!)
        let recordSetting = [ AVFormatIDKey : kAudioFormatAppleLossless,
                              AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
                              AVEncoderBitRateKey : 320000,
                              AVNumberOfChannelsKey : 2,
                              AVSampleRateKey : 44100.2] as [String : Any]
        
        do {
            soundRecorder = try AVAudioRecorder(url: audioFilename, settings: recordSetting)
            soundRecorder.delegate = self
            soundRecorder.prepareToRecord()
        } catch {
            print(error)
        }
    }
    
    func setupPlayer() {
        let cnote = foundData[0]

        do {
            soundPlayer = try AVAudioPlayer(data: cnote.audio!)
            soundPlayer.delegate = self
            soundPlayer.prepareToPlay()
            soundPlayer.volume = 1.0
            playerLoaded = false
        } catch {
            print(error)
        }
    }

}

