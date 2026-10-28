#!/usr/bin/env bash
# Thêm khai báo quyền ảnh/video vào AndroidManifest.xml và Info.plist sau khi
# chạy `flutter create`. Chạy nhiều lần vẫn an toàn (idempotent).
set -euo pipefail
cd "$(dirname "$0")/.."

MANIFEST=android/app/src/main/AndroidManifest.xml
PLIST=ios/Runner/Info.plist

if [ -f "$MANIFEST" ]; then
python3 - "$MANIFEST" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
perms = [
  '<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>',
  '<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>',
  '<uses-permission android:name="android.permission.READ_MEDIA_VISUAL_USER_SELECTED"/>',
  '<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>',
]
missing = [x for x in perms if x.split('"')[1] not in s]
if missing:
    block = ''.join('    ' + x + '\n' for x in missing)
    i = s.index('<application')
    s = s[:i] + block.lstrip(' ') + '    ' + s[i:]
    open(p, 'w', encoding='utf-8').write(s)
    print('Android: đã thêm', len(missing), 'quyền')
else:
    print('Android: đã đủ quyền')
PY
else
  echo "Không thấy $MANIFEST (chạy flutter create trước)"
fi

if [ -f "$PLIST" ]; then
python3 - "$PLIST" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
key = 'NSPhotoLibraryUsageDescription'
if key in s:
    print('iOS: đã có', key)
else:
    add = ('\t<key>NSPhotoLibraryUsageDescription</key>\n'
           '\t<string>Cleanify scans your photos and videos on your device to find duplicates and large files. Nothing is uploaded, and nothing is deleted without your confirmation.</string>\n')
    i = s.rindex('</dict>')
    s = s[:i] + add + s[i:]
    open(p, 'w', encoding='utf-8').write(s)
    print('iOS: đã thêm', key)
PY
else
  echo "Không thấy $PLIST (chạy flutter create trước)"
fi
