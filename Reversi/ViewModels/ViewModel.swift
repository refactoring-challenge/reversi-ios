//
//  ViewModel.swift
//  Reversi
//
//  Created by Yuto Mizutani on 2020/04/24.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation

public struct ViewModel {
    public private(set) var board: Board

    public init(board: Board) {
        self.board = board
    }
}
