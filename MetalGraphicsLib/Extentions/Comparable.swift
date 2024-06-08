//
//  Comparable.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 26.01.2023.
//

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
