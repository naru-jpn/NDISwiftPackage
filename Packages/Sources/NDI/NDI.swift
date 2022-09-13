import CoreMedia
import Foundation
import libndi

public enum NDISenderError: Error {
    case notInitialized
    case senderIsAlreadyCreated
    case failedToGetNDIName(name: String)
    case failedToCreateSender
    case noSenderCreated
    case invalidPixelFormatType(expected: OSType, actual: OSType)
    case failedToGetPixelBufferBaseAddress
}

public class NDISender {
    public static let shared = NDISender()
    
    public private(set) var isInitialized = false
    private var sender: NDIlib_send_instance_t?
    
    @discardableResult
    public func initialize() -> Bool {
        guard !isInitialized else {
            return true
        }
        isInitialized = NDIlib_initialize()
        return isInitialized
    }
    
    /// Crate sender
    public func create(with ndiName: String) throws {
        guard isInitialized else {
            throw NDISenderError.notInitialized
        }
        guard sender == nil else {
            throw NDISenderError.senderIsAlreadyCreated
        }
        var settings = NDIlib_send_create_t()
        guard let name: UnsafePointer<CChar> = ndiName.cString(using: .utf8)?.withUnsafeBytes({ $0.bindMemory(to: CChar.self).baseAddress }) else {
            throw NDISenderError.failedToGetNDIName(name: ndiName)
        }
        settings.p_ndi_name = name
        settings.p_groups = nil
        settings.clock_video = false
        settings.clock_audio = false
        sender = NDIlib_send_create(&settings)
        if sender == nil {
            throw NDISenderError.failedToCreateSender
        }
    }
    
    /// Send YCbCr format CVPixelBuffer
    public func send(pixelBuffer: CVPixelBuffer) throws {
        guard let sender = sender else {
            throw NDISenderError.noSenderCreated
        }
        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        guard pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange else {
            throw NDISenderError.invalidPixelFormatType(expected: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, actual: pixelFormat)
        }
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        var bottom:Int = 0
        CVPixelBufferGetExtendedPixels(pixelBuffer, nil, nil, nil, &bottom)
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        let capacity = bytesPerRow * (height + bottom) * 2
        guard let address = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)?.bindMemory(to: UInt8.self, capacity: capacity) else {
            throw NDISenderError.failedToGetPixelBufferBaseAddress
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        var videoFrame = NDIlib_video_frame_v2_t()
        videoFrame.xres = Int32(width)
        videoFrame.yres = Int32(height + bottom)
        videoFrame.FourCC = NDIlib_FourCC_video_type_NV12
        videoFrame.line_stride_in_bytes = Int32(bytesPerRow)
        videoFrame.p_data = address
        NDIlib_send_send_video_v2(sender, &videoFrame)
    }
    
    /// Destroy sender
    public func destroy() {
        guard let sender = sender else {
            return
        }
        NDIlib_send_destroy(sender)
        self.sender = nil
    }
}
