//
//  ViewController.swift
//  CustomCamera
//
//  Created by Daria on 01.08.17.
//  Copyright © 2017 Daria. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let captureSession  = AVCaptureSession() //initialize here using AV
    var previewLayer: CALayer! //display data stream
    
    var captureDevise: AVCaptureDevice! //store any devise that we a going to find(back camera)
    
    var takePhoto = false

    override func viewDidLoad() {
        super.viewDidLoad()
       
    
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareCamera()
    }

    func prepareCamera(){
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        
        if let availableDevises = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: .back).devices {
            captureDevise = availableDevises.first //we need only first object
            beginSession() //only if we have availiable devisies we can begin
        }
        
    }
    
    func beginSession() {
        do {
            let captureDeviseInput =  try AVCaptureDeviceInput(device: captureDevise)
            
            captureSession.addInput(captureDeviseInput)
        } catch {
            print(error.localizedDescription)
        }
        
        if let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession){
            self.previewLayer = previewLayer
            self.view.layer.addSublayer(self.previewLayer)
            self.previewLayer.frame = self.view.layer.frame
            //now we can start session 
            captureSession.startRunning()
            
            let dataOutput = AVCaptureVideoDataOutput() //what we have on the view
            dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString):NSNumber(value: kCVPixelFormatType_32BGRA)]
            
            dataOutput.alwaysDiscardsLateVideoFrames = true
            
            if captureSession.canAddOutput(dataOutput){
                captureSession.addOutput(dataOutput)
            }
            captureSession.commitConfiguration()
            
            let queue = DispatchQueue(label: "captureQueue")
            dataOutput.setSampleBufferDelegate(self, queue: queue)
            
    }
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        
        takePhoto = true
    }
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if takePhoto  {
            takePhoto = false
            //get photo from sample buffer
            if let image = self.getImageFromSampleBuffer(buffer: sampleBuffer){
                
                let photoVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PhotoVC") as! PhotoViewController
                
                photoVC.takenPhoto = image
                
                DispatchQueue.main.async { //see this in the second VC
                    
                    self.present(photoVC, animated: true, completion: {
                        self.stopeSession()
                    })
                }
            }
        }
    

    }
    
   
        
        
    func getImageFromSampleBuffer(buffer: CMSampleBuffer) -> UIImage? {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer){
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            
            if let image = context.createCGImage(ciImage, from: imageRect){
                return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .right)
            }
        }
        
        return nil
        
    }

    func stopeSession(){
        self.captureSession.stopRunning()
        
        if let inputs = captureSession.inputs as? [AVCaptureDeviceInput]{
            for input in inputs {
                self.captureSession.removeInput(input)
            }
        }
    }
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    

}

