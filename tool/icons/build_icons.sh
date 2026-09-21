#!/usr/bin/env bash
# 디자인 SVG(design/icon)에서 모든 플랫폼의 아이콘을 다시 굽는다.
#
#   tool/icons/build_icons.sh
#
# macOS 14 이상과 Xcode 명령줄 도구(swiftc)가 필요하다. 아이콘을 고치면
# design/icon 의 SVG 를 바꾸고 이것만 다시 돌리면 된다.
set -euo pipefail
cd "$(dirname "$0")/../.."

SRC=design/icon
LIGHT=$SRC/HIScore-icon-light.svg
DARK=$SRC/HIScore-icon-dark.svg
MARK=$SRC/HIScore-mark.svg
PAPER='#f7f8fb'

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
swiftc -O tool/icons/render.swift -o "$WORK/render"
R="$WORK/render"

# ---- iOS ----------------------------------------------------------------
# 알파 없이 굽는다. 파일 이름과 크기는 Contents.json 을 그대로 따른다.
IOS=ios/Runner/Assets.xcassets/AppIcon.appiconset
python3 - "$IOS/Contents.json" > "$WORK/ios.txt" <<'PY'
import json, sys
seen = {}
for im in json.load(open(sys.argv[1]))['images']:
    if 'filename' in im:
        w = float(im['size'].split('x')[0])
        seen[im['filename']] = round(w * int(im['scale'][0]))
for name, px in seen.items():
    print(px, name)
PY
while read -r px name; do
  "$R" "$LIGHT" "$IOS/$name" "$px" opaque
done < "$WORK/ios.txt"

# ---- Android ------------------------------------------------------------
# 옛 런처에는 네모 한 장을, 8.0 이상에는 바탕과 전경을 나눈 적응형을 준다.
# 적응형이 없으면 요즘 런처는 네모 아이콘을 흰 원 안에 작게 줄여 넣는다.
RES=android/app/src/main/res

# 바탕은 오선만 남긴 종이다. 음표 무리를 걷어 낸다.
python3 - "$LIGHT" "$WORK/paper.svg" <<'PY'
import re, sys
svg = open(sys.argv[1], encoding='utf-8').read()
svg = re.sub(r'<g fill="url\(#gLight\)">.*?</g>', '', svg, flags=re.S)
open(sys.argv[2], 'w', encoding='utf-8').write(svg)
PY

# 적응형 108dp 가운데 72dp 가 보인다. 오선은 그 72dp 를 덮고, 음표는 마스크가
# 원이어도 잘리지 않게 안전 원(지름 66dp) 안에 넣는다. 음표에서 가장 먼 점은
# 오른쪽 깃발 끝인데, 0.574(=62dp) 로 줄이면 중심에서 31.8dp 다.
for spec in mdpi:48:108 hdpi:72:162 xhdpi:96:216 xxhdpi:144:324 xxxhdpi:192:432; do
  IFS=: read -r density legacy layer <<< "$spec"
  dir="$RES/mipmap-$density"
  mkdir -p "$dir"
  "$R" "$LIGHT" "$dir/ic_launcher.png" "$legacy" opaque
  "$R" "$WORK/paper.svg" "$dir/ic_launcher_background.png" "$layer" opaque 0.6667 "$PAPER"
  "$R" "$MARK" "$dir/ic_launcher_foreground.png" "$layer" alpha 0.574
done
mkdir -p "$RES/mipmap-anydpi-v26"
cat > "$RES/mipmap-anydpi-v26/ic_launcher.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
XML

# ---- macOS --------------------------------------------------------------
# 맥은 앱이 스스로 모서리를 깎아 온다. Apple 격자대로 깎는다.
MAC=macos/Runner/Assets.xcassets/AppIcon.appiconset
for px in 16 32 64 128 256 512 1024; do
  "$R" "$LIGHT" "$MAC/app_icon_$px.png" "$px" mac
done

# ---- Windows ------------------------------------------------------------
# 크기 여럿을 PNG 그대로 담은 .ico. Vista 이후로 모두 읽는다.
for px in 16 24 32 48 64 128 256; do
  "$R" "$LIGHT" "$WORK/win_$px.png" "$px" opaque
done
python3 - "$WORK" windows/runner/resources/app_icon.ico <<'PY'
import pathlib, struct, sys
work = pathlib.Path(sys.argv[1])
sizes = [16, 24, 32, 48, 64, 128, 256]
blobs = [(s, (work / f'win_{s}.png').read_bytes()) for s in sizes]
# 머리말 6바이트, 항목 16바이트씩, 그 뒤에 PNG. 256 은 한 바이트에 안 들어가 0 으로 적는다.
out = struct.pack('<HHH', 0, 1, len(blobs))
offset = 6 + 16 * len(blobs)
for s, data in blobs:
    out += struct.pack('<BBBBHHII', s % 256, s % 256, 0, 0, 1, 32, len(data), offset)
    offset += len(data)
for _, data in blobs:
    out += data
pathlib.Path(sys.argv[2]).write_bytes(out)
PY

# ---- 앱 안 ---------------------------------------------------------------
# 좌측 레일 로고. 테마에 맞춰 밝은 판과 어두운 판을 고른다.
mkdir -p assets/icon
"$R" "$LIGHT" assets/icon/hiscore.png 256 opaque
"$R" "$DARK" assets/icon/hiscore_dark.png 256 opaque

echo "아이콘을 다시 구웠습니다."
