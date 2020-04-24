//
//  Board.swift
//  Reversi
//
//  Created by Yuto Mizutani on 2020/04/24.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation

public struct Board {
    /// 盤のサイズ（width: `8`, height: `8`）を表します。
    /// - Parameters:
    ///   - width: 盤の幅（ `8` ）を表します。
    ///   - height: 盤の高さ（ `8` ）を返します。
    public var size: (width: Int, height: Int) = (8, 8)

    /// 盤のセルの範囲（x: `0 ..< 8`, y: `0..<8`）を返します。
    /// - Parameters:
    ///   - x: 盤のセルの `x` の範囲（ `0 ..< 8` ）を返します。
    ///   - y: 盤のセルの `y` の範囲（ `0 ..< 8` ）を返します。
    public var range: (x: Range<Int>, y: Range<Int>) {
        (0 ..< size.width, 0 ..< size.height)
    }

    public init(width: Int, height: Int) {
        self.init(size: (width, height))
    }

    private init(size: (width: Int, height: Int)) {
        self.size = size
    }
}
