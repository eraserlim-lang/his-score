import Flutter
import PencilKit
import UIKit

/// Flutter 의 `hiscore/pencilkit` 플랫폼 뷰.
///
/// 좌표계: Flutter 는 "원본 페이지 폭 1000pt" 기준 공간으로 정규화한 PKDrawing 을 주고받는다.
/// 이 뷰는 크롭된 영역만 보여주므로, 보여줄 때는 기준 공간 → 뷰 공간으로,
/// 돌려줄 때는 그 역변환을 건다. 그래야 기기와 크롭이 달라도 같은 자리에 그려진다.
final class PencilKitViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    PencilKitPlatformView(frame: frame, viewId: viewId, args: args, messenger: messenger)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    registrar.register(PencilKitViewFactory(messenger: registrar.messenger()), withId: "hiscore/pencilkit")

    // 화면에 캔버스가 없어도 PKDrawing 을 PNG 로 굽는 정적 채널. 내보내기에서 쓴다.
    let render = FlutterMethodChannel(name: "hiscore/pencilkit_render", binaryMessenger: registrar.messenger())
    render.setMethodCallHandler { call, result in
      // 지우개 옵션의 "직전 필기 지우기". 그림에서 마지막 획을 떼어 돌려준다.
      // 획은 그은 차례로 쌓이므로 마지막이 가장 나중에 그은 것이다.
      // 떼고 나서 남은 획이 없으면 빈 바이트, 뗄 획이 없으면 nil 이다.
      if call.method == "removeLastStroke" {
        guard let dict = call.arguments as? [String: Any],
              let data = dict["data"] as? FlutterStandardTypedData,
              var drawing = try? PKDrawing(data: data.data),
              !drawing.strokes.isEmpty else {
          result(nil)
          return
        }
        drawing.strokes.removeLast()
        let out = drawing.strokes.isEmpty ? Data() : drawing.dataRepresentation()
        result(FlutterStandardTypedData(bytes: out))
        return
      }
      guard call.method == "render",
            let dict = call.arguments as? [String: Any],
            let data = dict["data"] as? FlutterStandardTypedData,
            let width = dict["width"] as? Int,
            let height = dict["height"] as? Int,
            let drawing = try? PKDrawing(data: data.data) else {
        result(nil)
        return
      }
      let refWidth: CGFloat = 1000
      let refHeight = refWidth * CGFloat(height) / CGFloat(width)
      let rect = CGRect(x: 0, y: 0, width: refWidth, height: refHeight)
      let image = drawing.image(from: rect, scale: CGFloat(width) / refWidth)
      result(image.pngData().map { FlutterStandardTypedData(bytes: $0) })
    }
  }
}

final class PencilKitPlatformView: NSObject, FlutterPlatformView, PKCanvasViewDelegate {
  private let canvas = PKCanvasView()
  private let channel: FlutterMethodChannel

  private static let referenceWidth: CGFloat = 1000

  private var viewWidth: CGFloat = 1
  private var viewHeight: CGFloat = 1
  private var cropLeft: CGFloat = 0
  private var cropTop: CGFloat = 0
  private var cropWidth: CGFloat = 1
  private var cropHeight: CGFloat = 1

  /// setDrawing 으로 들어온 그림을 다시 drawingChanged 로 되돌려 보내지 않기 위한 표시.
  private var applying = false

  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "hiscore/pencilkit_\(viewId)", binaryMessenger: messenger)
    super.init()

    canvas.frame = frame
    canvas.backgroundColor = .clear
    canvas.isOpaque = false
    canvas.isScrollEnabled = false
    canvas.drawingPolicy = .pencilOnly
    canvas.delegate = self
    canvas.tool = PKInkingTool(.pen, color: .black, width: 2)

    if let dict = args as? [String: Any] { applyGeometry(dict) }

    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  func view() -> UIView { canvas }

  // MARK: - 좌표 변환

  /// 기준 공간(폭 1000) → 뷰 공간.
  private var toView: CGAffineTransform {
    let refHeight = Self.referenceWidth * (viewHeight / viewWidth) * (cropWidth / cropHeight)
    let scale = viewWidth / (cropWidth * Self.referenceWidth)
    return CGAffineTransform(translationX: -cropLeft * Self.referenceWidth, y: -cropTop * refHeight)
      .concatenating(CGAffineTransform(scaleX: scale, y: scale))
  }

  private func applyGeometry(_ dict: [String: Any]) {
    func num(_ key: String, _ fallback: CGFloat) -> CGFloat {
      if let v = dict[key] as? Double { return CGFloat(v) }
      return fallback
    }
    viewWidth = max(1, num("viewWidth", viewWidth))
    viewHeight = max(1, num("viewHeight", viewHeight))
    cropLeft = num("cropLeft", cropLeft)
    cropTop = num("cropTop", cropTop)
    cropWidth = max(0.05, num("cropWidth", cropWidth))
    cropHeight = max(0.05, num("cropHeight", cropHeight))
  }

  // MARK: - Flutter → Native

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setGeometry":
      // 기하가 바뀌면 현재 그림을 기준 공간으로 되돌린 뒤 새 변환으로 다시 놓는다.
      let reference = canvas.drawing.transformed(using: toView.inverted())
      if let dict = call.arguments as? [String: Any] { applyGeometry(dict) }
      applying = true
      canvas.drawing = reference.transformed(using: toView)
      applying = false
      result(nil)

    case "setDrawing":
      guard let dict = call.arguments as? [String: Any],
            let data = dict["data"] as? FlutterStandardTypedData else { result(nil); return }
      applying = true
      defer { applying = false }
      if data.data.isEmpty {
        canvas.drawing = PKDrawing()
      } else if let drawing = try? PKDrawing(data: data.data) {
        canvas.drawing = drawing.transformed(using: toView)
      }
      result(nil)

    case "setTool":
      guard let dict = call.arguments as? [String: Any] else { result(nil); return }
      let eraser = dict["eraser"] as? Bool ?? false
      if eraser {
        if #available(iOS 16.4, *) {
          canvas.tool = PKEraserTool(.bitmap, width: 20)
        } else {
          canvas.tool = PKEraserTool(.bitmap)
        }
      } else {
        let preset = dict["preset"] as? String ?? "pen"
        let argb = dict["color"] as? Int ?? 0xFF000000
        let width = CGFloat(dict["width"] as? Double ?? 1)
        canvas.tool = Self.inkingTool(preset: preset, argb: argb, width: width)
      }
      let fingerDraws = dict["fingerDraws"] as? Bool ?? false
      canvas.drawingPolicy = fingerDraws ? .anyInput : .pencilOnly
      result(nil)

    case "setEditing":
      guard let dict = call.arguments as? [String: Any] else { result(nil); return }
      let editing = dict["editing"] as? Bool ?? false
      let fingerDraws = dict["fingerDraws"] as? Bool ?? false
      canvas.isUserInteractionEnabled = editing
      canvas.drawingPolicy = fingerDraws ? .anyInput : .pencilOnly
      result(nil)

    case "undo":
      canvas.undoManager?.undo()
      result(nil)

    case "redo":
      canvas.undoManager?.redo()
      result(nil)

    case "clear":
      canvas.drawing = PKDrawing()
      result(nil)

    case "renderImage":
      // 내보내기용. 기준 공간 전체를 요청한 폭으로 그린다.
      guard let dict = call.arguments as? [String: Any],
            let width = dict["width"] as? Double,
            let height = dict["height"] as? Double else { result(nil); return }
      let reference = canvas.drawing.transformed(using: toView.inverted())
      let refHeight = Self.referenceWidth * CGFloat(height / width)
      let rect = CGRect(x: 0, y: 0, width: Self.referenceWidth, height: refHeight)
      let scale = CGFloat(width) / Self.referenceWidth
      let image = reference.image(from: rect, scale: scale)
      result(image.pngData().map { FlutterStandardTypedData(bytes: $0) })

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func inkingTool(preset: String, argb: Int, width: CGFloat) -> PKInkingTool {
    let a = CGFloat((argb >> 24) & 0xFF) / 255
    let r = CGFloat((argb >> 16) & 0xFF) / 255
    let g = CGFloat((argb >> 8) & 0xFF) / 255
    let b = CGFloat(argb & 0xFF) / 255
    let color = UIColor(red: r, green: g, blue: b, alpha: a)
    switch preset {
    case "marker":
      return PKInkingTool(.marker, color: color.withAlphaComponent(0.4), width: 14 * width)
    case "pencil":
      return PKInkingTool(.pencil, color: color, width: 1.6 * width)
    case "brush":
      return PKInkingTool(.pen, color: color, width: 5 * width)
    default:
      return PKInkingTool(.pen, color: color, width: 2 * width)
    }
  }

  // MARK: - Native → Flutter

  func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
    if applying { return }
    let reference = canvasView.drawing.transformed(using: toView.inverted())
    let data = reference.strokes.isEmpty ? Data() : reference.dataRepresentation()
    channel.invokeMethod("drawingChanged", arguments: FlutterStandardTypedData(bytes: data))
  }

  // 펜을 봤다는 사실은 여기서 알리지 않는다. 이 콜백은 손가락으로 그려도 불려서,
  // 손가락 첫 획에 "펜 있음" 으로 바뀌어 다음 획부터 손가락 그리기가 꺼졌다.
  // 펜 입력은 Flutter 쪽 포인터 이벤트(stylus)로도 들어오므로 거기서 판별한다.
}
