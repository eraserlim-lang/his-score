import Flutter
import UIKit

/// 다른 앱에서 PDF 를 "HIScore 로 열기" 했을 때 파일 URL 을 Flutter 에 넘긴다.
///
/// 보안 스코프 URL 은 앱 샌드박스 안 임시 폴더로 복사한 뒤 경로만 넘긴다.
class SceneDelegate: FlutterSceneDelegate {
  private var pending: String?
  private var channel: FlutterMethodChannel?

  /// 애플 펜슬 두 번 두드리기. 대리자는 약하게 잡히므로 여기서 붙들어 둔다.
  private var pencilRelay: PencilTapRelay?

  override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    setupChannel()
    setupPencil()
    // 창이 아직 덜 차려졌으면 다음 차례에 한 번 더 해 본다.
    DispatchQueue.main.async { [weak self] in self?.setupPencil() }
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

  /// 애플 펜슬 2·프로의 두 번 두드리기를 화면 전체에서 받는다.
  private func setupPencil() {
    guard pencilRelay == nil,
          let controller = window?.rootViewController as? FlutterViewController else { return }
    let relay = PencilTapRelay(
      channel: FlutterMethodChannel(name: "hiscore/pencil", binaryMessenger: controller.binaryMessenger)
    )
    let interaction = UIPencilInteraction()
    interaction.delegate = relay
    controller.view.addInteraction(interaction)
    pencilRelay = relay
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

/// 애플 펜슬 두 번 두드리기를 Flutter 에 알린다.
///
/// 무엇을 할지(직전 도구로, 없으면 지우개로)는 Flutter 쪽 필기 도구가 정한다.
/// 설정 앱에서 두 번 두드리기를 "무시" 로 둔 사람은 그대로 따른다.
final class PencilTapRelay: NSObject, UIPencilInteractionDelegate {
  private let channel: FlutterMethodChannel

  init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  // iOS 17.5 부터는 이쪽이 불린다.
  @available(iOS 17.5, *)
  func pencilInteraction(_ interaction: UIPencilInteraction, didReceiveTap tap: UIPencilInteraction.Tap) {
    relay()
  }

  // 그 전 버전.
  func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
    relay()
  }

  private func relay() {
    if UIPencilInteraction.preferredTapAction == .ignore { return }
    channel.invokeMethod("doubleTap", arguments: nil)
  }
}
