//
//  ImageRawData.swift
//  Snoopy
//
//  Created by Yaxin Cheng on 2025-08-13.
//

import Foundation
import ImageIO
import SpriteKit

struct ImageRawData {
    let data: Data
    private let width: Int
    private let height: Int

    enum Error: Swift.Error {
        case failedToLoadImage
        case failedToConvertToRawData
    }

    init(contentsOf fileURL: URL) throws {
        let data = try Data(contentsOf: fileURL)
        try self.init(imageData: data)
    }

    var size: CGSize {
        CGSize(width: width, height: height)
    }

    static func asyncFrom(contentsOf fileURL: URL) async throws -> Self {
        let (data, _) = try await URLSession.shared.data(from: fileURL)
        return try self.init(imageData: data)
    }

    init(imageData: Data) throws {
        guard
            let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
            let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        else {
            throw Error.failedToLoadImage
        }
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData = Data(count: height * bytesPerRow)
        try pixelData.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            ) else {
                throw Error.failedToConvertToRawData
            }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        self.data = pixelData
        self.width = width
        self.height = height
    }
}
