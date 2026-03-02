//
//  FlatComment.swift
//  Hackers
//
//  Created by Claude on 2026/03/02.
//

import Foundation

struct FlatComment: Identifiable {
    var id: Int { comment.id }
    var comment: HNItemLocalizable
    var depth: Int
}
