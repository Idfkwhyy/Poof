import Cocoa

class PoofWindow: NSWindow {
    private var imageView: NSImageView!
    private var animationFrames: [NSImage] = []
    private var currentFrame = 0
    private var animationTimer: Timer?
    
    init(at point: NSPoint, size: CGFloat = 128) {
        let windowRect = NSRect(x: point.x - size/2, y: point.y - size/2, width: size, height: size)
            
        super.init(contentRect: windowRect,
                   styleMask: .borderless,
                   backing: .buffered,
                   defer: false)
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        setupImageView()
        loadAnimationFrames()
    }
    
    private func setupImageView() {
        imageView = NSImageView(frame: self.contentView!.bounds)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        self.contentView?.addSubview(imageView)
    }
    
    private func loadAnimationFrames() {
        guard let poofImage = NSImage(named: "poof") else {
            print("Could not load poof image")
            return
        }
        
        print("Loaded poof image")
        
        guard let imageRep = poofImage.representations.first else {
            print("No image representation")
            return
        }
        
        let imageWidth = imageRep.pixelsWide
        let imageHeight = imageRep.pixelsHigh
        
        print("Image size: \(imageWidth)x\(imageHeight)")
        
        let frameCount = 5
        let frameWidth = imageWidth
        let frameHeight = imageHeight / frameCount
        
        print("Frame size: \(frameWidth)x\(frameHeight)")
        
        for i in 0..<frameCount {
            let yPosition = i * frameHeight
            let frameRect = NSRect(x: 0, y: yPosition, width: frameWidth, height: frameHeight)
            
            if let frameImage = extractFrame(from: poofImage, rect: frameRect, imageSize: NSSize(width: imageWidth, height: imageHeight)) {
                animationFrames.append(frameImage)
                print("Extracted frame \(i+1)")
            } else {
                print("Failed to extract frame \(i+1)")
            }
        }
        
        print("Total frames extracted: \(animationFrames.count)")
    }
    
    private func extractFrame(from image: NSImage, rect: NSRect, imageSize: NSSize) -> NSImage? {
        let frameSize = NSSize(width: rect.width, height: rect.height)
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let scale = CGFloat(cgImage.width) / imageSize.width
        let cgRect = CGRect(x: rect.origin.x * scale,
                           y: rect.origin.y * scale,
                           width: rect.width * scale,
                           height: rect.height * scale)
        
        guard let croppedCGImage = cgImage.cropping(to: cgRect) else {
            return nil
        }
        
        let croppedImage = NSImage(cgImage: croppedCGImage, size: frameSize)
        return croppedImage
    }
    
    func playAnimation(completion: @escaping () -> Void) {
        currentFrame = 0
        
        guard !animationFrames.isEmpty else {
            print("No animation frames available")
            completion()
            return
        }
        
        print("Starting animation with \(animationFrames.count) frames")
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 12.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if self.currentFrame < self.animationFrames.count {
                self.imageView?.image = self.animationFrames[self.currentFrame]
                self.currentFrame += 1
                
                if self.currentFrame == self.animationFrames.count {
                    print("Last frame displayed, will complete after one more cycle")
                }
            } else {
                print("Animation complete, invalidating timer")
                timer.invalidate()
                self.animationTimer = nil
                
                print("Calling completion block")
                completion()
            }
        }
    }
    
    deinit {
        animationTimer?.invalidate()
        animationTimer = nil
        print("PoofWindow deallocated")
    }
}
