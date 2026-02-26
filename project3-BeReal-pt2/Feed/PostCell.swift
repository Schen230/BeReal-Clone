//
//  PostCell.swift
//  project2-BeReal
//
//  Created by Sunny Chen on 9/14/24.
//

import UIKit
import Alamofire
import AlamofireImage
import ParseSwift

class PostCell: UITableViewCell {

    @IBOutlet private weak var usernameLabel: UILabel!
    @IBOutlet private weak var postImageView: UIImageView!
    @IBOutlet private weak var captionLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    // Blur view to blur out "hidden" posts
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    private var imageDataRequest: DataRequest?

    func configure(with post: Post) {
        // Configure Post Cell
        // Username
        if let user = post.user {
            usernameLabel.text = user.username
            print("Post user objectId: \(user.objectId ?? "nil")")
            print("Post user username: \(user.username ?? "nil")")
            
            // attempt to fetch the user
            user.fetch { [weak self] result in
                switch result {
                case.success(let fetchedUser):
                    print("Fetched user objectId: \(fetchedUser.objectId ?? "nil")")
                    print("Fetched user username: \(fetchedUser.username ?? "nil")")
                    DispatchQueue.main.async {
                        self?.usernameLabel.text = fetchedUser.username
                    }
                case.failure(let error):
                    print("Error fetching user: \(error.localizedDescription)")
                    // Fallback to the cached username
                    DispatchQueue.main.async {
                        self?.usernameLabel.text = user.username ?? "Unknown User"
                    }
                }
            }
        } else {
            print("No user associated with this post")
            usernameLabel.text = "Unknown User"
        }
        
        // Image
        if let imageFile = post.imageFile,
           let imageUrl = imageFile.url {
            
            //Use AlamofireImage helper to fetch remote image from URL
            imageDataRequest = AF.request(imageUrl).responseImage { [weak self] response in
                switch response.result {
                case.success(let image):
                    // Set image view image with fetched image
                    self?.postImageView.image = image
                case.failure(let error):
                    print("Error fetching image: \(error.localizedDescription)")
                }
            }
        }
        // Caption
        captionLabel.text = post.caption
        
        //Date
        if let date = post.createdAt {
            dateLabel.text = DateFormatter.postFormatter.string(from: date)
        }
        
        // Blur posts unless it has been shared in the last 24 hrs.
        // A lot of the following returns optional values so we'll unwrap them all together in one big 'if let'
        // Get the current user
        if let currentUser = User.current,
            
            // Get the date the user last shared a post
        let lastPostedDate = currentUser.lastPostedDate,
        
        // Get the date the givn post was created
        let postCreatedDate = post.createdAt,
        
        // Get the difference in hours between when the given post was created and the current user last posted.
        let diffHours = Calendar.current.dateComponents([.hour], from: postCreatedDate, to: lastPostedDate).hour {
            blurView.isHidden = abs(diffHours) < 24
        } else {
            blurView.isHidden = false
        }
        
        // Set location
        if let city = post.city, let state = post.state {
            locationLabel.text = "\(city), \(state)"
        } else {
            locationLabel.text = "Location Unknown"
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // Cancel image download
        // Reset iamge view image
        postImageView.image = nil
        imageDataRequest?.cancel()
    }
}
