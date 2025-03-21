//
//  QRCodeViewController.swift
//  QRCodeTouchPadTask
//
//  Created by Kailash Rajput on 20/03/25.
//

import UIKit
import CoreImage
import AVFoundation

class QRCodeViewController: UIViewController {
    private let pickerImage = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupImagePicker()
    }
    
    private func checkCameraPermissions() {
        if AVCaptureDevice.authorizationStatus(for: .video) == .denied {
            showSettingsAlert()
        }
    }
    
    private func setupImagePicker() {
        pickerImage.delegate = self
        pickerImage.sourceType = .photoLibrary
        pickerImage.allowsEditing = false
    }
    
    @IBAction func btnGallery(_ sender: UIButton) {
        pickerImage.sourceType = .photoLibrary
        present(pickerImage, animated: true)
    }
    
    @IBAction func btnCamera(_ sender: UIButton) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(title: "Error", message: "Camera not available on this device")
            return
        }
        checkCameraPermissions()
        
        pickerImage.sourceType = .camera
        present(pickerImage, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showSettingsAlert() {
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Please enable camera access in Settings",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default))
        alert.addAction(UIAlertAction(title: "Settings", style: .cancel) { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(settingsUrl)
        })
        
        present(alert, animated: true)
    }
}

extension QRCodeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        picker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage else {
            showAlert(title: "Error", message: "Failed to get image")
            return
        }
        processQRCode(from: image)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    private func processQRCode(from image: UIImage) {
        guard let ciImage = CIImage(image: image) else {
            showAlert(title: "Error", message: "Failed to process image")
            return
        }
        print(ciImage.description)
        print(ciImage.debugDescription)
        print(ciImage.depthData ?? 0)
        
        let context = CIContext()
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        
        guard let detector = CIDetector(
            ofType: CIDetectorTypeQRCode,
            context: context,
            options: options
        ) else {
            showAlert(title: "Error", message: "QR Code detection failed")
            return
        }
        
        let features = detector.features(in: ciImage)   
        
        guard !features.isEmpty else {
            showAlert(title: "No QR Code", message: "No QR code detected in the image")
            return
        }
        
        var results = [String]()
        for case let feature as CIQRCodeFeature in features {
            if let message = feature.messageString {
                results.append(message)
            }
        }
        
        if !results.isEmpty {
            showResultsAlert(messages: results)
        }
    }
    
    private func showResultsAlert(messages: [String]) {
        let message = messages.joined(separator: "\n\n")
        let alert = UIAlertController(
            title: "QR Code Detected",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
          
        print("Detected QR Code Contents:")
        messages.forEach { print("- \($0)") }
    }
}
