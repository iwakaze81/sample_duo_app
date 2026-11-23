// Web 専用。index.html のツールバー (Flutter の外側の HTML) と
// DevicePreview.controller をつなぐ JS ブリッジ。
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/widgets.dart';

import 'preview_devices.dart';

@JS('duoPreviewReady')
external JSFunction? get _readyCallback;

/// `window.duoPreviewReady(api)` を呼び、HTML 側に操作用の API を渡す。
///
/// api:
/// - devices: `[{key, label, group}]` の JSON 文字列
/// - setDevice(key), setOrientation('portrait'|'landscape'),
///   setDark(bool)
void installWebPreviewBridge() {
  // GitHub Pages はリリースビルドなので、明示的に enabled: true にする
  // (省略すると !kReleaseMode になり無効化される)。
  DevicePreview.enable(enabled: true, padding: const EdgeInsets.all(24));

  var deviceKey = initialPreviewDeviceKey;
  var orientation = Orientation.portrait;
  Brightness? brightness;

  Future<void> apply() => applyPreviewDevice(
        deviceKey,
        orientation: orientation,
        brightness: brightness,
      );

  apply();

  final api = JSObject()
    ..['devices'] = jsonEncode([
      for (final d in previewDevices)
        {'key': d.key, 'label': d.label, 'group': d.group},
    ]).toJS
    ..['initialDevice'] = initialPreviewDeviceKey.toJS
    ..['setDevice'] = ((JSString key) {
      deviceKey = key.toDart;
      apply();
    }).toJS
    ..['setOrientation'] = ((JSString value) {
      orientation = value.toDart == 'landscape'
          ? Orientation.landscape
          : Orientation.portrait;
      apply();
    }).toJS
    ..['setDark'] = ((JSBoolean dark) {
      brightness = dark.toDart ? Brightness.dark : Brightness.light;
      apply();
    }).toJS;

  _readyCallback?.callAsFunction(null, api);
}
