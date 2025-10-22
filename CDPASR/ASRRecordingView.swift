//
//  ASRRecordingView.swift
//  CDPASR
//
//  Created by chaidongpeng on 2025/10/22.
//  录音视图view

import UIKit

// 录音视图代理
protocol ASRRecordingViewDelegate: NSObjectProtocol {
    /// 开始录音
    func startRecording()
    /// 停止录音
    func stopRecording()
}

class ASRRecordingView: UIView {
    // 代理
    public weak var delegate: ASRRecordingViewDelegate?
    
    // 录音按钮
    private let recordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("按住说话", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemPurple
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return button
    }()
    
    // 状态标签
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "准备就绪"
        label.textColor = .darkGray
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    // 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 设置视图
    private func setupViews() {
        backgroundColor = .white
        addSubview(recordButton)
        addSubview(statusLabel)
    }
    
    private func setupConstraints() {
        // 设置 recordButton 的 frame
        recordButton.frame = CGRect(
            x: (frame.width - 120) / 2,
            y: (frame.height - 40) / 2,
            width: 120,
            height: 40
        )
        
        // 设置 statusLabel 的 frame
        statusLabel.sizeToFit() // 根据文本内容调整大小
        statusLabel.frame.size.width += 20
        statusLabel.frame = CGRect(
            x: (frame.width - statusLabel.frame.width) / 2,
            y: recordButton.frame.minY - 25,
            width: statusLabel.frame.width,
            height: statusLabel.frame.height
        )
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupConstraints()
    }
    
    // 设置手势
    private func setupGestures() {
        // 长按录音
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        recordButton.addGestureRecognizer(longPress)
    }
    
    // 更新状态显示
    func updateStatus(_ text: String) {
        statusLabel.text = text
    }
    
    // 更新按钮状态
    func updateButton(isRecording: Bool) {
        if isRecording {
            recordButton.backgroundColor = .systemRed
            recordButton.setTitle("松开结束", for: .normal)
        } else {
            recordButton.backgroundColor = .systemPurple
            recordButton.setTitle("按住说话", for: .normal)
        }
    }
    
    // 处理长按手势
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            delegate?.startRecording()
            updateButton(isRecording: true)
            updateStatus("正在录音...")
        case .ended, .cancelled:
            delegate?.stopRecording()
            updateButton(isRecording: false)
            updateStatus("录音已结束")
        default:
            break
        }
    }
}
