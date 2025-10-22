//
//  ViewController.swift
//  CDPASR
//
//  Created by chaidongpeng on 2025/10/22.
//

import UIKit

class ViewController: UIViewController {
    // ASR管理器
    private let asrManager = CDPASRManager.shared
    
    // 录音视图
    private let recordingView = ASRRecordingView()
    
    // 识别结果文本视图
    private let resultTextView: UITextView = {
        let textView = UITextView()
        textView.layer.cornerRadius = 10
        textView.layer.masksToBounds = true
        textView.layer.borderColor = UIColor.black.cgColor
        textView.layer.borderWidth = 1
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isEditable = false
        textView.text = "识别结果将显示在这里..."
        return textView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupDelegates()
        checkPermissions()
    }
    
    // 设置UI
    private func setupUI() {
        view.backgroundColor = .white
        
        // 添加子视图
        view.addSubview(resultTextView)
        view.addSubview(recordingView)
        
        resultTextView.frame = CGRect(x: 20, y: 100, width: view.frame.width - 40, height: 200)
        recordingView.frame = CGRect(x: 0, y: view.frame.height - 140, width: view.frame.width, height: 100)
    }
    
    // 设置代理
    private func setupDelegates() {
        asrManager.delegate = self
        recordingView.delegate = self
    }
    
    // 检查权限
    private func checkPermissions() {
        asrManager.checkAllPermissions { [weak self] granted in
            guard let self = self else { return }
            if !granted {
                self.showPermissionAlert()
            }
        }
    }
    
    // 显示权限提示
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "需要麦克风和语音识别权限",
            message: "请在设置中开启麦克风和语音识别权限以使用此功能",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "设置", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        present(alert, animated: true)
    }
}

// MARK: - CDPASRManagerDelegate
extension ViewController: CDPASRManagerDelegate {
    func asrManager(_ manager: CDPASRManager, didReceiveTranscription text: String, isFinal: Bool) {
        printLog(text)
        resultTextView.text = text
    }
    
    func asrManager(_ manager: CDPASRManager, didFailWithError error: CDPASRError, description: String) {
        let alert = UIAlertController(
            title: "识别错误",
            message: description,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    func asrManager(_ manager: CDPASRManager, didChangeState state: CDPASRState) {
        switch state {
        case .idle:
            recordingView.updateStatus("准备就绪")
        case .starting:
            recordingView.updateStatus("开始录音...")
        case .recording:
            recordingView.updateStatus("正在录音...")
        case .processing:
            recordingView.updateStatus("处理中...")
        case .stopped:
            recordingView.updateStatus("录音已结束")
        }
    }
}

// MARK: - ASRRecordingViewDelegate
extension ViewController: ASRRecordingViewDelegate {
    func startRecording() {
        asrManager.startRecording()
    }
    
    func stopRecording() {
        asrManager.stopRecording()
    }
}
