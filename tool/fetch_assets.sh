#!/usr/bin/env bash
# Tải icon (SVG) và ảnh minh họa từ Figma vào assets/.
# URL do Figma MCP cấp, HẾT HẠN SAU 7 NGÀY kể từ 2026-10-28.
# Nếu lỗi 403/404: nhờ Claude lấy lại URL mới.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p assets/icons assets/images

B="https://www.figma.com/api/mcp/asset"
dl() { echo "-> $1"; curl -fsSL --retry 2 -o "$1" "$B/$2"; test -s "$1"; }

# Ảnh minh họa onboarding
dl assets/images/onboarding_1.png cfbe110d-e925-4744-92ac-6c594c20858e.png
dl assets/images/onboarding_2.png 9b5338e5-f848-433c-b0a4-cb43cf6355d3.png
dl assets/images/onboarding_3.png bf78ae7d-4de5-4239-b35c-5a1f23d19592.png

# Icon
dl assets/icons/brand_glyph.svg   d3557bec-c48e-42ad-8233-914a4ec43f37.svg
dl assets/icons/arrow_right.svg   b79b78aa-a7cb-4d9d-bff2-34d359abc8b3.svg
dl assets/icons/brand_mark.svg    af784f3a-627c-4efe-b164-57cdf158cb8c.svg
dl assets/icons/chevron_left.svg  0a536f7e-b0ba-4c7a-a366-43fc2de40964.svg
dl assets/icons/mail.svg          40e1498e-de95-4933-8ae5-06c7961fb665.svg
dl assets/icons/lock_keyhole.svg  50735cec-8516-43f2-9e79-5bb02260f652.svg
dl assets/icons/eye.svg           531c61e8-2426-4127-8a7c-fce92cba2dc9.svg
dl assets/icons/google_logo.svg   6706343f-614d-41f0-af1d-b83edb3c7d44.svg
dl assets/icons/apple_logo.svg    140d640d-b7e7-48d6-bb9a-67056eb6a112.svg
dl assets/icons/shield_check.svg  3c525460-eac6-49b3-bbdd-5e243c439f21.svg
dl assets/icons/user_round.svg    f67d9536-73a9-4070-98f2-f968103e0d45.svg
dl assets/icons/key_round.svg     9421d7c5-54ce-4d06-8148-8c97168d5e85.svg
dl assets/icons/info.svg          67fb80c9-a429-41bc-b45a-a02dec84f1d6.svg
dl assets/icons/mail_check.svg    79552028-d20e-4e3a-8d51-baafa4b0a72c.svg

# Lô 1: quyền ảnh/video
dl assets/icons/images.svg       79852da5-4bc6-489e-ac7f-d337b91d3c54.svg
dl assets/icons/image_off.svg    c20fb282-d417-49b3-b893-66a8e0707b71.svg
dl assets/icons/scan_line.svg    5b0a5fb3-a1b7-42de-bd43-a66098d0041c.svg
dl assets/icons/circle_check.svg 5522d28c-fd72-4f89-9cb9-793c3c906993.svg
dl assets/icons/plus.svg         e6514fb3-3b5a-4891-9ec7-b473c44f6864.svg
dl assets/icons/settings.svg     8a68aaf0-9a91-4787-881f-cd707db98e4d.svg

# Lô 2: Home và luồng quét
dl assets/icons/bell.svg           cef2daeb-15cb-4d1d-bb49-0e22134c00c0.svg
dl assets/icons/chevron_right.svg  2289cb92-c587-4099-95b3-81f507f72192.svg
dl assets/icons/image.svg          b6982585-d7b2-4d80-8b0f-1de5d9d441a4.svg
dl assets/icons/more_horizontal.svg f029b0b0-62ad-4030-85f2-de48fde5c390.svg
dl assets/icons/file_text.svg      15af3d20-ada4-4397-aad0-9e7b6c03ca84.svg
dl assets/icons/layers.svg         c088c938-7c75-4ae6-b7a6-73203ac3a6b9.svg
dl assets/icons/database.svg       216c14e4-5eb0-4ea2-8a2c-666b60c2854c.svg
dl assets/icons/home.svg           778a6ac7-596f-44a1-bd49-7c4dd65e0211.svg
dl assets/icons/search.svg         238234e0-ebb6-475f-8d0d-817c45d27d40.svg
dl assets/icons/clapperboard.svg   b96c009e-1c50-4abe-8052-02b81bab8d87.svg
dl assets/icons/download.svg       e4eb6289-dd6d-488e-9566-8ee62bbc497d.svg
dl assets/icons/check_white.svg    3ba7b242-7856-433b-a5c5-68a3a0ee56b7.svg
dl assets/icons/broom.svg          7ffcff00-ed92-4f56-bf14-922034e0ca33.svg
dl assets/icons/warning.svg        7977b2c9-50b1-45d5-bcc0-e3a0ff953e37.svg
dl assets/icons/check.svg          05496ad3-73f3-411b-b75a-3205221f36c2.svg

# Lô 3: màn Access your files (URL hết hạn 2026-11-04)
dl assets/icons/folder.svg b862163f-e52b-4e15-b179-376f5d65ea22.svg


# Lô 4: Home (hết hạn ~2026-11-04; các file này thay bản vẽ tạm cùng tên)
dl assets/icons/bell.svg            666967ce-83c7-4238-8ad0-66872027955d.svg
dl assets/icons/chevron_right.svg   1f1821a2-9289-445a-a9a5-ca968f109d7d.svg
dl assets/icons/search.svg          6f5a838b-32b9-4d13-b076-98008a9449fa.svg
dl assets/icons/image.svg           056ae557-4fe0-4683-bfb1-a5c97677e55a.svg
dl assets/icons/more_horizontal.svg bb56dc07-0f06-4758-8506-3614e3f552df.svg
dl assets/icons/file_text.svg       fbe18f3d-77b7-4a70-949a-583687bde101.svg
dl assets/icons/layers.svg          44ef3de7-d0ef-4c22-ac56-7c711279b42e.svg
dl assets/icons/database.svg        e256a49d-c601-4da5-956d-b4b78b46f863.svg
dl assets/icons/home.svg            b9e46862-d959-4745-a2e7-0f29e525c604.svg

echo "Xong: $(ls assets/icons | grep -c svg) icon, $(ls assets/images | grep -c png) ảnh."
