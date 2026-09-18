import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // PencilKit 필기 캔버스. Flutter 쪽 PencilKitCanvas 위젯과 짝이다.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PencilKitPlugin") {
      PencilKitViewFactory.register(with: registrar)
    }
  }
}
