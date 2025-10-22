//
//  CDPASRManager.swift
//  CDPASR
//
//  Created by chaidongpeng on 2025/10/22.
//  ASR语音识别
//  要在info.plist中增加权限：
//  1-Privacy - Speech Recognition Usage Description
//  2-Privacy - Microphone Usage Description

import Foundation
import Speech
import AVFoundation
import UIKit


// 语音识别结果代理
protocol CDPASRManagerDelegate: NSObjectProtocol {
    /// 实时返回识别到的文字
    /// - Parameter text: 识别结果
    /// - Parameter isFinal: 是否为最终识别结果
    func asrManager(_ manager: CDPASRManager, didReceiveTranscription text: String, isFinal: Bool)
    
    /// 识别出现错误
    /// - Parameter error: 错误类型
    /// - Parameter description: 错误描述
    func asrManager(_ manager: CDPASRManager, didFailWithError error: CDPASRError, description: String)
    
    /// 识别状态变化
    /// - Parameter state: 当前状态
    func asrManager(_ manager: CDPASRManager, didChangeState state: CDPASRState)
}

/// 语音识别状态
enum CDPASRState {
    /// 空闲
    case idle
    /// 开始中
    case starting
    /// 录音中
    case recording
    /// 处理中
    case processing
    /// 已停止
    case stopped
}

// 语音识别错误类型
enum CDPASRError {
    /// 无权限
    case permissionDenied
    /// 语音识别服务不可用
    case unavailable
    /// 创建语音识别请求失败
    case recognitionRequestFailed
    /// 未知错误
    case unknown
}

class CDPASRManager: NSObject {
    // 单例实例
    public static let shared = CDPASRManager()
    
    // 代理
    public weak var delegate: CDPASRManagerDelegate? = nil
    // 是否实时返回语音识别结果 (false则只在结束后返回最终结果)
    public var reportPartialResults: Bool = true
    
    // 当前状态
    private(set) var state: CDPASRState = .idle {
        didSet {
            delegate?.asrManager(self, didChangeState: state)
        }
    }
    
    // 语音识别器
    private lazy var speechRecognizer: SFSpeechRecognizer = {
        let sf = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))!
        sf.delegate = self
        return sf
    }()
    // 当前语音识别请求
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    // 当前语音识别任务
    private var recognitionTask: SFSpeechRecognitionTask?
    // 音频引擎
    private let audioEngine = AVAudioEngine()
    
    // 私有化初始化方法
    private override init() {
        super.init()
    }
}

// MARK: - 权限检查
extension CDPASRManager {
    // 检查所有需要的权限
    public func checkAllPermissions(completion: @escaping (Bool) -> Void) {
        // 先检查麦克风权限
        checkMicrophonePermission { [weak self] micGranted in
            guard micGranted else {
                completion(false)
                return
            }
            
            // 再检查语音识别权限
            self?.checkSpeechRecognizerPermission { speechGranted in
                completion(speechGranted)
            }
        }
    }
    
    // 检查并请求-麦克风权限
    public func checkMicrophonePermission(completion: @escaping (Bool) -> Void) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            // 已授权
            completion(true)
        case .denied:
            // 已拒绝
            completion(false)
        case .undetermined:
            // 未决定，请求权限
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        default:
            completion(false)
        }
    }
    
    // 检查并请求-语音识别权限
    public func checkSpeechRecognizerPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    completion(true)
                default:
                    completion(false)
                }
            }
        }
    }
}

// MARK: - 录音和识别
extension CDPASRManager {
    // 开始录音和识别
    public func startRecording() {
        // 检查状态
        guard state == .idle else { return }
        
        // 检查语音识别可用性
        guard speechRecognizer.isAvailable else {
            printLog("CDPASR:语音识别服务不可用")
            delegate?.asrManager(self, didFailWithError: .unavailable, description: "语音识别服务不可用")
            return
        }
        
        state = .starting
        
        // 检查权限
        checkAllPermissions { [weak self] granted in
            guard let self = self else { return }
            if !granted {
                // 无权限
                self.delegate?.asrManager(self, didFailWithError: .permissionDenied, description: "无权限")
                self.state = .idle
                return
            }
            // 开始音频引擎
            self.startAudioEngine()
        }
    }
    
    // 停止录音和识别
    public func stopRecording() {
        guard state == .recording else { return }
        
        state = .processing
        
        // 停止音频引擎
        audioEngine.stop()
        recognitionRequest?.endAudio()
        
        // 停止识别任务
        if let recognitionTask = recognitionTask {
            recognitionTask.finish()
            self.recognitionTask = nil
        }
        
        recognitionRequest = nil
    }
    
    // 开始音频引擎
    private func startAudioEngine() {
        do {
            // 配置音频会话
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            let inputNode = audioEngine.inputNode
            
            // 创建识别请求
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                printLog("CDPASR:无法创建语音识别请求")
                self.delegate?.asrManager(self, didFailWithError: .recognitionRequestFailed, description: "无法创建语音识别请求")
                self.state = .idle
                return
            }
            // 实时返回结果
            recognitionRequest.shouldReportPartialResults = reportPartialResults
            
            // 开始识别任务
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let error = error {
                    printLog("CDPASR:语音识别ing错误: \(error.localizedDescription)")
                    self.delegate?.asrManager(self, didFailWithError: .unknown, description: error.localizedDescription)
                    self.reset()
                    return
                }
                
                // 检查是否完成
                let isFinal = result?.isFinal ?? false
                
                // 获取识别结果
                if let transcription = result?.bestTranscription {
                    let text = transcription.formattedString
                    self.delegate?.asrManager(self, didReceiveTranscription: text, isFinal: isFinal)
                }
                
                // 如果完成，重置状态
                if isFinal {
                    self.reset()
                }
            }
            // 检查并移除已存在的Tap
            if inputNode.numberOfInputs > 0 {
                inputNode.removeTap(onBus: 0)
            }
            // 配置音频输入
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }
            
            // 启动音频引擎
            audioEngine.prepare()
            try audioEngine.start()
            
            self.state = .recording
            
        } catch {
            printLog("CDPASR:语音识别start错误: \(error.localizedDescription)")
            delegate?.asrManager(self, didFailWithError: .unknown, description: error.localizedDescription)
            reset()
        }
    }
    
    // 重置状态
    private func reset() {
        if state != .stopped {
            state = .stopped
            
            // 延迟重置为idle状态，给外部处理的时间
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.state = .idle
            }
        }
    }
}

// MARK: - SFSpeechRecognizerDelegate
extension CDPASRManager: SFSpeechRecognizerDelegate {
    // 语音识别可用性状态改变
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available && state == .recording {
            printLog("CDPASR:语音识别服务不可用")
            delegate?.asrManager(self, didFailWithError: .unavailable, description: "语音识别服务不可用")
            stopRecording()
        }
    }
}

/// 进行log输出
public func printLog<T>(_ message: T, file: String = #file, method: String = #function, line: Int = #line) {
#if DEBUG
    print("\((file as NSString).lastPathComponent)[\(line)], \(method): \(message)")
#endif
}
