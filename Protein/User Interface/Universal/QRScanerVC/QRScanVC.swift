//
//  QRScanVC.swift
//  Protein
//
//  Created by Lakr Aream on 2020/7/21.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import AVFoundation
import UIKit

class QRScanViewController: UIViewControllerWithCustomizedNavBar, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()

        defer { setupNavigationBar() }
        
        view.backgroundColor = UIColor(named: "G-ViewController-Background")
        let size = CGSize(width: 600, height: 600)
        preferredContentSize = size
        hideKeyboardWhenTappedAround()
        view.insetsLayoutMarginsFromSafeArea = false
        isModalInPresentation = true
        
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        switch  UIDevice.current.orientation {
        case .landscapeLeft:
            previewLayer.connection?.videoOrientation = .landscapeRight
        case .landscapeRight:
            previewLayer.connection?.videoOrientation = .landscapeLeft
        case .faceUp, .portrait:
            previewLayer.connection?.videoOrientation = .portrait
        case .faceDown, .portraitUpsideDown:
            previewLayer.connection?.videoOrientation = .portraitUpsideDown
        default:
            break
        }
        
        captureSession.startRunning()
        
    }

    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }

        dismiss(animated: true)
    }

    func found(code: String) {
        Tools.rprint("[QRScan] Found code: " + code)
        let target = self.parent ?? view.window?.rootViewController ?? UIViewController()
        self.dismiss(animated: true) {
            let pop = RepoAddViewController()
            pop.modalPresentationStyle = .formSheet;
            pop.modalTransitionStyle = .coverVertical
            target.present(pop, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                pop.inputContext.text = code
            }
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

}
