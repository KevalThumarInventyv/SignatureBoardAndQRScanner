//
//  UIPanGestureReconizerViewController.swift
//  QRCodeTouchPadTask
//
//  Created by Kailash Rajput on 20/03/25.
//

import UIKit
import Photos

enum ImageFormatUIPan {
    case png
    case jpeg
}

class SignatureViewUIPan: UIView {
    
    private var path = UIBezierPath()
    private var strokeColor: UIColor = .black
    private var strokeWidth: CGFloat = 2.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpStroke()
    }
    
    private func setUpStroke() {
        strokeColor.setStroke()
        path.lineWidth = strokeWidth
        path.stroke()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpStroke()
    }
    
    
    func handlePan(_ gesture: UIPanGestureRecognizer) {
        let currentPoint = gesture.location(in: self)
        
        switch gesture.state {
        case .began:
            path.move(to: currentPoint)
        case .changed:
            path.addLine(to: currentPoint)
            setNeedsDisplay()
        case .ended:
            break
        default:
            break
        }
    }
    
    override func draw(_ rect: CGRect) {
        strokeColor.setStroke()
        path.lineWidth = strokeWidth
        path.stroke()
    }
    
    func clear() {
        path.removeAllPoints()
        setNeedsDisplay()
    }
    
    func getSignature() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        return renderer.image { _ in
            layer.render(in: UIGraphicsGetCurrentContext()!)
        }
    }
    
//    deprecated for IOS 15 and
    
    //    func getSignatureImage() -> UIImage? {
    //        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
    //        defer { UIGraphicsEndImageContext() }
    //        layer.render(in: UIGraphicsGetCurrentContext()!)
    //        return UIGraphicsGetImageFromCurrentImageContext()
    //    }
}

class UIPanGestureReconizerViewController: UIViewController {
    
    @IBOutlet weak var viewSignature: SignatureViewUIPan!
    @IBOutlet weak var btnSave: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewSignature.layer.borderWidth = 2
        viewSignature.layer.borderColor = UIColor.gray.cgColor
        
    }
    
    @IBAction func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        viewSignature.handlePan(sender)
    }
    
    @IBAction func btnSaveClick(_ sender: UIButton) {
        guard let signatureImage = viewSignature.getSignature() else {
            showAlert(message: "No signature to save")
            return
        }
        
        let alert = UIAlertController(title: "Save As", message: "Choose image format", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "PNG (High Quality)", style: .default) { _ in
            self.handleImageSave(image: signatureImage, format: .png)
        })
        
        alert.addAction(UIAlertAction(title: "JPEG (High Quality)", style: .default) { _ in
            self.handleImageSave(image: signatureImage, format: .jpeg)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = btnSave
            popover.sourceRect = btnSave.bounds
        }
        
        present(alert, animated: true)
    }
    
    @IBAction func btnClearClick(_ sender: UIButton) {
        viewSignature.clear()
    }
    
    private func handleImageSave(image: UIImage, format: ImageFormatUIPan) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized:
            saveImageToLibrary(image: image, format: format)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] newStatus in
                if newStatus == .authorized {
                    self?.saveImageToLibrary(image: image, format: format)
                } else {
                    self?.showPermissionAlert()
                }
            }
        default:
            showPermissionAlert()
        }
        
    }

    private func saveImageToLibrary(image: UIImage, format: ImageFormatUIPan) {
        
        let directory = FileManager.default.temporaryDirectory
        let filename = "Signature_\(Date().timeIntervalSince1970).\(format == .png ? "png" : "jpg")"
        let fileURL = directory.appendingPathComponent(filename)
        
        var imageData: Data?
        switch format {
        case .png:
            imageData = image.pngData()
        case .jpeg:
            imageData = image.jpegData(compressionQuality: 1.0)
        }
        
        guard let data = imageData else {
            showAlert(title: "Error", message: "Failed to create image data")
            return
        }
        
        // Save image file locally
        do {
            try data.write(to: fileURL)
        } catch {
            showAlert(title: "Error", message: "Failed to save file: \(error.localizedDescription)")
            return
        }
        
        // Request permission and save to Photo Library
        PHPhotoLibrary.shared().performChanges {
            let creationRequest = PHAssetCreationRequest.forAsset()
            let resourceOptions = PHAssetResourceCreationOptions()
            creationRequest.addResource(with: .photo, fileURL: fileURL, options: resourceOptions)
        } completionHandler: { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.showAlert(title: "Success", message: "Saved as \(filename)")
                } else {
                    self?.showAlert(title: "Error", message: error?.localizedDescription ?? "Unknown error")
                }
            }
        }
    }

    
//
//    private func saveImageToLibrary(image: UIImage, format: ImageFormatUIPan) {
//        var data: Data?
//        
//        switch format {
//        case .png:
//            data = image.pngData()
//        case .jpeg:
//            data = image.jpegData(compressionQuality: 1.0)
//        }
//        
//        guard let imageData = data else {
//            showAlert(title: "Error", message: "Failed to create image data")
//            return
//        }
//        
//        PHPhotoLibrary.shared().performChanges {
//            let creationRequest = PHAssetCreationRequest.forAsset()
//            creationRequest.addResource(with: .photo, data: imageData, options: nil)
//        } completionHandler: { [weak self] success, error in
//            DispatchQueue.main.async {
//                if success {
//                    self?.showAlert(title: "Success", message: "Saved as \(format == .png ? "PNG" : "JPEG")")
//                } else {
//                    self?.showAlert(title: "Error", message: error?.localizedDescription ?? "Unknown error")
//                }
//            }
//        }
//    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "Photo Access Required",
            message: "Please enable photo library access in Settings to save signatures",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        present(alert, animated: true)
    }
    
    private func showAlert(title: String? = nil, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
