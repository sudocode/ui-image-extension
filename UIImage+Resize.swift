//
//  UIImage+Resize.swift
//
//  Originally created by Trevor Harmon on 8/5/09
//  Translated to Swift by Daniel Park on 2/5/15.
//
//  Free for personal or commercial use, with or without modification
//  No warranty is expressed or implied

import Foundation
import UIKit

extension UIImage {
    
    // Returns a copy of this image that is cropped to the given bounds.
    // The bounds will be adjusted using CGRectIntegral.
    // This method ignores the image's imageOrientation setting.
    func croppedImage(_ bounds: CGRect) -> UIImage {
        let imageRef:CGImage = self.cgImage!.cropping(to: bounds)!
        return UIImage(cgImage: imageRef)
    }
    
    func thumbnailImage( _ thumbnailSize: Int, transparentBorder borderSize:Int,
                         cornerRadius:Int, interpolationQuality quality:CGInterpolationQuality) -> UIImage {
        let resizedImage:UIImage = self.resizedImageWithContentMode(
            .scaleAspectFill,
            bounds: CGSize(width: CGFloat(thumbnailSize), height: CGFloat(thumbnailSize)),
            interpolationQuality: quality
        )
        let cropRect:CGRect = CGRect(
            x: round((resizedImage.size.width - CGFloat(thumbnailSize))/2),
            y: round((resizedImage.size.height - CGFloat(thumbnailSize))/2),
            width: CGFloat(thumbnailSize),
            height: CGFloat(thumbnailSize)
        )
        
        let croppedImage:UIImage = resizedImage.croppedImage(cropRect)
        return croppedImage
    }
    
    // Returns a rescaled copy of the image, taking into account its orientation
    // The image will be scaled disproportionately if necessary to fit the bounds specified by the parameter
    func resizedImage(_ newSize:CGSize, interpolationQuality quality:CGInterpolationQuality) -> UIImage {
        var drawTransposed:Bool
        
        switch(self.imageOrientation) {
        case .left:
            fallthrough
        case .leftMirrored:
            fallthrough
        case .right:
            fallthrough
        case .rightMirrored:
            drawTransposed = true
            break
        default:
            drawTransposed = false
            break
        }
        
        return self.resizedImage(
            newSize,
            transform: self.transformForOrientation(newSize),
            drawTransposed: drawTransposed,
            interpolationQuality: quality
        )
    }
    
    func resizedImageWithContentMode( _ contentMode:UIViewContentMode, bounds:CGSize,
                                      interpolationQuality quality:CGInterpolationQuality) -> UIImage {
        let horizontalRatio:CGFloat = bounds.width / self.size.width
        let verticalRatio:CGFloat = bounds.height / self.size.height
        var ratio:CGFloat = 1
        
        switch(contentMode) {
        case .scaleAspectFill:
            ratio = max(horizontalRatio, verticalRatio)
            break
        case .scaleAspectFit:
            ratio = min(horizontalRatio, verticalRatio)
            break
        default:
            print("Unsupported content mode \(contentMode)")
        }
        
        let newSize:CGSize = CGSize(width: self.size.width * ratio, height: self.size.height * ratio)
        return self.resizedImage(newSize, interpolationQuality: quality)
    }
    
    func resizedImage( _ newSize:CGSize, transform:CGAffineTransform,
                       drawTransposed transpose:Bool, interpolationQuality quality:CGInterpolationQuality) -> UIImage {
        let newRect:CGRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral
        let transposedRect:CGRect = CGRect(x: 0, y: 0, width: newRect.size.height, height: newRect.size.width)
        let imageRef:CGImage = self.cgImage!
        
        // build a context that's the same dimensions as the new size
        let bitmap:CGContext = CGContext(
            data: nil,
            width: Int(UInt(newRect.size.width)),
            height: Int(UInt(newRect.size.height)),
            bitsPerComponent: imageRef.bitsPerComponent,
            bytesPerRow: 0,
            space: imageRef.colorSpace!,
            bitmapInfo: imageRef.bitmapInfo.rawValue
            )!
        
        // rotate and/or flip the image if required by its orientation
        bitmap.concatenate(transform)
        
        // set the quality level to use when rescaling
        bitmap.interpolationQuality = quality
        
        // draw into the context; this scales the image
        bitmap.draw(imageRef, in: transpose ? transposedRect : newRect)
        
        // get the resized image from the context and a UIImage
        let newImageRef:CGImage = bitmap.makeImage()!
        let newImage:UIImage = UIImage(cgImage: newImageRef)
        
        return newImage
    }
    
    func transformForOrientation(_ newSize:CGSize) -> CGAffineTransform {
        var transform:CGAffineTransform = CGAffineTransform.identity
        switch (self.imageOrientation) {
        case .down:          // EXIF = 3
            fallthrough
        case .downMirrored:  // EXIF = 4
            transform = transform.translatedBy(x: newSize.width, y: newSize.height)
            transform = transform.rotated(by: CGFloat(M_PI))
            break
        case .left:          // EXIF = 6
            fallthrough
        case .leftMirrored:  // EXIF = 5
            transform = transform.translatedBy(x: newSize.width, y: 0)
            transform = transform.rotated(by: CGFloat(M_PI_2))
            break
        case .right:         // EXIF = 8
            fallthrough
        case .rightMirrored: // EXIF = 7
            transform = transform.translatedBy(x: 0, y: newSize.height)
            transform = transform.rotated(by: -CGFloat(M_PI_2))
            break
        default:
            break
        }
        
        switch(self.imageOrientation) {
        case .upMirrored:    // EXIF = 2
            fallthrough
        case .downMirrored:  // EXIF = 4
            transform = transform.translatedBy(x: newSize.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            break
        case .leftMirrored:  // EXIF = 5
            fallthrough
        case .rightMirrored: // EXIF = 7
            transform = transform.translatedBy(x: newSize.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            break
        default:
            break
        }
        
        return transform
    }
    
}
