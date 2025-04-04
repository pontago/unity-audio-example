## Unity Audio Example with Swift

Unity から Swift の AudioUnit を使用して、音声入力 → 出力するサンプルプロジェクトです。

### 前提条件

- iOS13 or 15 以上
- iOS Simulator では上手く音声入力できない場合があるので実機にて確認推奨
- Unity6

### Unity の設定

- [File]-[Build]-[iOS]をアクティブにする
- テストする際は、[File]-[BuildProfiles]-[iOS]-[Run in Xcode as]を Debug。

#### [Edit]-[Project Settings]-[Player]-[Other Settings]

- Bundle Identifier: アプリで使用する Bundle Identifier
- Microphone Usage Description: 録音権限の説明文（必須、ないと動かない）
- Mute Other Audio Sources: 使用時に他の音声出力を止めるかどうか（チェックする）
- Prepare iOS for Recording: 録音の初期化処理をする（チェックする）
- Target Device: iPhone（+iPad）
- Target SDK: Device SDK（実機確認時）、Simulator SDK（Simulator 確認時、非推奨）

## Swift ファイル

Assets/Plugin/iOS/AudioManager.swift に配置。この Swift ファイルからオーディオをコントロールするためのメソッドを定義している。

公開メソッド

- audioStart
  - オーディオ入力と出力を開始する。イヤホン装着時はイヤホンから出力される。それ以外は、受話口から出力される。
- audioStop
  - オーディオ入力と出力を終了する。
- setupAudioSession
  - オーディオ出力切り替えを行う。audioStart の前に呼ぶ。
- latestInputAudioDbfs
  - 最新の入力音量を取得する。dBFS 単位。iPhone だと, -80.0 ~ 0.0 の範囲。
- latestInputAudioDbspl
  - 最新の入力音量を取得する。dBSPL 単位。上記値を 0.0 ~ 140.0 に正規化したもの。

audioStart 後、一定間隔で、latestInputAudioDbspl を呼び出すことで現在の音量を取得する。

## Uniti のでも

- ButtonScript.cs で、Swift のオーディオを制御。
- InputAudioVolume.cs で、latestInputAudioDbspl を取得・更新。

## トラブルシュート

- iPhone 実機でオーディオ入力されない。  
  アプリ初回起動時にマイクの許可画面が出ていない場合は、Unity から出力される Xcode プロジェクトの中にある、「Unity-iPhone/Classes/Preprocessor.h」ファイル内の「UNITY_USES_MICROPHONE」を「1」に変更する。  
  もしくは、「Microphone Usage Description」を設定しているか確認。
