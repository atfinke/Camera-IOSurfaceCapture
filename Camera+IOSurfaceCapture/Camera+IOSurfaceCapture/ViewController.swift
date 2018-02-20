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

    private let flipButton = UIButton()
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

        flipButton.translatesAutoresizingMaskIntoConstraints = false
        flipButton.setTitle("FLIP", for: .normal)
        flipButton.titleLabel?.font = UIFont.systemFont(ofSize: 22.0, weight: .semibold)
        flipButton.addTarget(self, action: #selector(swapCamera), for: .touchUpInside)
        view.addSubview(flipButton)

        let constraints = [
            captureButtonView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            captureButtonView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            captureButtonView.widthAnchor.constraint(equalToConstant: 80.0),
            captureButtonView.heightAnchor.constraint(equalToConstant: 80.0),

            flipButton.leftAnchor.constraint(equalTo: captureButtonView.rightAnchor, constant: 0),
            flipButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            flipButton.centerYAnchor.constraint(equalTo: captureButtonView.centerYAnchor, constant: 0),
        ]
        NSLayoutConstraint.activate(constraints)

        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera],
                                                                      mediaType: .video,
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

    @objc
    func swapCamera() {
        guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput else { return }

        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        let currentIsFront = currentInput.device.position == .front
        let newPosition: AVCaptureDevice.Position = currentIsFront ? .back : .front

        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera],
                                                                      mediaType: .video,
                                                                      position: newPosition)

        guard let captureDevice = deviceDiscoverySession.devices.first,
            let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            fatalError()
        }

        captureSession.removeInput(currentInput)
        captureSession.addInput(deviceInput)
        captureSession.outputs.first?.connection(with: .video)?.videoOrientation = .portrait
        captureSession.outputs.first?.connection(with: .video)?.isVideoMirrored = !currentIsFront
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

