//  Created by Amritendu Mondal on 15/10/17.
//  Copyright © 2017 Amritendu Mondal. All rights reserved.
//

import Foundation
import CoreImage
import UIKit
import GPUImage

struct ImageProcessing {
    private let detector = CIDetector(ofType: CIDetectorTypeText,
                                      context: nil,
                                      options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])!
    
//    func prepareForOcr(_ lang: String) -> CIImage {
//        return preprocessing_en()
//    }
    
//    func preprocessing_en() -> CIImage{
//        let options = [CIDetectorReturnSubFeatures: true]
//        guard let features = detector.features(in: ciImage, options: options) as? [CITextFeature] else {fatalError()}
//
//        let cropImage = ciImage
//        for feature in features {
//            //var rect = feature.bounds
//            //rect.size.height = max(feature.bounds.height, feature.bounds.width)
//            //rect.size.width = max(feature.bounds.height, feature.bounds.width)
//            //rect = rect.insetBy(dx: -30, dy: -30)
//            //cropImage = ciImage.cropped(to: rect)
//            print("bounds:\(feature.bounds), topLeft:\(feature.topLeft), bottomRight:\(feature.bottomRight)")
//            //feature.drawRectOnView(imageView, color: UIColor.green.withAlphaComponent(0.8), borderWidth: 2.0, scale: scale)
//
//            // draw subFeature's rects
//            //guard let subFeatures = feature.subFeatures as? [CITextFeature] else {fatalError()}
//            //for subFeature in subFeatures {
//            //    subFeature.drawRectOnView(imageView, color: UIColor.yellow.withAlphaComponent(0.8), borderWidth: 1.0, scale: scale)
//            //}
//        }
//        return cropImage
//    }
    
    func applyFilters(_ uiImage: UIImage) -> UIImage {
        let processedImage = uiImage
        let image = GPUImagePicture(image: processedImage)
        let image2 = GPUImagePicture(image: processedImage)
        
        //Img 1
        
        let grayFilter = GPUImageGrayscaleFilter()
        image?.addTarget(grayFilter)
        
        let invertFilter = GPUImageColorInvertFilter()
        grayFilter.addTarget(invertFilter)
        
        let blurFilter = GPUImageGaussianBlurFilter()
        blurFilter.blurRadiusInPixels = 10
        invertFilter.addTarget(blurFilter)
        
        let opacityFilter = GPUImageOpacityFilter()
        opacityFilter.opacity = 0.93
        blurFilter.addTarget(opacityFilter)
        
        opacityFilter.useNextFrameForImageCapture()
        
        //Img 2
        
        let grayFilter2 = GPUImageGrayscaleFilter()
        image2?.addTarget(grayFilter2)
        
        grayFilter2.useNextFrameForImageCapture()
        
        //Blend
        
        let dodgeBlendFilter = GPUImageColorDodgeBlendFilter()
        
        grayFilter2.addTarget(dodgeBlendFilter)
        image2?.processImage()
        
        opacityFilter.addTarget(dodgeBlendFilter)
        image?.processImage()
        
        dodgeBlendFilter.useNextFrameForImageCapture()
        
        //Img 3
        
        var dodgeBlendImage:UIImage? = dodgeBlendFilter.imageFromCurrentFramebuffer(with: UIImageOrientation.up)
        
        while dodgeBlendImage == nil {
            //Sometimes it gets stuck here
            dodgeBlendImage = dodgeBlendFilter.imageFromCurrentFramebuffer(with: UIImageOrientation.up)
        }
        
        if let dodgeImage = dodgeBlendImage {
            
            let image3 = GPUImagePicture(image: dodgeImage)
            
            let levelFilter = GPUImageLevelsFilter()
            levelFilter.setMin(90/255, gamma: 0.8, max: 215/255, minOut: 0, maxOut: 1)
            image3?.addTarget(levelFilter)
            
            let medianFilter = GPUImageMedianFilter()
            levelFilter.addTarget(medianFilter)
            
            let erosionFilter = GPUImageErosionFilter()
            medianFilter.addTarget(erosionFilter)
            
            let thresholdFilter = GPUImageLuminanceThresholdFilter()
            thresholdFilter.threshold = 220/255
            erosionFilter.addTarget(thresholdFilter)
            
            thresholdFilter.useNextFrameForImageCapture()
            
            image3?.processImage()
            let processedImage = thresholdFilter.imageFromCurrentFramebuffer(with: UIImageOrientation.up)
            
            return processedImage!
        } else {
            NSLog("WARNING: DodgeImage image is to small","")
            return processedImage
        }
    }
}
