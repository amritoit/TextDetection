//  Created by Amritendu Mondal on 14/10/17.
//  Copyright © 2017 Amritendu Mondal. All rights reserved.

import UIKit
import TesseractOCR


class ImageScannerViewController: UIViewController, UINavigationControllerDelegate, G8TesseractDelegate  {
    @IBOutlet weak var scannedImageView: UIImageView!
    @IBOutlet weak var scannedTextView: UITextView!
    @IBOutlet weak var progressBar: UITextView!
    
    var tesseract: G8Tesseract!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let tesseract = G8Tesseract(language: "eng") {
            tesseract.delegate = self
            self.tesseract = tesseract
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
    
    func readTextFromImage(image: UIImage) -> String {
        if tesseract != nil {
            tesseract.delegate = self
            tesseract.image = image.g8_blackAndWhite()
            tesseract.recognize()
            self.progressBar.text = ""
            return tesseract.recognizedText
        } else {
            return "Internal server error!!"
        }
    }
    
    func progressImageRecognition(for tesseract: G8Tesseract!){
        self.progressBar.text = tesseract.progress > 90 ? "" : "Scanning \(tesseract.progress) %"
    }
}

extension ImageScannerViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true)
        //classifier.text = "Analyzing Image..."
        guard let image = info["UIImagePickerControllerOriginalImage"] as? UIImage else {
            return
        }
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 299, height: 299), true, 2.0)
        image.draw(in: CGRect(x: 0, y: 0, width: 299, height: 299))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) //3
        
        context?.translateBy(x: 0, y: newImage.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        scannedImageView.image = newImage
        DispatchQueue.main.async() {
            self.scannedTextView.text = self.readTextFromImage(image: newImage)
            //self.progressBar.text = "asfsafafdsa"
        }
    }
}
