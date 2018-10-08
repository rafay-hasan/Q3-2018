//
//  ViewController.swift
//  Tapstar Demo
//
//  Created by Rafay Hasan on 2/10/18.
//  Copyright © 2018 Rafay Hasan. All rights reserved.
//

import UIKit
import Vision
import CoreImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    var selectedImage: UIImage! {
        didSet {
            self.imageView?.image = selectedImage
            if self.ifThereIsAnyFaceInTheImage() {
                self.colorFacelandmark()
            }
            else {
                let alert = UIAlertController(title: "Error", message: "Please select an image with an human face", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        selectedImage = UIImage(named: "rafay")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func cameraAction(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            selectedImage = image
        }
    }
    
    func ifThereIsAnyFaceInTheImage() -> Bool {
        let faceImage = CIImage(image: self.imageView.image!)
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let faces = faceDetector?.features(in: faceImage!) as! [CIFaceFeature]
        if (faces.first) != nil {
            return true
        }
        else {
            return false
        }
    }
    
    func colorFacelandmark()  {
        let detectFaceRequest = VNDetectFaceLandmarksRequest { (request, error) in
            if error == nil {
                if let results = request.results as? [VNFaceObservation] {
                    for faceObservation in results {
                        guard let landmarks = faceObservation.landmarks else {
                            continue
                        }
                        let boundingRect = faceObservation.boundingBox
                        var landmarkRegions: [VNFaceLandmarkRegion2D] = []
                    
                        if let leftEye = landmarks.leftEye {
                            landmarkRegions.append(leftEye)
                        }
                        if let rightEye = landmarks.rightEye {
                            landmarkRegions.append(rightEye)
                        }
                        if let innerLips = landmarks.outerLips {
                            landmarkRegions.append(innerLips)
                        }
                        if let outerLips = landmarks.outerLips {
                            landmarkRegions.append(outerLips)
                        }
                        
                        self.drawOnImage(sourceImage: self.selectedImage, boundingRect: boundingRect, faceLandmarkRegions: landmarkRegions)
                    }
                }
            } else {
                print(error!.localizedDescription)
            }
        }
        
        let vnImage = VNImageRequestHandler(cgImage: (self.imageView.image?.cgImage!)!, options: [:])
        try? vnImage.perform([detectFaceRequest])
    }
    
    func drawOnImage(sourceImage: UIImage,
                     boundingRect: CGRect,
                     faceLandmarkRegions: [VNFaceLandmarkRegion2D]) {
        
        UIGraphicsBeginImageContextWithOptions(sourceImage.size, false, 1)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: 0, y: sourceImage.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(CGBlendMode.colorBurn)
    
        //draw image
        let rect = CGRect(x: 0, y:0, width: sourceImage.size.width, height: sourceImage.size.height)
        context.draw(sourceImage.cgImage!, in: rect)
        
        let w = boundingRect.size.width * sourceImage.size.width
        let h = boundingRect.size.height * sourceImage.size.height
        let x = boundingRect.origin.x * sourceImage.size.width
        let y = boundingRect.origin.y * sourceImage.size.height
        
        // draw overlay
        context.setFillColor(UIColor.red.cgColor)
        context.setLineWidth(12.0)
        for faceLandmarkRegion in faceLandmarkRegions {
            for i in 0..<faceLandmarkRegion.pointCount {
                let point = faceLandmarkRegion.normalizedPoints[i]
                if i == 0 {
                    context.move(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                } else {
                    context.addLine(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                }
            }
            context.drawPath(using: .fill)
            context.saveGState()
        }
        
        let coloredImg : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        DispatchQueue.main.async {
            self.imageView.image = coloredImg
        }
 
    }
    
}


