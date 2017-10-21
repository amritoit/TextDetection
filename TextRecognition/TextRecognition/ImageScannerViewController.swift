//  Created by Amritendu Mondal on 14/10/17.
//  Copyright © 2017 Amritendu Mondal. All rights reserved.

import UIKit
import TesseractOCR
import GPUImage
import AKImageCropperView



class ImageScannerViewController: UIViewController, UINavigationControllerDelegate, G8TesseractDelegate  {
    @IBOutlet weak var scannedImageView: UIImageView!
    @IBOutlet weak var scannedTextView: UITextView!
    @IBOutlet weak var progressBar: UITextView!
    
    var tesseract: G8Tesseract!
    var imageProcessing: ImageProcessing!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let tesseract = G8Tesseract(language: "eng") {
            tesseract.delegate = self
            //tesseract.engineMode = .tesseractCubeCombined
            tesseract.setVariableValue("true", forKey: "tessedit_write_images")
            tesseract.pageSegmentationMode = .auto
            tesseract.maximumRecognitionTime = 60.0
            self.tesseract = tesseract
        }
    }
    
    @IBAction func camera(_ sender: Any) {
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            return
        }
        
        let cameraPicker = UIImagePickerController()
        cameraPicker.delegate = self
        cameraPicker.sourceType = .camera
        cameraPicker.allowsEditing = false
        present(cameraPicker, animated: true)
    }
    
    @IBAction func openLibrary(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    func blurFilter(_ image: UIImage) -> UIImage {
        let blurFilter = GPUImageGaussianBlurFilter()
        blurFilter.blurRadiusInPixels = 10
        return blurFilter.image(byFilteringImage: image)
    }
    
    func luminanceFilter(_ image: UIImage) -> UIImage {
        let luminanceFilter = GPUImageAdaptiveThresholdFilter()
        luminanceFilter.blurRadiusInPixels = 15
        return luminanceFilter.image(byFilteringImage: image)
    }
    
    
    func readTextFromImage(image: UIImage) -> String {
        if tesseract != nil {
            tesseract.delegate = self
            tesseract.image = image.g8_blackAndWhite()
            tesseract.recognize()
            return tesseract.recognizedText
        } else {
            return "Internal server error!!"
        }
    }
    
    // Tesseract delegate method inside of your class

    func progressImageRecognition(for tesseract: G8Tesseract!){
        self.progressBar.text = "Scanning \(tesseract.progress) %"
    }
    
    // Tesseract delegate method inside of your class
    func preprocessedImageForTesseract(for tesseract:  G8Tesseract, sourceImage: UIImage) -> UIImage {
        return luminanceFilter(sourceImage)
    }
    
//    func preProcessImageMine(_ image: UIImage) -> UIImage{
//        print("started converting to ciimage")
//        let s = Int(Date().timeIntervalSince1970 * 1000)
//        var ciImage = CIImage(image: image.g8_blackAndWhite())!
//        var e = Int(Date().timeIntervalSince1970 * 1000)
//        print("done converting to ciimage \(e-s) ms")
//
//        imageProcessing = ImageProcessing(ciImage)
//        ciImage = (imageProcessing?.preprocessing_en())!
//        let processedImage = UIImage(ciImage: ciImage)
//        e = Int(Date().timeIntervalSince1970 * 1000)
//        print("done preporessing image \(e-s) ms")
//        return processedImage
//    }
    
    func displayFilteredImage(_ image: UIImage) -> UIImage{
        let filter = CIFilter(name: "CISepiaTone",
                              withInputParameters: [kCIInputIntensityKey: 0.5])!
        let inputImage = CIImage(image: image)!
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        return UIImage(ciImage: filter.outputImage!)
    }
//    func addActivityIndicator() {
//        activityIndicator = UIActivityIndicatorView(frame: view.bounds)
//        activityIndicator.activityIndicatorViewStyle = .WhiteLarge
//        activityIndicator.backgroundColor = UIColor(white: 0, alpha: 0.25)
//        activityIndicator.startAnimating()
//        view.addSubview(activityIndicator)
//    }
//
//    func removeActivityIndicator() {
//        activityIndicator.removeFromSuperview()
//        activityIndicator = nil
//    }
    
   func scaleImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        
        var scaledSize = CGSize(width: maxDimension, height: maxDimension)
        var scaleFactor: CGFloat
        
        if image.size.width > image.size.height {
            scaleFactor = image.size.height / image.size.width
            scaledSize.width = maxDimension
            scaledSize.height = scaledSize.width * scaleFactor
        } else {
            scaleFactor = image.size.width / image.size.height
            scaledSize.height = maxDimension
            scaledSize.width = scaledSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        image.draw(in: CGRect(x: 0, y: 0, width: scaledSize.width, height: scaledSize.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
    
    func convertImageForDevice(_ image: UIImage) -> UIImage {
        let s = Int(Date().timeIntervalSince1970 * 1000)
        //resizing image
        //let scaledSize = scaleImage(image, maxDimension: 1024)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 299, height: 299), true, 2.0)
        image.draw(in: CGRect(x: 0, y: 0, width: 299, height: 299))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        //loading pixel into memory
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return image
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        //changing image to device specific color
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) //3
        
        context?.translateBy(x: 0, y: newImage.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        //coverting graphic context to current context and render it.
        UIGraphicsPushContext(context!)
        newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let e = Int(Date().timeIntervalSince1970 * 1000)
        print("done with color modification \(e-s) ms")
        return newImage
    }
    
    func sampleImage() -> UIImage {
        return UIImage(named: "13")!
    }
}

extension ImageScannerViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        print("calling picker controller")
        //dismiss image picker and take the image in a variable
        picker.dismiss(animated: true)
        guard let image = info["UIImagePickerControllerOriginalImage"] as? UIImage else {
            return
        }
        
        //correct color for running device.
        //let processedImage = preProcessImageMine(image)
        var newImage = image
        let process = ImageProcessing()
        newImage = process.applyFilters(image)
        //let newImage = scaleImage(image,  maxDimension: 299)
        //scannedImageView.image = luminanceFilter(image)
        scannedImageView.image = newImage
        //tesseract.rect = CGRectMake(20, 20, 100, 100);
        DispatchQueue.main.async() {
            self.scannedTextView.text = self.readTextFromImage(image: newImage)
        }
    }
}
