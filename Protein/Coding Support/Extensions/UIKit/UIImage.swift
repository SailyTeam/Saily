//
//  UIView+Shine.swift
//  PPHub
//
//  Created by AndyPang on 2018/8/30.
//  Copyright © 2017年 jkpang. All rights reserved.
//

import UIKit

extension UIImage {
    
    func areaAverage() -> UIColor {
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        
        if #available(iOS 9.0, *) {
            // Get average color.
            let context = CIContext()
            let inputImage: CIImage = ciImage ?? CoreImage.CIImage(cgImage: cgImage!)
            let extent = inputImage.extent
            let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
            let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: inputExtent])!
            let outputImage = filter.outputImage!
            let outputExtent = outputImage.extent
            assert(outputExtent.size.width == 1 && outputExtent.size.height == 1)
            // Render to bitmap.
            context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: CIFormat.RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        } else {
            // Create 1x1 context that interpolates pixels when drawing to it.
            let context = CGContext(data: &bitmap, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            let inputImage = cgImage ?? CIContext().createCGImage(ciImage!, from: ciImage!.extent)
            
            // Render to bitmap.
            context.draw(inputImage!, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        
        // Compute result.
        let result = UIColor(red: CGFloat(bitmap[0]) / 255.0, green: CGFloat(bitmap[1]) / 255.0, blue: CGFloat(bitmap[2]) / 255.0, alpha: CGFloat(bitmap[3]) / 255.0)
        return result
        
    }
    
    func blur(offset: Int? = 10) -> UIImage? {
        let context = CIContext(options: nil)
        let inputImage = CIImage(image: self)
        let originalOrientation = self.imageOrientation
        let originalScale = self.scale
        
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(inputImage, forKey: kCIInputImageKey)
        filter?.setValue(offset, forKey: kCIInputRadiusKey)
        let outputImage = filter?.outputImage
        
        var cgImage:CGImage?
        
        if let asd = outputImage {
            cgImage = context.createCGImage(asd, from: (inputImage?.extent)!)
        }
        
        if let cgImageA = cgImage {
            return UIImage(cgImage: cgImageA, scale: originalScale, orientation: originalOrientation)
        }
        
        return nil
    }
    
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
    
    static func generateImageFrom(charA: Character, charB: Character,
                                  andColor: UIColor) -> UIImage? {
        let sem = DispatchSemaphore(value: 0)
        var get: UIImage?
        DispatchQueue.main.async {
            let view = GradientView(frame: CGRect(x: -188, y: -188, width: 128, height: 128))
            let label = UILabel()
            let mainColor = UIColor.randomAsPudding
            let start = mainColor.lighterColor(removeSaturation: 0.05, resultAlpha: -1)
            let end = mainColor.lighterColor(removeSaturation: -0.1, resultAlpha: -1)
            view.setGradientColor(from: start, to: end)
            view.clipsToBounds = true
            let text = (String(charA) + String(charB)).uppercased()
            label.text = text.uppercased()
            label.textColor = UIColor(hex: 0xffffff)
            label.font = .systemFont(ofSize: 66)
            label.font = label.font.monospacedDigitFont
            label.textAlignment = .center
            view.addSubview(label)
            label.snp.makeConstraints { (x) in
                x.edges.equalTo(view)
            }
                     
            let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
            let capturedImage = renderer.image { (ctx) in
                view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
            }
            get = capturedImage
            sem.signal()
            
        }
        let _ = sem.wait(timeout: .now() + 1)
        return get
    }
    
    
    func isLight() -> Bool? {
        return areaAverage().isLight()
    }
    
}
