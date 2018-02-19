//
//  ViewController.swift
//  Camera+IOSurfaceCapture
//
//  Created by Andrew Finke on 2/18/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import UIKit
import AVFoundation
import VideoToolbox

private class CaptureButton: UIButton {
    override open var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UIColor.lightGray : UIColor.white
        }
    }
}

private class CaptureButtonView: UIView {

    var buttonPressed: (() -> ())?

    init() {
        super.init(frame: .zero)

        layer.cornerRadius = 80.0 / 2
        layer.borderWidth = 0
        layer.borderColor = UIColor.black.cgColor
        backgroundColor = UIColor.white
        translatesAutoresizingMaskIntoConstraints = false

        let innerViewWidth: CGFloat = 80.0 - 20
        let innerButton = CaptureButton(frame: CGRect(x: 0, y: 0, width: innerViewWidth, height: innerViewWidth))
        innerButton.layer.cornerRadius = innerViewWidth / 2
        innerButton.layer.borderWidth = 3
        innerButton.layer.borderColor = UIColor.black.cgColor
        innerButton.center = CGPoint(x: 40, y: 40)
        innerButton.backgroundColor = UIColor.white

        innerButton.addTarget(self, action: #selector(captureButtonPressed), for: .touchUpInside)

        addSubview(innerButton)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func captureButtonPressed() {
        buttonPressed?()
    }

}

class ViewController: UIViewController {

    var imageCaptured: ((UIImage) -> ())?

    private let sessionQueue = DispatchQueue(label: "session queue", attributes: [], target: nil)

    private var captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    private let imageView = UIImageView()
    private let captureButtonView = CaptureButtonView()

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.frame = view.frame
        view.addSubview(imageView)

        captureButtonView.buttonPressed = { [weak self] in
            self?.captureButtonPressed()
        }
        view.addSubview(captureButtonView)

        let constraints = [
            captureButtonView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            captureButtonView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            captureButtonView.widthAnchor.constraint(equalToConstant: 80.0),
            captureButtonView.heightAnchor.constraint(equalToConstant: 80.0)
        ]
        NSLayoutConstraint.activate(constraints)

        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera],
                                                                      mediaType: AVMediaType.video,
                                                                      position: .back)

        guard let captureDevice = deviceDiscoverySession.devices.first else {
            fatalError()
        }

        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)

            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)

            captureSession.addOutput(videoOutput)
            videoOutput.connection(with: .video)?.videoOrientation = .portrait

        } catch {
            print(error)
            return
        }

        captureSession.startRunning()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        captureSession.stopRunning()
    }

    func captureButtonPressed() {
        guard let image = imageView.image else {
            return
        }
        UIImpactFeedbackGenerator().impactOccurred()
        imageCaptured?(image)
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        var imageFromBuffer: CGImage?

        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, nil, &imageFromBuffer)

        guard let cgImage = imageFromBuffer else {
            return
        }

        let image = UIImage(cgImage: cgImage)
        DispatchQueue.main.async {
            self.imageView.image = image
        }
    }

}

