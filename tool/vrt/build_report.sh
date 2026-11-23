#!/usr/bin/env bash
# reg-actions のアーティファクト (reg) から、Pages に載せる reg-cli レポートを作る。
#
#   tool/vrt/build_report.sh <reg アーティファクトを展開したディレクトリ> <出力先> [--gallery]
#
# アーティファクトは PR のコードで作られたものなので、想定した名前の PNG だけを取り出し、
# HTML は main 側のこのスクリプトと reg-cli で生成し直す。
# --gallery を付けると比較せず、スクリーンショット一覧 (すべて NEW) にする。
set -euo pipefail

src="$1"
out="$2"
mode="${3:-}"
here="$(cd "$(dirname "$0")" && pwd)"

copy_pngs() {
  local from="$1" to="$2"
  mkdir -p "$to"
  [ -d "$from" ] || return 0
  find "$from" -maxdepth 1 -type f -name '*.png' -print0 |
    while IFS= read -r -d '' f; do
      name="$(basename "$f")"
      if [[ "$name" =~ ^[a-z0-9][a-z0-9_-]{0,80}\.png$ ]]; then
        cp "$f" "$to/$name"
      fi
    done
}

rm -rf "$out"
mkdir -p "$out"
copy_pngs "$src/1_actual" "$out/1_actual"
if [ "$mode" = "--gallery" ]; then
  mkdir -p "$out/2_expected"
else
  copy_pngs "$src/2_expected" "$out/2_expected"
fi

cd "$out"
# -M: 差分とみなす色の閾値 (reg-actions の matching-threshold と同じ値)
# -I: 差分があっても終了コード 0 にする (マージをブロックしない方針)
"$here/node_modules/.bin/reg-cli" 1_actual 2_expected 0_diff \
  -R index.html -J reg.json -M 0.1 -I
