//
//  AudioManager.swift
//  iosAudio
//
//  Created by void on 2025/04/03.
//

import AVFAudio
import AudioToolbox
import Foundation

class AudioManager {
  static var shared: AudioManager = AudioManager()

  private var audioUnit: AudioUnit?
  
  var latestDb: Float32 = 0.0
  var started: Bool = false

  init() {
    var desc = AudioComponentDescription(
      componentType: kAudioUnitType_Output,
      componentSubType: kAudioUnitSubType_RemoteIO,
      componentManufacturer: kAudioUnitManufacturer_Apple,
      componentFlags: 0,
      componentFlagsMask: 0
    )

    guard let component = AudioComponentFindNext(nil, &desc) else {
      NSLog("AudioComponent not found")
      return
    }

    var tempAudioUnit: AudioUnit?
    if AudioComponentInstanceNew(component, &tempAudioUnit) != noErr {
      NSLog("AudioUnit instance creation failed")
      return
    }
    audioUnit = tempAudioUnit

    enableIO()
    setupAudioFormat()
    setupRenderCallback()

    AudioUnitInitialize(audioUnit!)
  }

  deinit {
    AudioUnitUninitialize(audioUnit!)
  }

  private func enableIO() {
    guard let audioUnit = audioUnit else { return }

    var enable: UInt32 = 1

    // 入力 (マイク) を有効化
    let inStatus = AudioUnitSetProperty(
      audioUnit,
      kAudioOutputUnitProperty_EnableIO,
      kAudioUnitScope_Input,
      1,  // バス1 = マイク入力
      &enable,
      UInt32(MemoryLayout.size(ofValue: enable)))
    NSLog("enableIO - inStatus: \(inStatus)");
    
    // 出力 (スピーカー) を有効化
    let outStatus = AudioUnitSetProperty(
      audioUnit,
      kAudioOutputUnitProperty_EnableIO,
      kAudioUnitScope_Output,
      0,  // バス0 = スピーカー出力
      &enable,
      UInt32(MemoryLayout.size(ofValue: enable)))
    NSLog("enableIO - outStatus: \(outStatus)");
  }

  func startAudioUnit() {
    if started {
//      do {
//        try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
//      } catch {
//        print("Failed to set AVAudioSession: \(error)")
//      }
      return
    }
    guard let audioUnit = audioUnit else { return }

    AudioOutputUnitStart(audioUnit)
    started = true
    
    NSLog("START AUDIO.")
  }

  func stopAudioUnit() {
    guard let audioUnit = audioUnit else { return }

    AudioOutputUnitStop(audioUnit)
    
    started = false

    NSLog("STOP AUDIO.")
  }
  
  func setupAudioSession() {
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker])
      try audioSession.setActive(true)
      //try audioSession.overrideOutputAudioPort(.speaker)
    } catch {
      NSLog("Failed to set AVAudioSession: \(error)")
    }
  }

  private func setupAudioFormat() {
    guard let audioUnit = audioUnit else { return }

    // 44.1kHz, 16-bit, 2ch (ステレオ)
//        var streamFormat = AudioStreamBasicDescription(
//          mSampleRate: 44100,
//          mFormatID: kAudioFormatLinearPCM,
//          mFormatFlags: kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger,
//          mBytesPerPacket: 2 * 2,  // 16bit(2byte) * 2ch
//          mFramesPerPacket: 1,
//          mBytesPerFrame: 2 * 2,
//          mChannelsPerFrame: 2,
//          mBitsPerChannel: 16,
//          mReserved: 0
//        )
    // 44.1kHz, 32-bit, 2ch (ステレオ)
    var streamFormat = AudioStreamBasicDescription(
      mSampleRate: 44100.0,
      mFormatID: kAudioFormatLinearPCM,
      mFormatFlags: kAudioFormatFlagIsFloat,
      mBytesPerPacket: UInt32(MemoryLayout<Float32>.size * 2),
      mFramesPerPacket: 1,
      mBytesPerFrame: UInt32(MemoryLayout<Float32>.size * 2),
      mChannelsPerFrame: 2,
      mBitsPerChannel: UInt32(MemoryLayout<Float32>.size * 8),
      mReserved: 0
    )

    // 出力フォーマット設定
    AudioUnitSetProperty(
      audioUnit,
      kAudioUnitProperty_StreamFormat,
      kAudioUnitScope_Input,
      0,
      &streamFormat,
      UInt32(MemoryLayout.size(ofValue: streamFormat)))

    // 入力フォーマット設定
    AudioUnitSetProperty(
      audioUnit,
      kAudioUnitProperty_StreamFormat,
      kAudioUnitScope_Output,
      1,
      &streamFormat,
      UInt32(MemoryLayout.size(ofValue: streamFormat)))
  }

  private func setupRenderCallback() {
    guard let audioUnit = audioUnit else { return }

    var outCallback = AURenderCallbackStruct(
      inputProc: renderCallback,
      inputProcRefCon: UnsafeMutableRawPointer(
        Unmanaged.passUnretained(self).toOpaque())
    )

    AudioUnitSetProperty(
      audioUnit,
      kAudioUnitProperty_SetRenderCallback,
      kAudioUnitScope_Input,
      0,  // 出力のバス0 (スピーカー)
      &outCallback,
      UInt32(MemoryLayout.size(ofValue: outCallback)))
  }
    
  private let renderCallback: AURenderCallback = {
    (
      inRefCon: UnsafeMutableRawPointer,
      ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
      inTimeStamp: UnsafePointer<AudioTimeStamp>,
      inBusNumber: UInt32,
      inNumberFrames: UInt32,
      ioData: UnsafeMutablePointer<AudioBufferList>?
    ) -> OSStatus in

    guard let ioData = ioData else { return noErr }

    let audioUnitManager = Unmanaged<AudioManager>.fromOpaque(inRefCon)
      .takeUnretainedValue()
    guard let audioUnit = audioUnitManager.audioUnit else { return noErr }

    // AudioBuffer
    let bufferSize = Int(inNumberFrames) * MemoryLayout<Float32>.size * 2
    let audioBuffer = UnsafeMutablePointer<Float32>.allocate(capacity: bufferSize / MemoryLayout<Float32>.size)
    var bufferList = AudioBufferList(
      mNumberBuffers: 1,
      mBuffers: AudioBuffer(
        mNumberChannels: 2,
        mDataByteSize: UInt32(bufferSize),
        mData: UnsafeMutableRawPointer(audioBuffer)
      )
    )

    // マイク入力からデータを取得
    let status = AudioUnitRender(
      audioUnit,
      ioActionFlags,
      inTimeStamp,
      1,  // 入力のバス1 (マイク)
      inNumberFrames,
      &bufferList)
    NSLog("size: %d", Int(bufferList.mBuffers.mDataByteSize))

    if status != noErr {
      NSLog("AudioUnitRender failed:", status)
      return status
    }

    var leftRMS: Float32 = 0.0
    var rightRMS: Float32 = 0.0
//    let data = bufferList.mBuffers.mData!.assumingMemoryBound(to: Int16.self)
    let data = bufferList.mBuffers.mData!.assumingMemoryBound(to: Float32.self)
    for frame in 0..<Int(inNumberFrames) {
      // 左右のチャンネルを個別に処理
//      let leftValue = Float32(data[frame * 2]) / 32768.0
//      let rightValue = Float32(data[frame * 2 + 1]) / 32768.0
//      let leftValue = data[frame * 2]
//      let rightValue = data[frame * 2 + 1]
      let leftValue = data[frame * 2]
      let rightValue = data[frame * 2 + 1]
      leftRMS += leftValue * leftValue
      rightRMS += rightValue * rightValue
    }
    leftRMS = sqrt(leftRMS / Float32(inNumberFrames))
    rightRMS = sqrt(rightRMS / Float32(inNumberFrames))

    // RMSをデシベルに変換
    let leftdB = 20 * log10(leftRMS)
    let rightdB = 20 * log10(rightRMS)
    let convertedDB = dbfsToSPL(leftdB)
    AudioManager.shared.latestDb = convertedDB
    NSLog("Left Volume: \(leftdB) dB, Right Volume: \(rightdB) dB, coverted dB: \(convertedDB)")
    
// モノラル
//    var rms: Float32 = 0.0
//    let data = bufferList.mBuffers.mData!.assumingMemoryBound(to: Float32.self)
//    for frame in 0..<Int(inNumberFrames) {
//      rms += data[frame] * data[frame]
//    }
//    rms = sqrt(rms / Float32(inNumberFrames))
//
//    // RMSをデシベルに変換
//    let dB = 20 * log10(rms)
//    let convertedDB = dbfsToSPL(dB)
//    NSLog("Volume: \(dB) dB, coverted dB: \(convertedDB)")
    

    // 出力バッファにコピー
    memcpy(
      ioData.pointee.mBuffers.mData, bufferList.mBuffers.mData,
      Int(bufferList.mBuffers.mDataByteSize))

    audioBuffer.deallocate()
    
    return noErr
  }
  
  // -80dBFS（静かな環境）を0dBSPL、0dBFS（最大音）を140dBSPLと仮定
  static func dbfsToSPL(_ dbfs: Float32) -> Float32 {
    let silentDbfs: Float32 = -80.0 // 無音判定しきい値（dBFS）
    let loudestSPL: Float32 = 140.0 // 最大音
    let silentSPL: Float32 = 0.0 // 無音判定しきい値=0dB
    let clamped = max(min(dbfs, 0), silentDbfs) // dBFS範囲を制限
    return ((clamped + abs(silentDbfs)) / abs(silentDbfs)) * (loudestSPL - silentSPL) + silentSPL
  }
}

//@_cdecl("audioStart")
//public func audioStart() {
//  AudioManager.shared.startAudioUnit()
//}
//
//@_cdecl("audioStop")
//public func audioStop() {
//  AudioManager.shared.stopAudioUnit()
//}
