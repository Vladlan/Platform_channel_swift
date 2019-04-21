// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit
import Flutter

enum ChannelName {
  static let battery = "samples.flutter.io/battery"
  static let charging = "samples.flutter.io/charging"
  static let radio = "samples.flutter.io/radio"
}

enum BatteryState {
  static let charging = "charging"
  static let discharging = "discharging"
}

enum MyFlutterErrorCode {
  static let unavailable = "UNAVAILABLE"
}

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?

  override func application(
          _ application: UIApplication,
          didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    guard let controller = window?.rootViewController as? FlutterViewController else {
      fatalError("rootViewController is not type FlutterViewController")
    }
    print("batteryChannel")
    let batteryChannel = FlutterMethodChannel(name: ChannelName.battery, binaryMessenger: controller)
    batteryChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
      guard call.method == "getBatteryLevel" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.receiveBatteryLevel(result: result)
    })

    let chargingChannel = FlutterEventChannel(name: ChannelName.charging, binaryMessenger: controller)
    chargingChannel.setStreamHandler(self)


    let radioChannel = FlutterMethodChannel(name: ChannelName.radio, binaryMessenger: controller)
    radioChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
      guard call.method == "play" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.play(result: result)
    })


    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func receiveBatteryLevel(result: FlutterResult) {
    print("receiveBatteryLevel()")

    let device = UIDevice.current
    print("device:")
    print(device)
    print("device.isBatteryMonitoringEnabled:")
    print(device.isBatteryMonitoringEnabled)
    device.isBatteryMonitoringEnabled = true
    guard device.batteryState != .unknown  else {
      result(FlutterError(code: MyFlutterErrorCode.unavailable,
              message: "Battery info unavailable",
              details: nil))
      return
    }
    result(Int(device.batteryLevel * 100))
  }

  private func play(result: FlutterResult) {
    print("play()")
    result(true)
  }

  public func onListen(withArguments arguments: Any?,
                       eventSink: @escaping FlutterEventSink) -> FlutterError? {
    print("onListen()")
    self.eventSink = eventSink
    UIDevice.current.isBatteryMonitoringEnabled = true
    sendBatteryStateEvent()
    NotificationCenter.default.addObserver(
            self,
            selector: #selector(AppDelegate.onBatteryStateDidChange),
            name: NSNotification.Name.UIDeviceBatteryStateDidChange,
            object: nil)
    return nil
  }

  @objc private func onBatteryStateDidChange(notification: NSNotification) {
    print("onBatteryStateDidChange()")
    sendBatteryStateEvent()
  }

  private func sendBatteryStateEvent() {
    print("sendBatteryStateEvent()")
    guard let eventSink = eventSink else {
      return
    }

    switch UIDevice.current.batteryState {
    case .full:
      eventSink(BatteryState.charging)
    case .charging:
      eventSink(BatteryState.charging)
    case .unplugged:
      eventSink(BatteryState.discharging)
    default:
      eventSink(FlutterError(code: MyFlutterErrorCode.unavailable,
              message: "Charging status unavailable",
              details: nil))
    }
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    print("onCancel()")
    NotificationCenter.default.removeObserver(self)
    eventSink = nil
    return nil
  }
}
