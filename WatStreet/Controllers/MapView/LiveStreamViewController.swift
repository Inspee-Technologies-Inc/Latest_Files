//
//  LiveStreamViewController.swift
//  WatStreet
//
//  Created by Eric on 1/17/18.
//  Copyright © 2018 Developer. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD
import HaishinKit
import AVFoundation
import VideoToolbox

let sampleRate:Double = 44_100

class LiveStreamViewController: UIViewController {
    // Live Streaming
    let wowzaServer = "159.89.137.82"
    var rtmpConnection:RTMPConnection = RTMPConnection()
    var rtmpStream:RTMPStream!
    var sharedObject:RTMPSharedObject!
    
    var currentPosition:AVCaptureDevice.Position = AVCaptureDevice.Position.back
    
    var streamKey: String!
    var recordSec: Int!
    var recordTimer: Timer?
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var viewCountLabel: UILabel!
    @IBOutlet weak var preview: GLLFView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rtmpStream = RTMPStream(connection: rtmpConnection)
        rtmpStream.syncOrientation = true
        rtmpStream.captureSettings = [
            "sessionPreset": AVCaptureSession.Preset.hd1280x720,
            "continuousAutofocus": true,
            "continuousExposure": true,
        ]
        rtmpStream.videoSettings = [
            "width": 480,
            "height": 854,
            "bitrate": (1024 * 1024)
        ]
        rtmpStream.audioSettings = [
            "sampleRate": sampleRate
        ]
        
        preview.backgroundColor = UIColor.black
        
        playButton.clipsToBounds = true
        playButton.layer.cornerRadius = playButton.frame.size.width / 2
        playButton.isUserInteractionEnabled = false
        
        recordSec = 0
        
        FeedManager.init().setupLiveEvent(streamKey) { (viewCount) in
            self.viewCountLabel.text = "  \(InputValidator.getCount(viewCount))"
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        rtmpStream.attachAudio(AVCaptureDevice.default(for: .audio)) { error in
            logger.warn(error.description)
        }
        rtmpStream.attachCamera(DeviceUtil.device(withPosition: currentPosition)) { error in
            logger.warn(error.description)
        }
        
        preview.attachStream(rtmpStream)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        rtmpStream.close()
        rtmpStream.dispose()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.startLiveStream()
    }
    
    // MARK: UI Events
    
    func startLiveStream() {
        UIApplication.shared.isIdleTimerDisabled = true
        rtmpConnection.addEventListener(Event.RTMP_STATUS, selector:#selector(LiveStreamViewController.rtmpStatusHandler(_:)), observer: self)
        rtmpConnection.connect("rtmp://\(wowzaServer):1935/live")
    }
    
    @IBAction func onStopStream(_ sender: Any) {
        if (recordTimer != nil) {
            recordTimer?.invalidate()
        }
        
        FeedManager.init().closeStream(streamKey) { (success) in
            if (success) {
                DispatchQueue.main.async {
                    UIApplication.shared.isIdleTimerDisabled = false
                    self.rtmpConnection.close()
                    self.rtmpConnection.removeEventListener(Event.RTMP_STATUS, selector:#selector(LiveStreamViewController.rtmpStatusHandler(_:)), observer: self)
                    
                    self.navigationController?.popViewController(animated: true)
                }
            } else {
                SVProgressHUD.showError(withStatus: "Could not stop the stream right now. Please try later.")
            }
        }
    }
    
    @objc func onRecodTime() {
        recordSec = recordSec + 1
        timerLabel.text = String.init(format: "%02d:%02d", recordSec / 60, recordSec % 60)
    }
    
    // MARK: Live Session Delegate
    @objc func rtmpStatusHandler(_ notification:Notification) {
        let e:Event = Event.from(notification)
        //        case callBadVersion       = "NetConnection.Call.BadVersion"
        //        case callFailed           = "NetConnection.Call.Failed"
        //        case callProhibited       = "NetConnection.Call.Prohibited"
        //        case connectAppshutdown   = "NetConnection.Connect.AppShutdown"
        //        case connectClosed        = "NetConnection.Connect.Closed"
        //        case connectFailed        = "NetConnection.Connect.Failed"
        //        case connectIdleTimeOut   = "NetConnection.Connect.IdleTimeOut"
        //        case connectInvalidApp    = "NetConnection.Connect.InvalidApp"
        //        case connectNetworkChange = "NetConnection.Connect.NetworkChange"
        //        case connectRejected      = "NetConnection.Connect.Rejected"
        //        case connectSuccess       = "NetConnection.Connect.Success"
        
        if let data:ASObject = e.data as? ASObject , let code:String = data["code"] as? String {
            switch code {
            case RTMPConnection.Code.connectSuccess.rawValue:
                DispatchQueue.main.async {
                    self.rtmpStream!.publish(self.streamKey)
                    self.playButton.isUserInteractionEnabled = true
                    self.playButton.tintColor = UIColor.red
                    
                    FeedManager.init().startStream(self.streamKey)
                    self.recordTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(LiveStreamViewController.onRecodTime), userInfo: nil, repeats: true)
                }
                
                print ("======== Connection Success. Start Publish! =======")
                break
                
            default:
                print ("======== State Changed (\(code)) =======")
                break
            }
        }
    }
}

