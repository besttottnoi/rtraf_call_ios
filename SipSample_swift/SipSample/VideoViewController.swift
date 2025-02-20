//
//  VideoViewController.m
//  SIPSample
//
//  Copyright (c) 2013 PortSIP Solutions, Inc. All rights reserved.
//

import UIKit

class VideoViewController: UIViewController {
    var mCameraDeviceId: Int = 1 // 1 - FrontCamra 0 - BackCamra
    var mLocalVideoWidth: Int = 352
    var mLocalVideoHeight: Int = 288
    var isStartVideo = false
    var isInitVideo = false
    var sessionId: Int = 0

    var portSIPSDK: PortSIPSDK!

    @IBOutlet var viewLocalVideo: PortSIPVideoRenderView!
    @IBOutlet var viewRemoteVideo: PortSIPVideoRenderView!
    @IBOutlet var viewRemoteVideoSmall:PortSIPVideoRenderView!
    var shareInSmallWindow=true
    @IBOutlet var buttonConference: UIButton!

    func checkDisplayVideo() {
        let application = UIApplication.shared
        let appDelegate = application.delegate as! AppDelegate
        guard let result = appDelegate._callManager.findCallBySessionID(sessionId) else {
            return
        }
        
       
        if isInitVideo {
            if isStartVideo {

                self.viewRemoteVideoSmall.isHidden = !result.session.screenShare;
                
                if(self.shareInSmallWindow){
                    portSIPSDK.setRemoteScreenWindow(sessionId, remoteScreenWindow: viewRemoteVideoSmall)
                    if(appDelegate.isConference!){
                        portSIPSDK.setRemoteVideoWindow(sessionId, remoteVideoWindow: nil)
                        portSIPSDK.setConferenceVideoWindow(viewRemoteVideo)
                    }else{
                        portSIPSDK.setRemoteVideoWindow(sessionId, remoteVideoWindow: viewRemoteVideo)
                        portSIPSDK.setConferenceVideoWindow(nil)
                    }
                }else{
                    portSIPSDK.setRemoteScreenWindow(sessionId, remoteScreenWindow: viewRemoteVideo)
                    
                    if(appDelegate.isConference!){
                        portSIPSDK.setRemoteVideoWindow(sessionId, remoteVideoWindow: nil)
                        portSIPSDK.setConferenceVideoWindow(viewRemoteVideoSmall)
                    }else{
                        portSIPSDK.setRemoteVideoWindow(sessionId, remoteVideoWindow: viewRemoteVideoSmall)
                        portSIPSDK.setConferenceVideoWindow(nil)
                    }
                }
            
                portSIPSDK.displayLocalVideo(true, mirror: mCameraDeviceId == 0, localVideoWindow: viewLocalVideo)
                portSIPSDK.sendVideo(sessionId, sendState: true)
            } else {
                self.viewRemoteVideoSmall.isHidden = true;
                portSIPSDK.displayLocalVideo(false,mirror:false,localVideoWindow: nil)
                portSIPSDK.setRemoteVideoWindow(sessionId, remoteVideoWindow: nil)
                portSIPSDK.setRemoteScreenWindow(sessionId, remoteScreenWindow: nil)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        isInitVideo = true

        viewLocalVideo.initVideoRender()
        viewRemoteVideo.initVideoRender()
        // contents scaled to fit with fixed aspect. remainder is transparent
        viewRemoteVideo.contentMode = .scaleAspectFit;
        // contents scaled to fill with fixed aspect. some portion of content may be clipped.
        //viewRemoteVideo.contentMode = .scaleAspectFill;
        
        viewRemoteVideoSmall.initVideoRender()
        
        let tapGesture = UITapGestureRecognizer.init(target:self, action: #selector(onSwichShareScreenClick(action:)))

        self.viewRemoteVideoSmall.addGestureRecognizer(tapGesture);
        
        updateLocalVideoPosition(UIScreen.main.bounds.size)
    }

    override func viewDidAppear(_: Bool) {
        checkDisplayVideo()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // best call super just in case
        super.viewWillTransition(to: size, with: coordinator)
        // will execute before rotation
        coordinator.animate(alongsideTransition: { (_: Any) -> Void in
            // will execute during rotation
            self.updateLocalVideoPosition(size)
        }, completion: { (_: Any) -> Void in
            // will execute after rotation
        })
    }

    @IBAction func onSwitchSpeakerClick(_ sender: AnyObject) {
        let buttonSpeaker = sender as! UIButton

        if buttonSpeaker.titleLabel?.text == "Speaker" {
            portSIPSDK.setLoudspeakerStatus(true)
            buttonSpeaker.setTitle("Headphone", for: .normal)
        } else {
            portSIPSDK.setLoudspeakerStatus(false)
            buttonSpeaker.setTitle("Speaker", for: .normal)
        }
    }

    @IBAction func onSwitchCameraClick(_ sender: AnyObject) {
        let buttonCamera = sender as! UIButton
        if buttonCamera.titleLabel!.text == "FrontCamera" {
            if portSIPSDK.setVideoDeviceId(1) == 0 {
                mCameraDeviceId = 1
                buttonCamera.setTitle("BackCamera", for: .normal)
            }
        } else {
            if portSIPSDK.setVideoDeviceId(0) == 0 {
                mCameraDeviceId = 0
                buttonCamera.setTitle("FrontCamera", for: .normal)
            }
        }
    }
    
    @IBAction func onSwichShareScreenClick(action:UITapGestureRecognizer)->Void {

        self.shareInSmallWindow = !self.shareInSmallWindow
        self.checkDisplayVideo()
    }
    
    @IBAction func onSendingVideoClick(_ sender: AnyObject) {
        let buttonSendingVideo = sender as! UIButton

        if buttonSendingVideo.titleLabel!.text == "PauseSending" {
            portSIPSDK.sendVideo(sessionId, sendState: false)
            buttonSendingVideo.setTitle("StartSending", for: .normal)
        } else {
            portSIPSDK.sendVideo(sessionId, sendState: true)
            buttonSendingVideo.setTitle("PauseSending", for: .normal)
        }
    }

    @IBAction func onConference(_ sender: AnyObject) {
        let buttonConference = sender as! UIButton
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if buttonConference.titleLabel!.text == "Conference" {
            appDelegate.createConference(viewRemoteVideo)
            buttonConference.setTitle("UnConference", for: .normal)
        } else {
            appDelegate.destoryConference(viewRemoteVideo)
            portSIPSDK.setRemoteVideoWindow(sessionId, remoteVideoWindow: viewRemoteVideo)
            buttonConference.setTitle("Conference", for: .normal)
        }
    }

    func onStartVideo(_ sessionID: Int) {
        isStartVideo = true
        sessionId = sessionID
        shareInSmallWindow = true;
        checkDisplayVideo()
    }

    func onStopVideo(_: Int) {
        isStartVideo = false
        checkDisplayVideo()
    }

    func updateLocalVideoPosition(_ screenSize: CGSize) {
        if viewLocalVideo == nil {
            return
        }

        if screenSize.width > screenSize.height {
            // Landscape
            var rectLocal: CGRect = viewLocalVideo.frame
            rectLocal.size.width = 176
            rectLocal.size.height = CGFloat(Int(rectLocal.size.width) * mLocalVideoHeight / mLocalVideoWidth)
            rectLocal.origin.x = screenSize.width - rectLocal.size.width - 10
            rectLocal.origin.y = 10

            print(rectLocal.size.height)
            viewLocalVideo.frame = rectLocal
        } else {
            var rectLocal: CGRect = viewLocalVideo.frame
            rectLocal.size.width = 144
            rectLocal.size.height = CGFloat(Int(rectLocal.size.width) * mLocalVideoWidth / mLocalVideoHeight)
            rectLocal.origin.x = screenSize.width - rectLocal.size.width - 10
            rectLocal.origin.y = 30
            viewLocalVideo.frame = rectLocal
        }
    }

    func updateLocalVideoCaptureSize(_ width: Int, height: Int) {
        if height <= 0 || width <= 0 {
            return
        }
        if mLocalVideoHeight != height || mLocalVideoWidth != width {
            mLocalVideoWidth = width
            mLocalVideoHeight = height
            updateLocalVideoPosition(UIScreen.main.bounds.size)
            print("updateLocalVideoCaptureSize width=\(width) height=\(height)")
        }
    }
}
