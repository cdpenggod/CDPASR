# CDPASR

CDPASR is a lightweight Swift library that simplifies speech recognition by leveraging system-native ASR capabilities. It provides an easy-to-use interface to integrate seamless speech-to-text functionality into your iOS/macOS Swift projects, with minimal setup and full utilization of platform-built-in speech recognition features.

CDPASR 是一款轻量级 Swift 库，通过调用系统原生Speech框架- ASR（自动语音识别）功能简化语音识别开发流程。它提供简洁易用的接口，可帮助你在 iOS/macOS Swift 项目中快速集成流畅的语音转文字功能，配置步骤极少，且能充分利用平台内置的语音识别能力。

## Requirements

### 要求

To use CDPASR, your project must meet the following requirements:



* iOS 10.0+ / macOS 10.15+


使用 CDPASR 前，你的项目需满足以下要求：



* 系统版本：iOS 10.0+ /macOS 10.15+

## Permissions Setup

### 权限配置

CDPASR requires user permissions to access speech recognition and the microphone. You **must** add the following entries to your `Info.plist` file:



1. `NSMicrophoneUsageDescription`

   (Explain why your app needs microphone access, e.g., "Need microphone access to capture your voice for recognition")

2. `NSSpeechRecognitionUsageDescription`

   (Describe why your app requires speech recognition, e.g., "Need speech recognition to convert your voice to text")

These permissions are mandated by iOS/macOS platform guidelines to ensure users are informed about how their data is used. Without these entries, the library will not function properly.

CDPASR 需要获取用户授权才能访问语音识别功能和麦克风。你**必须**在项目的`Info.plist`文件中添加以下配置项：



1. `NSMicrophoneUsageDescription`（麦克风权限描述）

   （需说明 App 使用麦克风的原因，示例："需要访问麦克风以采集您的语音用于识别"）

2. `NSSpeechRecognitionUsageDescription`（语音识别权限描述）

   （需说明 App 使用语音识别的原因，示例："需要访问语音识别功能以将您的语音转换为文字"）

这些权限是 iOS/macOS 平台规范强制要求的，目的是让用户清楚了解 App 如何使用其数据。若未添加这些配置项，该库将无法正常工作。

> （注：文档部分内容可能由 AI 生成）
