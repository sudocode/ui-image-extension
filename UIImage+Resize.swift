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
    func croppedImage(bounds: CGRect) -> UIImage {
        let imageRef:CGImageRef = CGImageCreateWithImageInRect(self.CGImage, bounds)
        return UIImage(CGImage: imageRef)!
    }

    func thumbnailImage(
        thumbnailSize: Int,
        transparentBorder borderSize:Int,
        cornerRadius:Int,
        interpolationQuality quality:CGInterpolationQuality
    ) -> UIImage {
        var resizedImage:UIImage = self.resizedImageWithContentMode(
            .ScaleAspectFill,
            bounds: CGSizeMake(CGFloat(thumbnailSize), CGFloat(thumbnailSize)),
            interpolationQuality: quality
        )
        var cropRect:CGRect = CGRectMake(
            round((resizedImage.size.width - CGFloat(thumbnailSize))/2),
            round((resizedImage.size.height - CGFloat(thumbnailSize))/2),
            CGFloat(thumbnailSize),
            CGFloat(thumbnailSize)
        )

        var croppedImage:UIImage = resizedImage.croppedImage(cropRect)
        return croppedImage
    }

    // Returns a rescaled copy of the image, taking into account its orientation
    // The image will be scaled disproportionately if necessary to fit the bounds specified by the parameter
    func resizedImage(newSize:CGSize, interpolationQuality quality:CGInterpolationQuality) -> UIImage {
        var drawTransposed:Bool

        switch(self.imageOrientation) {
        case .Left:
            fallthrough
        case .LeftMirrored:
            fallthrough
        case .Right:
            fallthrough
        case .RightMirrored:
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

    func resizedImageWithContentMode(
        contentMode:UIViewContentMode,
        bounds:CGSize,
        interpolationQuality quality:CGInterpolationQuality
    ) -> UIImage {
        var horizontalRatio:CGFloat = bounds.width / self.size.width
        var verticalRatio:CGFloat = bounds.height / self.size.height
        var ratio:CGFloat = 1

        switch(contentMode) {
        case .ScaleAspectFill:
            ratio = max(horizontalRatio, verticalRatio)
            break
        case .ScaleAspectFit:
            ratio = min(horizontalRatio, verticalRatio)
            break
        default:
            println("Unsupported content mode \(contentMode)")
        }

        var newSize:CGSize = CGSizeMake(self.size.width * ratio, self.size.height * ratio)
        return self.resizedImage(newSize, interpolationQuality: quality)
    }

    func resizedImage(
        newSize:CGSize,
        transform:CGAffineTransform,
        drawTransposed transpose:Bool,
        interpolationQuality quality:CGInterpolationQuality
        ) -> UIImage {
            var newRect:CGRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height))
            var transposedRect:CGRect = CGRectMake(0, 0, newRect.size.height, newRect.size.width)
            var imageRef:CGImageRef = self.CGImage

            // build a context that's the same dimensions as the new size
            var bitmap:CGContextRef = CGBitmapContextCreate(
                nil,
                UInt(newRect.size.width),
                UInt(newRect.size.height),
                CGImageGetBitsPerComponent(imageRef),
                0,
                CGImageGetColorSpace(imageRef),
                CGImageGetBitmapInfo(imageRef)
            )

            // rotate and/or flip the image if required by its orientation
            CGContextConcatCTM(bitmap, transform)

            // set the quality level to use when rescaling
            CGContextSetInterpolationQuality(bitmap, quality)

            // draw into the context; this scales the image
            CGContextDrawImage(bitmap, transpose ? transposedRect : newRect, imageRef)

            // get the resized image from the context and a UIImage
            var newImageRef:CGImageRef = CGBitmapContextCreateImage(bitmap)
            var newImage:UIImage = UIImage(CGImage: newImageRef)!

            return newImage
    }

    func transformForOrientation(newSize:CGSize) -> CGAffineTransform {
        var transform:CGAffineTransform = CGAffineTransformIdentity
        switch (self.imageOrientation) {
        case .Down:          // EXIF = 3
            fallthrough
        case .DownMirrored:  // EXIF = 4
            transform = CGAffineTransformTranslate(transform, newSize.width, newSize.height)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI))
            break
        case .Left:          // EXIF = 6
            fallthrough
        case .LeftMirrored:  // EXIF = 5
            transform = CGAffineTransformTranslate(transform, newSize.width, 0)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI_2))
            break
        case .Right:         // EXIF = 8
            fallthrough
        case .RightMirrored: // EXIF = 7
            transform = CGAffineTransformTranslate(transform, 0, newSize.height)
            transform = CGAffineTransformRotate(transform, -CGFloat(M_PI_2))
            break
        default:
            break
        }

        switch(self.imageOrientation) {
        case .UpMirrored:    // EXIF = 2
            fallthrough
        case .DownMirrored:  // EXIF = 4
            transform = CGAffineTransformTranslate(transform, newSize.width, 0)
            transform = CGAffineTransformScale(transform, -1, 1)
            break
        case .LeftMirrored:  // EXIF = 5
            fallthrough
        case .RightMirrored: // EXIF = 7
            transform = CGAffineTransformTranslate(transform, newSize.height, 0)
            transform = CGAffineTransformScale(transform, -1, 1)
            break
        default:
            break
        }

        return transform
    }

}
