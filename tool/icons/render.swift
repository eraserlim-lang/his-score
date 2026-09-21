// SVG 한 장을 PNG 한 장으로 굽는다. build_icons.sh 가 부른다.
//
// macOS 14 부터 NSImage 가 SVG 를 직접 읽는다. 크기마다 벡터에서 바로 그리므로
// 큰 PNG 를 줄이는 것보다 작은 아이콘이 선명하다.
//
// 인자: <svg> <png> <픽셀> <방식> [비율] [바탕색]
//   방식  opaque  알파 없이 굽는다. iOS 앱 아이콘은 알파가 있으면 스토어가 거부한다.
//         alpha   투명 바탕을 살린다. 안드로이드 적응형 전경과 앱 안 로고에 쓴다.
//         mac     Apple 아이콘 격자(1024 안에 824, 반지름 185.4)로 깎는다.
//   비율  SVG 의 1024 상자가 캔버스에서 차지할 몫. 가운데에 놓는다. 기본 1.
//   바탕색 비율이 1 보다 작을 때 남는 자리를 채울 색(#rrggbb).
import AppKit
import ImageIO
import UniformTypeIdentifiers

let a = CommandLine.arguments
guard a.count >= 5, let px = Int(a[3]) else {
  fputs("usage: render <svg> <png> <px> <opaque|alpha|mac> [scale] [#bg]\n", stderr)
  exit(1)
}
let mode = a[4]
let scale = a.count >= 6 ? (Double(a[5]) ?? 1) : 1
let background = a.count >= 7 ? a[6] : nil

guard let img = NSImage(contentsOfFile: a[1]) else {
  fputs("svg 를 읽지 못했습니다: \(a[1])\n", stderr)
  exit(2)
}

func color(_ hex: String) -> NSColor {
  var v: UInt64 = 0
  Scanner(string: hex.replacingOccurrences(of: "#", with: "")).scanHexInt64(&v)
  return NSColor(
    srgbRed: CGFloat((v >> 16) & 0xff) / 255,
    green: CGFloat((v >> 8) & 0xff) / 255,
    blue: CGFloat(v & 0xff) / 255,
    alpha: 1
  )
}

let s = CGFloat(px)
let info = mode == "opaque"
  ? CGImageAlphaInfo.noneSkipLast.rawValue
  : CGImageAlphaInfo.premultipliedLast.rawValue
guard let cg = CGContext(
  data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
  space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: info
) else { exit(3) }
cg.interpolationQuality = .high
cg.clear(CGRect(x: 0, y: 0, width: s, height: s))

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: false)

let full = NSRect(x: 0, y: 0, width: s, height: s)
if let background {
  color(background).setFill()
  full.fill()
}

var rect = full.insetBy(dx: s * (1 - scale) / 2, dy: s * (1 - scale) / 2)
if mode == "mac" {
  let inset = rect.width * 100 / 1024
  rect = rect.insetBy(dx: inset, dy: inset)
  let r = rect.width * 185.4 / 824
  NSBezierPath(roundedRect: rect, xRadius: r, yRadius: r).addClip()
}
img.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
NSGraphicsContext.restoreGraphicsState()

guard
  let out = cg.makeImage(),
  let dest = CGImageDestinationCreateWithURL(
    URL(fileURLWithPath: a[2]) as CFURL, UTType.png.identifier as CFString, 1, nil)
else { exit(4) }
CGImageDestinationAddImage(dest, out, nil)
guard CGImageDestinationFinalize(dest) else { exit(5) }
