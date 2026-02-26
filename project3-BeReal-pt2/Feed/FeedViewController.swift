//
//  FeedViewController.swift
//  project2-BeReal
//
//  Created by Sunny Chen on 9/14/24.
//

import UIKit
import ParseSwift

class FeedViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private let refreshControl = UIRefreshControl()
    
    private var posts = [Post]() {
        didSet {
            // Reload table view data any time the posts variable gets updated.
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = true
        
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        queryPosts()
    }
    
    let yesterdayDate = Calendar.current.date(byAdding: .day, value: (-1), to: Date())!
    
    private func queryPosts() {
        // TODO: Pt 1 - Query Posts
        // 1. Create a query to fetch Posts
        // 2. Any properties that are parse objects are stored by reference in Parse DB and as such need to explicitly use 'include_:)' to be included in query results.
        // 3. Sort the posts by descending order based on the created at date
        let query = Post.query()
            .include("user", "comments", "comments.user")
            .order([.descending("createdAt")])
            .where("createdAt" >= yesterdayDate)
            .limit(10)
        
        //Fetch objects (posts) defined in query (async)
        query.find { [weak self] result in
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
                
                switch result{
                case.success(let posts):
                    // Update local posts property with fetched posts
                    self?.posts = posts
                case.failure(let error):
                    self?.showAlert(description: error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func refreshData(_ sender: Any) {
        queryPosts()
    }
    
    @IBAction func onLogOutTapped(_ sender: Any) {
        showConfirmLogoutAlert()
    }
    
    private func showConfirmLogoutAlert() {
        let alertController = UIAlertController(title: "Log out of your account?", message: nil, preferredStyle: .alert)
        let logOutAction = UIAlertAction(title: "Log out", style: .destructive) { _ in
            NotificationCenter.default.post(name: Notification.Name("logout"), object: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(logOutAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    private func showAlert(description: String? = nil) {
        let alertController = UIAlertController(title: "Oops...", message: "\(description ?? "Please try again...")", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
}

extension FeedViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let post = posts[section]
        let comments = post.comments
        
        // Add another row for the add comment button
        return (comments?.count ?? 0) + 2
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let post = posts[indexPath.section]
        let comments = post.comments ?? []
        
        // Regular PostCell
        if indexPath.row == 0 {
            guard let postCell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostCell
            else {
                return UITableViewCell()
            }
            postCell.configure(with: posts[indexPath.section])
            return postCell
            
        } else if indexPath.row <= comments.count {
                guard let commentCell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as? CommentCell
            else {
                    return UITableViewCell()
            }
            
            if (comments.count > 0) {
                let comment = comments[indexPath.row - 1]
                commentCell.nameLabel.text = comment.user?.username
                commentCell.commentLabel.text = comment.text
            }
            return commentCell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddCommentCell")!
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let post = posts[indexPath.section]
        let comments = post.comments ?? []
        
        // Check if the tapped row is the "Add Comment" cell
        if indexPath.row == comments.count + 1 {
            showCommentInputAlert(for: post, at: indexPath.section)
        } else {
            // Handle selection of other cells (if needed)
            print("Selected row: \(indexPath.row) in section \(indexPath.section)")
        }
    }
        
        private func showCommentInputAlert(for post: Post, at index: Int) {
            // Create and configure an alert controller with a text field
            let alertController = UIAlertController(title: "Add Comment", message: nil, preferredStyle: .alert)
            
            alertController.addTextField { textField in
                textField.placeholder = "Enter your comment here..."
            }
            
            // Add a "Cancel" action
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            // Add a "Submit" action
            let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self] _ in
                guard let commentText = alertController.textFields?.first?.text, !commentText.isEmpty else {
                    return
                }
                self?.saveComment(text: commentText, for: post, at: index)
            }
            alertController.addAction(submitAction)
            
            // Preent the alert controller
            present(alertController, animated: true, completion: nil)
        }
    
    private func saveComment(text: String, for post: Post, at index: Int) {
        var comment = Comment()
        comment.text = text
        comment.post = post
        comment.user = User.current

        comment.save { [weak self] result in
            switch result {
            case.success(let savedComment):
                print("Comment saved successfully: \(savedComment)")
                
                // Now add comment to the post
                var updatedPost = post
                
                // Initialize the comments array if its nil
                if updatedPost.comments == nil {
                    updatedPost.comments = []
                }
                
                // Append the new comment to the post's comments array
                updatedPost.comments?.append(savedComment)
                
                // Save the updated post
                updatedPost.save { [weak self] result in
                    switch result {
                    case.success(let savedPost):
                        print("Post updated with new comment: \(savedPost)")
                        DispatchQueue.main.async {
                            // Update the local posts array
                            self?.posts[index] = savedPost
                            // Reload the specific section
                            self?.tableView.reloadSections(IndexSet(integer: index), with: .automatic)
                        }
                    case.failure(let error):
                        print("Error saving post with comment: \(error)")
                    }
                }
            case.failure(let error):
                assertionFailure("Error saving comment: \(error)")
            }
        }
    }
}

extension FeedViewController: UITableViewDelegate { }
