//
//  SampleHandler.swift
//  broadcast-upload
//
//  Created by Naruki Chigira on 2022/09/13.
//

import NDI
import ReplayKit

class SampleHandler: RPBroadcastSampleHandler {
    private lazy var duplicator = PixelBufferDuplicator()

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        NDISender.shared.initialize()
        do {
            try NDISender.shared.create(with: "NDI Test")
        } catch {
            let userInfo = [NSLocalizedFailureReasonErrorKey: "Failed to create NDI sender."]
            finishBroadcastWithError(NSError(domain: "broadcast-upload", code: -1, userInfo: userInfo) as Error)
        }
    }
    
    override func broadcastPaused() {
    }
    
    override func broadcastResumed() {
    }
    
    override func broadcastFinished() {
        NDISender.shared.destroy()
    }
    
    override func finishBroadcastWithError(_ error: Error) {
        super.finishBroadcastWithError(error)
        NDISender.shared.destroy()
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            do {
                guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                    return
                }
                let pixelBuffer = try duplicator.duplicate(pixelBuffer: imageBuffer)
                try NDISender.shared.send(pixelBuffer: pixelBuffer)
            } catch {
                let userInfo = [NSLocalizedFailureReasonErrorKey: "Failed to send sample buffer with error: \(error)."]
                finishBroadcastWithError(NSError(domain: "broadcast-upload", code: -1, userInfo: userInfo) as Error)
            }
            break
        case RPSampleBufferType.audioApp:
            break
        case RPSampleBufferType.audioMic:
            break
        @unknown default:
            fatalError("Unknown type of sample buffer")
        }
    }
}
