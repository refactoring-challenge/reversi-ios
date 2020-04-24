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
    public var size: (width: Int, height: Int) = (8, 8) {
        didSet {
            disks = (0 ..< (size.width * size.height)).map { _ in nil }
        }
    }

    public var disks: [Disk?] = []

    public init(width: Int, height: Int) {
        self.init(size: (width, height))
    }

    private init(size: (width: Int, height: Int)) {
        self.size = size
    }
}

public extension Board {
    /// 盤のセルの範囲（x: `0 ..< 8`, y: `0..<8`）を返します。
    /// - Parameters:
    ///   - x: 盤のセルの `x` の範囲（ `0 ..< 8` ）を返します。
    ///   - y: 盤のセルの `y` の範囲（ `0 ..< 8` ）を返します。
    var range: (x: Range<Int>, y: Range<Int>) {
        (0 ..< size.width, 0 ..< size.height)
    }

    /// `x`, `y` で指定されたセルの状態を返します。
    /// セルにディスクが置かれていない場合、 `nil` が返されます。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Returns: セルにディスクが置かれている場合はそのディスクの値を、置かれていない場合は `nil` を返します。
    func diskAt(x: Int, y: Int) -> Disk? {
        guard range.x.contains(x) && range.y.contains(y) else { return nil }
        return disks[y * size.width + x]
    }
}
