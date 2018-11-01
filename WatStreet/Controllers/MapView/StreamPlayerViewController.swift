//
//  StreamPlayerViewController.swift
//  WatStreet
//
//  Created by Eric on 1/18/18.
//  Copyright © 2018 Developer. All rights reserved.
//

import UIKit
import SVProgressHUD
import FirebaseAuth

class StreamPlayerViewController: UIViewController, VLCMediaPlayerDelegate {
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var fullModeButton: UIButton!
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var stredCredLabel: UILabel!
    
    @IBOutlet weak var ratingView: UIView!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    
    var mediaPlayer: VLCMediaPlayer!
    var tours: [TourRequestInfo]!
    var preview: UIView!
    var currentIndex: Int!
    var currentTour: TourRequestInfo!
    var isFullMode = false
    var feedManager: FeedManager!
    
    var feedInfo: FeedInfo!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        feedManager = FeedManager.init()
        
        preview = UIView.init()
        preview.frame = self.view.bounds
        preview.clipsToBounds = true
        self.view.insertSubview(preview, at: 0)
        
        currentIndex = -1
        currentTour = nil
        tours = []
        
        mediaPlayer = VLCMediaPlayer.init()
        mediaPlayer.delegate = self
        
        ratingView.isHidden = true
        
        stredCredLabel.isUserInteractionEnabled = true
        stredCredLabel.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(FeedsTableViewCell.onTapCred)))
        
        if (feedInfo != nil) {
            userNameLabel.text = ""
            stredCredLabel.text = "@ \((feedInfo.street)!)"
            leftButton.isHidden = true
            rightButton.isHidden = true
            summaryLabel.text = feedInfo.text
            fullModeButton.setImage(#imageLiteral(resourceName: "ico_close"), for: .normal)
            self.onPlay(playButton)
        } else {
            commentLabel.isHidden = true
            summaryLabel.isHidden = true
        }
    }
    
    func setTours(_ tours: [TourRequestInfo]!) {
        self.tours = tours
        
        countLabel.text = "0 / \(tours.count)"
        currentIndex = 0
        
        if (currentTour != nil) {
            var index = 0
            currentIndex = -1
            for item in tours {
                if (item.uid == currentTour?.uid) {
                    currentIndex = index
                    currentTour = item
                    countLabel.text = "\((index + 1)) / \(tours.count)"
                    return
                }
                index = index + 1
            }
            
            if (mediaPlayer.isPlaying) {
                mediaPlayer.stop()
            }
        }
        
        countLabel.text = "\((currentIndex + 1)) / \(tours.count)"
        self.displayInfo()
    }
    
    func displayInfo() {
        if (currentTour == nil) {
            currentTour = (tours.count > 0 && currentIndex != -1) ? tours[currentIndex] : nil
        }
        
        if (currentTour == nil) {
            userNameLabel.text = ""
            stredCredLabel.text = ""
        } else {
            userNameLabel.text = currentTour.authorName.capitalized
            stredCredLabel.text = " @ \((currentTour.street)!)"
        }
    }
    
    @objc func onTapCred() {
        if (currentTour == nil) {
            return
        }
        
//        stredCredLabel.text = " - Street Cred - \(InputValidator.getCount(currentFeed.userLiked))"
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
//            self.stredCredLabel.text = " @ \((self.currentFeed.street)!)"
//        }
    }
    
    // MARK: UI Events
    
    @IBAction func onPlay(_ sender: UIButton) {
        playButton.isHidden = true

        if (feedInfo != nil) {
            mediaPlayer.media = VLCMedia.init(url: URL(string: feedInfo.photoUrl)!)
            preview.frame = self.view.bounds
            mediaPlayer.drawable = preview
            mediaPlayer.play()
        } else {
            if (currentIndex >= 0 && currentIndex < tours.count) {
                currentTour = tours[currentIndex]
                mediaPlayer.media = VLCMedia.init(url: URL(string: currentTour.videoUrl)!)
                preview.frame = self.view.bounds
                mediaPlayer.drawable = preview
                mediaPlayer.play()
                
                self.displayInfo()
            }
        }
    }
    
    @IBAction func onBefore(_ sender: Any) {
        currentIndex = currentIndex - 1
        if (currentIndex >= 0 && currentIndex < tours.count) {
            countLabel.text = "\((currentIndex+1)) / \(tours.count)"
        } else {
            currentIndex = currentIndex + 1
        }
        
        self.displayInfo()
        playButton.isHidden = false
    }
    
    @IBAction func onNext(_ sender: Any) {
        currentIndex = currentIndex + 1
        if (currentIndex >= 0 && currentIndex < tours.count) {
            countLabel.text = "\((currentIndex+1)) / \(tours.count)"
        } else {
            currentIndex = currentIndex - 1
        }

        self.displayInfo()
        playButton.isHidden = false
    }

    @IBAction func onFullscreen(_ sender: Any) {
        if (feedInfo != nil) {
            mediaPlayer.stop()
            self.navigationController?.popViewController(animated: true)
            return
        }
        if (!isFullMode) {
            isFullMode = true
            let containerView = (self.parent as! MainViewController).videoView
            containerView?.superview?.bringSubview(toFront: containerView!)
            UIView.animate(withDuration: 0.3) {
                containerView?.frame = (containerView?.superview?.bounds)!
                self.preview.frame = (containerView?.superview?.bounds)!
            }
        } else {
            isFullMode = false
            let containerView = (self.parent as! MainViewController).videoView
            let feedview = (self.parent as! MainViewController).feedContainerView
            UIView.animate(withDuration: 0.3) {
                containerView?.frame = (feedview?.frame)!
                self.preview.frame = (feedview?.bounds)!
            }
        }
    }
    
    @IBAction func onAwardPoint(_ sender: UIButton) {
        ratingView.isHidden = true
        FeedManager.shared.likeTour(self.currentTour, like: sender.tag)
        let containerView = (self.parent as! MainViewController).videoView
        containerView?.isHidden = true
    }
    
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        if (mediaPlayer.state == .ended) {
            playButton.isHidden = false
            
            if (feedInfo == nil) {
                if (self.currentTour.userId == Auth.auth().currentUser?.uid && self.currentTour.liked == 0) {
                    ratingView.isHidden = false
                } else {
                    let containerView = (self.parent as! MainViewController).videoView
                    containerView?.isHidden = true
                }
            }
        }
    }
    
}
