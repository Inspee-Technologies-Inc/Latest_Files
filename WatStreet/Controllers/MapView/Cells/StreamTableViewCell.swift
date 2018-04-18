//
//  StreamTableViewCell.swift
//  WatStreet
//
//  Created by Eric on 1/17/18.
//  Copyright © 2018 Developer. All rights reserved.
//

import UIKit

class StreamTableViewCell: UITableViewCell {
    let wowzaServer = "18.218.129.201"
    var feeds: [FeedInfo]!
    var mediaPlayer: VLCMediaPlayer!
    
    @IBOutlet weak var containerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        mediaPlayer = VLCMediaPlayer.init()
    }
    
    func setFeeds(_ feeds: [FeedInfo]!) {
        self.feeds = feeds
    }
    
    @IBAction func onNext(_ sender: Any) {
    }
    
    @IBAction func onBefore(_ sender: Any) {
    }
    
    @IBAction func onPlay(_ sender: Any) {
        if (feeds.count == 0) {
            return
        }
        
        let feed = feeds[0]
        mediaPlayer.media = VLCMedia.init(url: URL(string: "rtsp://\(wowzaServer):1935/live/\(feed.uid!)")!)
        mediaPlayer.drawable = self.containerView
        mediaPlayer.play()
    }
}
