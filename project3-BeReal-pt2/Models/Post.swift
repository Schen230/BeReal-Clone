//
//  Post.swift
//  project2-BeReal
//
//  Created by Sunny Chen on 9/14/24.
//

import Foundation
import ParseSwift

// Create Post Parse Object model

struct Post : ParseObject{
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?
    
    var caption: String?
    var user: User?
    var imageFile: ParseFile?
    
    var comments: [Comment]?
    
    var city: String?
    var state: String?
    
    var latitude: Double?
    var longitude: Double?
    var date: Date?
}
