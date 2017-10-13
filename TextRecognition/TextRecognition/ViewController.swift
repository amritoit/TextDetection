//
//  ViewController.swift
//  TextRecognition
//
//  Created by Amritendu Mondal on 13/10/17.
//  Copyright © 2017 Amritendu Mondal. All rights reserved.
//

import UIKit
import TesseractOCR

class ViewController: UIViewController,G8TesseractDelegate {

    @IBOutlet weak var textView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()      
        if let tesseract = G8Tesseract(language: "eng") {
            tesseract.delegate = self
            tesseract.image = UIImage(named: "demoImage1")?.g8_blackAndWhite()
            tesseract.recognize()
            textView.text = tesseract.recognizedText
            tesseract.image = UIImage(named: "demoImage2")?.g8_blackAndWhite()
            tesseract.recognize()
            textView.text = textView.text + tesseract.recognizedText
            tesseract.image = UIImage(named: "demoImage3")?.g8_blackAndWhite()
            tesseract.recognize()
            textView.text = textView.text + tesseract.recognizedText
        }
    }

    func progressImageRecognition(for tesseract: G8Tesseract!) {
        print("Recognition progress \(tesseract.progress) %")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}

