import Flutter
import UIKit

/// 다른 앱에서 PDF 를 "HIScore 로 열기" 했을 때 파일 URL 을 Flutter 에 넘긴다.
///
/// 보안 스코프 URL 은 앱 샌드박스 안 임시 폴더로 복사한 뒤 경로만 넘긴다.
class SceneDelegate: FlutterSceneDelegate {
  private var pending: String?
  private var channel: FlutterMethodChannel?

  override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    setupChannel()
    for context in connectionOptions.urlContexts { handle(context.url) }
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    for context in URLContexts { handle(context.url) }
  }

  private func setupChannel() {
    guard channel == nil,
          let controller = window?.rootViewController as? FlutterViewController else { return }
    channel = FlutterMethodChannel(name: "hiscore/open_in", binaryMessenger: controller.binaryMessenger)
    channel?.setMethodCallHandler { [weak self] call, result in
      if call.method == "takePending" {
        result(self?.pending)
        self?.pending = nil
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func handle(_ url: URL) {
    // OAuth 되돌아오기(hiscore://oauth)는 app_links 가 처리한다.
    guard url.isFileURL, url.pathExtension.lowercased() == "pdf" else { return }
    setupChannel()

    let accessed = url.startAccessingSecurityScopedResource()
    defer { if accessed { url.stopAccessingSecurityScopedResource() } }

    // 파일명이 그대로 곡 제목이 된다. 겹침은 파일명 앞에 붙이지 말고
    // 폴더를 따로 파서 피한다. "openin-1732..." 가 제목에 섞이면 안 된다.
    let folder = FileManager.default.temporaryDirectory
      .appendingPathComponent("openin/\(Int(Date().timeIntervalSince1970))", isDirectory: true)
    let target = folder.appendingPathComponent(url.lastPathComponent)
    do {
      try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
      try? FileManager.default.removeItem(at: target)
      try FileManager.default.copyItem(at: url, to: target)
    } catch {
      return
    }
    pending = target.path
    channel?.invokeMethod("openFile", arguments: target.path)
  }
}
