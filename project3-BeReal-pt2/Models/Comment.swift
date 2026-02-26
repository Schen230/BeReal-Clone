//
//  Comment.swift
//  project3-BeReal-pt2
//
//  Created by Sunny Chen on 9/28/24.
//

import Foundation
import ParseSwift

// Create Comment Parse Object model

struct Comment : ParseObject{
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?
    
    var text: String?
    var user: User?
    var post: Post?
}
