//
//  ViewController.swift
//  Vision_iOS
//
//  Created by Sohel Dhengre on 04/02/18.
//  Copyright © 2018 Sohel Dhengre. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

enum flashState {
    case off
    case on
}

class CameraVC: UIViewController {

    var captureSession: AVCaptureSession!
    var cameraOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var photoData: Data?
    var speechSynthesizer = AVSpeechSynthesizer()
    var flashControlState: flashState = .off
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var identificationLbl: UILabel!
    @IBOutlet weak var captureImageView: RoundedShadowImageView!
    @IBOutlet weak var flashBtn: RoundedShadowButton!
    @IBOutlet weak var confidenceLbl: UILabel!
    @IBOutlet weak var roundedLblView: RoundedShadowView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        speechSynthesizer.delegate = self
        spinner.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer.frame = cameraView.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.didTapCameraView))
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        do {
            let input = try AVCaptureDeviceInput(device: backCamera!)
            if captureSession.canAddInput(input) == true {
                captureSession.addInput(input)
            }
            
            cameraOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(cameraOutput) == true{
                captureSession.addOutput(cameraOutput)
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
            previewLayer.connection?.videoOrientation = .portrait
            
            cameraView.layer.addSublayer(previewLayer)
            cameraView.addGestureRecognizer(tap)
            captureSession.startRunning()
        } catch {debugPrint(error)}
    }

    @objc func didTapCameraView(){
        self.cameraView.isUserInteractionEnabled = false
        spinner.isHidden = false
        spinner.startAnimating()
        let settings = AVCapturePhotoSettings() // object of AVCaptureSettings
        
        settings.previewPhotoFormat = settings.embeddedThumbnailPhotoFormat
        
        if flashControlState == .off {
            settings.flashMode = .off
        } else{
            settings.flashMode = .on
        }
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func synthesizedSpeech(forString string: String){
        let speechUtterence = AVSpeechUtterance(string: string)
        speechSynthesizer.speak(speechUtterence)
    }
    
    func resultsMethod(request: VNRequest, error: Error?){
        guard let result = request.results as? [VNClassificationObservation] else {return}
        for classifications in result{
            if classifications.confidence < 0.5 {
                let unknownObjectMessage = "I'm not sure what this is. Please try again!"
                self.identificationLbl.text = unknownObjectMessage
                synthesizedSpeech(forString: unknownObjectMessage)
                self.confidenceLbl.text = ""
                break
            } else {
                let identification = classifications.identifier
                let confidence = classifications.confidence*100
                self.identificationLbl.text = identification
                self.confidenceLbl.text = "CONFIDENCE: \(Int(classifications.confidence*100))%"
                let completeSentence = "This looks like \(identification) and I'm \(confidence) percent sure."
                synthesizedSpeech(forString: completeSentence)
                break
            }
        }
    }
    
    
  
    @IBAction func flashBtnPressed(_ sender: Any) {
        if flashControlState == .off {
            flashBtn.setTitle("FLASH OFF", for: .normal)
            flashControlState = .on
        } else {
            flashBtn.setTitle("FLASH ON", for: .normal)
            flashControlState = .off
        }
    }
    
}

extension CameraVC: AVCapturePhotoCaptureDelegate{
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            debugPrint(error)
        } else {
            photoData = photo.fileDataRepresentation()
            do{
                let model = try VNCoreMLModel(for: Inceptionv3().model)
                let request = VNCoreMLRequest(model: model, completionHandler: resultsMethod)
                let handler = VNImageRequestHandler(data: photoData!)
                try handler.perform([request])
            } catch {debugPrint(error)}
            
            
            
            let image = UIImage(data: photoData!)
            self.captureImageView.image = image
        }
    }
}

extension CameraVC: AVSpeechSynthesizerDelegate {

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        cameraView.isUserInteractionEnabled = true
        spinner.isHidden = true
        spinner.stopAnimating()
    }
}








