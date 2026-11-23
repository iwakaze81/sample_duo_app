# device_preview 3.0.0 (patched)

pub.dev の `device_preview` 3.0.0 をそのままコピーし、以下だけ変更しています。

- `lib/src/binding/preview_platform_dispatcher.dart` に
  `resetInternalState()` の委譲を追加 (Flutter 3.50 の Web ビルドでコンパイルエラーになるため)
- サイズ削減のため `doc/`, `example/`, `test/`, `tool/`, `extension/` (DevTools 拡張) を削除

上流で修正版がリリースされたら、`pubspec.yaml` の `dependency_overrides` と
このディレクトリを削除してください。ライセンスは同梱の LICENSE (MIT) のとおりです。
