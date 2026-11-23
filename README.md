# sample_duo_app

iPhone Duo (折りたたみ iPhone) に対応した Flutter の ToDo アプリ。
折りたたみ端末対応のプラクティス用サンプルです。

| 閉じた状態 (一覧) | 閉じた状態 (詳細) | 開いた状態 (2 ペイン) |
| --- | --- | --- |
| <img src="docs/screenshots/closed.png" width="200"> | <img src="docs/screenshots/closed_detail.png" width="200"> | <img src="docs/screenshots/open.png" width="420"> |

## 機能

- ToDo の追加 (ボトムシート) / 編集 / 完了切り替え / 削除 (スワイプ・元に戻す)
- 優先度・期限・メモ、期限切れの強調表示
- すべて / 未完了 / 完了 のフィルタと進捗表示
- ライト / ダークテーマ (Material 3)

## iPhone Duo 対応の考え方

`lib/layout/duo_layout.dart` にまとめています。

| 状態 | レイアウト |
| --- | --- |
| 閉じた状態 (外側ディスプレイ) / 通常の iPhone | 1 ペイン。一覧 → タップで詳細を push |
| 開いた状態 (内側ディスプレイ) / iPad / 横向き | 2 ペイン。左に一覧、右に詳細 |

1. **幅ベースで判定する** — 幅 600dp 以上で 2 ペイン (Material 3 の window size class)。
   2026 年 11 月時点で Flutter は iOS のヒンジ情報 (`MediaQuery.displayFeatures`) を返さないため、
   iPhone Duo ではこれが実質的な判定方法になります。
2. **ヒンジ情報があれば優先する** — Android の折りたたみ端末などで縦のヒンジ / 半開きの折り目が
   報告された場合は、その位置でペインを分割してヒンジをまたがないようにしています。
   将来 iOS でも値が入るようになればそのまま効きます。
3. **開閉で状態を引き継ぐ (App Continuity)** — `TodoHomePage` がモードの変化を検知し、
   - 閉じた状態で詳細を見ていた → 開くと詳細の route を閉じて右ペインに表示
   - 開いた状態で選択していた → 閉じると詳細画面を push
   一覧は `GlobalKey` でツリー上の位置が変わってもスクロール位置などを保持します。

## 状態管理

グローバルな状態管理ライブラリは使わず、`StatefulWidget` + `setState` のみ。
ToDo のリストと選択状態は `TodoHomePage` の `State` が持ち、子ウィジェットには値とコールバックを渡しています。

## 構成

```
lib/
  main.dart                    アプリのエントリーポイント
  app_theme.dart               テーマ (ライト / ダーク)
  layout/duo_layout.dart       1 / 2 ペイン判定と DualPane ウィジェット
  models/todo.dart             Todo モデル / Priority / TodoFilter
  models/sample_todos.dart     初期データ
  pages/todo_home_page.dart    状態を持つルート画面 (開閉時の引き継ぎもここ)
  widgets/                     一覧・詳細・追加シートなどの UI
  utils/date_format.dart       日本語の日付表示
test/todo_app_test.dart        1 / 2 ペイン、開閉の引き継ぎ、ヒンジ判定のテスト
```

## Web 版 (GitHub Pages) と端末プレビュー

Web 版は `.github/workflows/deploy-web.yml` で GitHub Pages にデプロイします
(`https://<user>.github.io/sample_duo_app/`)。

Web 版だけ [device_preview](https://pub.dev/packages/device_preview) を有効にしていて、
画面上部のツールバーから端末を切り替えてレスポンシブ表示を確認できます。

| 閉じた状態 (iPhone 17 相当) | 半開き (折り目で 2 ペインに分割) |
| --- | --- |
| <img src="docs/screenshots/web_preview_closed.png" width="420"> | <img src="docs/screenshots/web_preview_open.png" width="420"> |

- **開く / 閉じる**: iPhone Duo の開閉を切り替えます。アプリの状態は保たれたままなので、
  選択中の ToDo が引き継がれる様子をそのまま確認できます。
- **端末**: iPhone Duo (閉 / 開 / 半開き)、iPhone SE、iPhone 17 Pro Max、iPad mini、
  Galaxy Z Fold8、Pixel 10 Pro Fold、プレビュー解除 (ブラウザ幅)
- **横向き / ダーク**: 回転とダークモード

device_preview に iPhone Duo のプリセットはまだ無いため、開いた状態は 800×980 の
**想定サイズ**で定義しています (`lib/preview/preview_devices.dart`)。実機の値が分かったら差し替えてください。

仕組み:

- `lib/main.dart` で条件付き import を使い、Web のときだけ `lib/preview/web_preview_bridge.dart` を読み込みます。
  iOS / Android ではスタブが使われ、device_preview はビルドに含まれません。
- device_preview 3.x はアプリ内のツールバーが無く、操作 UI は DevTools 側にあります。Pages では DevTools を
  使えないため、`web/index.html` に HTML のツールバーを置き、JS 経由で `DevicePreview.controller` を操作しています。
- device_preview 3.0.0 は Flutter 3.50 の Web ビルドでコンパイルエラーになるため、
  1 メソッド追加したコピーを `third_party/device_preview` に置いて `dependency_overrides` で使っています
  (詳細は `third_party/device_preview/PATCHED.md`)。

### GitHub Pages の初回設定

リポジトリの **Settings → Pages → Build and deployment → Source** を **GitHub Actions** にしてください。
以降は `main` への push でデプロイされます (PR ではビルドとテストのみ)。

## 実行

```sh
flutter pub get
flutter run          # iPhone Duo シミュレータで開閉を切り替えて確認
flutter test
flutter run -d chrome   # Web 版 (端末プレビュー付き)
```

テストでは画面サイズを変えて「閉じた状態 (390×844)」と「開いた状態 (900×760)」を再現しています。
