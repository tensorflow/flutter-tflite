// Copyright 2023 The TensorFlow Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import Flutter
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
            
            let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
            let audioRecordChannel = FlutterMethodChannel(name: "org.tensorflow.audio_classification/audio_record",
                                                          binaryMessenger: controller.binaryMessenger)
            audioRecordChannel.setMethodCallHandler({
                (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
                switch call.method{
                case "requestPermissionAndCreateRecorder":
                    guard let args = call.arguments as? [String : Any] else {return}
                    let sampleRate = args["sampleRate"] as! Int
                    let requiredInputBufferSize = args["requiredInputBuffer"] as! Int
                    self.requestPermissionAndCreateRecorder(sampleRate: sampleRate,
                                                            requiredInputBufferSize:requiredInputBufferSize,
                                                            flutterResult: result)
                case "startRecord": self.startRecord()
                case "getAudioFloatArray":result(self.getAudioFloatArray())
                case "closeRecorder": result(self.closeRecorder())
                default:result(FlutterMethodNotImplemented)
                }
            })
            
            GeneratedPluginRegistrant.register(with: self)
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }
    
    private var flutterResult : FlutterResult? = nil
    private var audioEngine = AVAudioEngine()
    private var sampleRate = 0
    private var bufferSize = 0
    private let dispatchQueue = DispatchQueue(label: "conversionQueue")
    private var audioFloatArray = [Float]();
    
    // Requests permission to record audio and creates a recorder.
    public func requestPermissionAndCreateRecorder(sampleRate: Int,
                                                   requiredInputBufferSize: Int,
                                                   flutterResult: @escaping FlutterResult) {
        // Store the Flutter result callback.
        self.flutterResult = flutterResult
        
        // Request permission to record audio.
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                // If permission is granted, initialize the recorder.
                self.sampleRate = sampleRate
                self.bufferSize = requiredInputBufferSize * 2
                self.audioFloatArray = [Float](repeating: 0.0, count: requiredInputBufferSize)
                
                self.createRecorder()
                self.flutterResult!(true)
            } else {
                // Inform the user that recording permission is required.
                print("Please grant this app recording permission so it can classify sounds.")
                self.flutterResult!(false)
            }
        }
    }
    
    private func createRecorder(){
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        guard let recordingFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Double(sampleRate),
            channels: 1,
            interleaved: true
        ), let formatConverter = AVAudioConverter(from:inputFormat, to: recordingFormat) else { return }
        
        // installs a tap on the audio engine and specifying the buffer size and the input format.
        inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(bufferSize), format: inputFormat) {
            buffer, _ in
            
            // An AVAudioConverter is used to convert the microphone input to the format required
            // for the model.
            guard let pcmBuffer = AVAudioPCMBuffer(
                pcmFormat: recordingFormat,
                frameCapacity: AVAudioFrameCount(recordingFormat.sampleRate * 2.0)
            ) else { return }
            
            var error: NSError?
            let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                outStatus.pointee = AVAudioConverterInputStatus.haveData
                return buffer
            }
            
            formatConverter.convert(to: pcmBuffer, error: &error, withInputFrom: inputBlock)
            
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.dispatchQueue.async {
                if let channelData = pcmBuffer.floatChannelData {
                    let channelDataValue = channelData.pointee
                    let channelDataValueArray = stride(
                        from: 0,
                        to: Int(pcmBuffer.frameLength),
                        by: buffer.stride
                    ).map { channelDataValue[$0] }
                    self.audioFloatArray = Array(channelDataValueArray[0..<self.audioFloatArray.count])
                }
            }
        }
        audioEngine.prepare()
    }
    
    // Starts the recorder. This function should be called after the recorder has been created.
    public func startRecord() {
        do {
            try audioEngine.start()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // Converts the Float array to a FlutterStandardTypedData.
    public func getAudioFloatArray()-> FlutterStandardTypedData {
        let data = Data(bytes: &audioFloatArray, count: audioFloatArray.count * MemoryLayout<Float>.stride)
        let flutterTypeData = FlutterStandardTypedData(float32: data)
        return flutterTypeData
    }
    
    private func closeRecorder()-> Bool {
        self.audioEngine.stop()
        return true
    }
}
