//
//  SignatureViewController.swift
//  QRCodeTouchPadTask
//
//  Created by Keval Thumar on 19/03/25.
//

import UIKit
import Photos

enum ImageFormat {
    case png
    case jpeg
}

class SignatureView: UIView {

    private var path = UIBezierPath()
    private var strokeColor: UIColor = .black
    private var strokeWidth: CGFloat = 2.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        self.backgroundColor = .white
        path.lineWidth = strokeWidth
        strokeColor.setStroke()
        path.stroke()
    }

//  override from UIResponder class
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)

        path.move(to: point)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let currentPoint = touch.location(in: self)

        path.addLine(to: currentPoint)
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        strokeColor.setStroke()
        path.stroke()
    }

    func clear() {
        path.removeAllPoints()
        setNeedsDisplay()
    }
    
    func getSignature() -> UIImage? {
        let insetBounds = bounds.insetBy(dx: 2, dy: 2)
        let renderer = UIGraphicsImageRenderer(size: insetBounds.size)

        return renderer.image { _ in
            guard let context = UIGraphicsGetCurrentContext() else { return }
            context.translateBy(x: -insetBounds.origin.x, y: -insetBounds.origin.y)
            layer.render(in: context)
        }
    }


    /// Deprecated for iOS 15 or later
//    func getSignature() -> UIImage? {
//        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
//        defer { UIGraphicsEndImageContext() }
//        layer.render(in: UIGraphicsGetCurrentContext()!)
//        return UIGraphicsGetImageFromCurrentImageContext()
//    }
}


class SignatureViewController: UIViewController {
    
    @IBOutlet weak var viewSignature: SignatureView!
    @IBOutlet weak var btnSave: UIButton!
    @IBOutlet weak var btnClear: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewSignature.layer.borderWidth = 2
        viewSignature.layer.borderColor = UIColor.gray.cgColor

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
    
    private func handleImageSave(image: UIImage, format: ImageFormat) {
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
    
    private func saveImageToLibrary(image: UIImage, format: ImageFormat) {
        var data: Data?
        
        switch format {
        case .png:
            data = image.pngData()
        case .jpeg:
            data = image.jpegData(compressionQuality: 1.0)
        }
        
        guard let imageData = data else {
            showAlert(title: "Error", message: "Failed to create image data")
            return
        }
        
        PHPhotoLibrary.shared().performChanges {
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: imageData, options: nil)
        } completionHandler: { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.showAlert(title: "Success", message: "Saved as \(format == .png ? "PNG" : "JPEG")")
                } else {
                    self?.showAlert(title: "Error", message: error?.localizedDescription ?? "Unknown error")
                }
            }
        }
    }
    
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
