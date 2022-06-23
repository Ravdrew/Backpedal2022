//
//  DetailViewController.swift
//  NotesSaving
//
//  Created by Andres Garcia on 7/15/19.
//  Copyright © 2019 Andres Garcia. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation

var loaded:Bool = false
var currentButtonState:Int = 0
var recording:Bool = false
var string_seconds:String = "00"
var string_minutes:String = "00"
var AudioTimer = Timer()


class DetailViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    @IBOutlet weak var detailDescriptionLabel: UILabel!

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
            
            updateTimer()
        }
    }
    
    
    @IBAction func Back10(_ sender: Any) {
        if recording == false && currentButtonState >= 1{
            soundPlayer.pause()
            currentButtonState = 1
            buttonModification()
            soundPlayer.currentTime -= TimeInterval(10)
            print(soundPlayer.currentTime)
            updateTimer()
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
            print(soundPlayer.currentTime)
            updateTimer()
        }
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
            
        }
        
        if currentButtonState == 1{ // stop recording/stop playing
            if recording == true{
                recording = false;
                soundRecorder.stop()
                saveAudioToCD()
                
                timeStampColor()
                setupPlayer()
                Slider.maximumValue = Float(soundPlayer.duration)
                Slider.isUserInteractionEnabled = true
            }
            
            else if recording == false{
                soundPlayer.pause()
                stopTimer()
            }
        }
        
        if currentButtonState == 2{// play audio
            initTimer()
            //print("slider_max = \(Slider.maximumValue),duration= \(Float(soundPlayer.duration))")
            //print("SP currentButtonState time = \(soundPlayer.currentTime), Slider.val = \(TimeInterval(Slider.value))")
            soundPlayer.play()
        }
        
        buttonModification()
        
    }
    
    func initTimer(){
        AudioTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    
    func stopTimer(){
        AudioTimer.invalidate()
    } //ooga booga
    
    @objc func updateTimer(){
        let minutes = floor(soundPlayer.currentTime/60)
        let seconds = round(soundPlayer.currentTime - minutes * 60)
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
    
    func buttonModification(){
        if currentButtonState == 0 || currentButtonState == 2{
            if #available(iOS 13.0, *) {
                let pauseImage = UIImage(systemName: "pause.circle")
                self.MultiButton.setBackgroundImage(pauseImage, for: [])
                self.MultiButton.tintColor = UIColor.systemGray
                currentButtonState = 1
            }
        }
        else if currentButtonState == 1{
            if #available(iOS 13.0, *) {
                let playImage = UIImage(systemName: "play.circle")
                self.MultiButton.setBackgroundImage(playImage, for: [])
                self.MultiButton.tintColor = UIColor.systemBlue
                currentButtonState = 2
            }
        }
        
    }
    
    @objc func backPedal(){
        if(currentButtonState != 2){
            let minutes = floor(soundRecorder.currentTime/60)
            let seconds = round(soundRecorder.currentTime - minutes * 60)
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
        }
    }
    
    func timeStampColor(){
        if recording == true{
            TimeReader.textColor = UIColor.systemRed
            TimeReader.text = "REC"
        }
        else{
            TimeReader.textColor = UIColor.black
            TimeReader.text = "00:00"
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if #available(iOS 13.0, *) {
            soundPlayer.pause()
            //soundPlayer.currentTime = soundPlayer.duration
            let playImage = UIImage(systemName: "play.circle")
            self.MultiButton.setBackgroundImage(playImage, for: [])
            self.MultiButton.tintColor = UIColor.systemBlue
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
        NotificationCenter.default.addObserver(self, selector: #selector(detailWillResignActive), name: UIApplication.willResignActiveNotification,object: nil)
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        
        let backpedalButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.action, target: self, action: #selector(backPedal))
        
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
        }
        self.TitleTextBox.text = cnote.name
        self.Write.text = cnote.content
        loaded = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if (loaded){
            let cnote = foundData[0]
            if self.TitleTextBox.text != ""{
                cnote.name = self.TitleTextBox.text!
            }
            cnote.content = self.Write.text
            loaded = false
            
            soundPlayer.pause()
        }
    }
    
    @objc func detailWillResignActive(){
        if (loaded){
            let cnote = foundData[0]
            if self.TitleTextBox.text != ""{
                cnote.name = self.TitleTextBox.text!
            }
            cnote.content = self.Write.text
            loaded = false
            
        }
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
        } catch {}
        
        cnote.audio = audioTrack
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func setupRecorder() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("\(selected)AudioFile.m4a")
        //cnote.audio = audioFilename as! NSData?
        let recordSetting = [ AVFormatIDKey : kAudioFormatAppleLossless,
                              AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
                              AVEncoderBitRateKey : 320000,
                              AVNumberOfChannelsKey : 2,
                              AVSampleRateKey : 44100.2] as [String : Any]
        
        do {
            soundRecorder = try AVAudioRecorder(url: audioFilename, settings: recordSetting )
            soundRecorder.delegate = self
            soundRecorder.prepareToRecord()
        } catch {
            print(error)
        }
    }
    
    func setupPlayer() {
        //let audioFilename = getDocumentsDirectory().appendingPathComponent("\(selected)AudioFile.m4a")
        let cnote = foundData[0]
    
        
        do {
            print(cnote.audio)
            soundPlayer = try AVAudioPlayer(data: cnote.audio!)
            print("success!!!!")
            soundPlayer.delegate = self
            soundPlayer.prepareToPlay()
            soundPlayer.volume = 1.0
        } catch {
            print(error)
        }
    }

}

