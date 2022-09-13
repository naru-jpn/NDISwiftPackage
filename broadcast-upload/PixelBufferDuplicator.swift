//
//  PixelBufferDuplicator.swift
//  broadcast-upload
//
//  Created by Naruki Chigira on 2022/09/06.
//

import Accelerate
import CoreMedia
import UIKit

/// Duplicate YCbCr format CVPixelBuffer
final class PixelBufferDuplicator {
    enum PixelBufferDuplicatorError: Error {
        case invalidInputPixelBufferFormatType(OSType, OSType)
        case failedToGetPixelBufferPool
        case failedToGetBaseAddressOfPlane(Int)
        case failedToGetBaseAddress
        case failedToCreatePixelBuffer
        case failedToGetOutputBaseAddress
    }

    private var pixelBufferSize: CGSize = .zero
    private var pixelBufferPool: CVPixelBufferPool?
    private var pixelBufferExtent: UIEdgeInsets = .zero
    private lazy var ciContext = CIContext()

    /// Duplicate YCbCr format CVPixelBuffer
    func duplicate(pixelBuffer: CVPixelBuffer) throws -> CVPixelBuffer {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        }

        // Check Pixel Format
        let pixelFormatType = CVPixelBufferGetPixelFormatType(pixelBuffer)
        guard pixelFormatType == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange else {
            throw PixelBufferDuplicatorError.invalidInputPixelBufferFormatType(pixelFormatType, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
        }

        // Get Extent
        var left: Int = 0
        var right: Int = 0
        var top: Int = 0
        var bottom: Int = 0
        CVPixelBufferGetExtendedPixels(pixelBuffer, &left, &right, &top, &bottom)
        pixelBufferExtent = UIEdgeInsets(top: CGFloat(top), left: CGFloat(left), bottom: CGFloat(bottom), right: CGFloat(right))

        // Setup PixelBufferPool
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let size = CGSize(width: width, height: height)
        if size != pixelBufferSize {
            pixelBufferSize = size
            setupPixelBufferPool(size: size, extent: pixelBufferExtent)
        }
        guard let pixelBufferPool = pixelBufferPool else {
            throw PixelBufferDuplicatorError.failedToGetPixelBufferPool
        }

        // Create Output CVPixelBuffer
        var pixelBufferOut: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &pixelBufferOut)
        guard let pixelBufferOut = pixelBufferOut else {
            throw PixelBufferDuplicatorError.failedToCreatePixelBuffer
        }

        let ciimage = CIImage(cvPixelBuffer: pixelBuffer)
        ciContext.render(ciimage, to: pixelBufferOut)
        return pixelBufferOut
    }

    private func setupPixelBufferPool(size: CGSize, extent: UIEdgeInsets) {
        let attributes = [
            kCVPixelBufferWidthKey: size.width,
            kCVPixelBufferHeightKey: size.height,
            kCVPixelBufferExtendedPixelsTopKey: Int(extent.top),
            kCVPixelBufferExtendedPixelsRightKey: Int(extent.right),
            kCVPixelBufferExtendedPixelsBottomKey: Int(extent.bottom),
            kCVPixelBufferExtendedPixelsLeftKey: Int(extent.left),
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
            kCVPixelBufferIOSurfacePropertiesKey: [:]
        ] as CFDictionary
        CVPixelBufferPoolCreate(nil, nil, attributes, &pixelBufferPool)
    }
}
