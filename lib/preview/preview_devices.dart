import 'dart:ui' as ui;

import 'package:device_preview/device_preview.dart';
import 'package:device_preview/presets.dart';
import 'package:flutter/widgets.dart';

/// Web 版の端末プレビューで切り替えられる端末の一覧。
///
/// device_preview に iPhone Duo のプリセットはまだ無いため、
/// 開いた状態は 7.6 インチ内側ディスプレイを想定した近似値で定義している。
/// (実機の論理解像度が分かったら [_duoOpenSize] を差し替える)
class PreviewDevice {
  const PreviewDevice(this.key, this.label, this.preset, {this.group = ''});

  final String key;
  final String label;
  final String group;

  /// null の場合はシミュレーションを解除してブラウザの幅そのままで表示する。
  final DevicePreset? preset;
}

const _duoOpenSize = ui.Size(800, 980);

DevicePreset _duoOpen({required bool halfOpened}) => DevicePreset(
      id: halfOpened ? 'iphone-duo-open-book' : 'iphone-duo-open',
      name: halfOpened ? 'iPhone Duo (半開き・想定)' : 'iPhone Duo (開・想定)',
      brand: 'Apple',
      platform: TargetPlatform.iOS,
      portraitSize: _duoOpenSize,
      devicePixelRatio: 2.0,
      portraitPadding: const EdgeInsets.only(top: 32, bottom: 20),
      landscapePadding: const EdgeInsets.only(top: 24, bottom: 20),
      portraitKeyboardHeight: 360,
      landscapeKeyboardHeight: 400,
      kind: DeviceKind.foldable,
      displayFeatures: [
        SimulatedDisplayFeature(
          // 内側ディスプレイ中央の縦の折り目
          bounds: Rect.fromLTRB(
            _duoOpenSize.width / 2,
            0,
            _duoOpenSize.width / 2,
            _duoOpenSize.height,
          ),
          type: ui.DisplayFeatureType.fold,
          state: halfOpened
              ? ui.DisplayFeatureState.postureHalfOpened
              : ui.DisplayFeatureState.postureFlat,
        ),
      ],
    );

final previewDevices = <PreviewDevice>[
  const PreviewDevice(
    'duo-closed',
    'iPhone Duo 閉 (iPhone 17 相当)',
    DevicePresets.iPhone17,
    group: 'iPhone Duo',
  ),
  PreviewDevice(
    'duo-open',
    'iPhone Duo 開 (想定)',
    _duoOpen(halfOpened: false),
    group: 'iPhone Duo',
  ),
  PreviewDevice(
    'duo-book',
    'iPhone Duo 半開き (想定)',
    _duoOpen(halfOpened: true),
    group: 'iPhone Duo',
  ),
  const PreviewDevice('se3', 'iPhone SE (3rd)', DevicePresets.iPhoneSe3,
      group: 'iPhone'),
  const PreviewDevice(
    '17promax',
    'iPhone 17 Pro Max',
    DevicePresets.iPhone17ProMax,
    group: 'iPhone',
  ),
  const PreviewDevice('ipad-mini', 'iPad mini', DevicePresets.iPadMini,
      group: 'iPad'),
  const PreviewDevice(
    'zfold8',
    'Galaxy Z Fold8',
    DevicePresets.galaxyZFold8,
    group: 'Android 折りたたみ',
  ),
  const PreviewDevice(
    'pixelfold',
    'Pixel 10 Pro Fold',
    DevicePresets.pixel10ProFold,
    group: 'Android 折りたたみ',
  ),
  const PreviewDevice('off', 'ブラウザの幅 (プレビュー解除)', null, group: 'その他'),
];

const initialPreviewDeviceKey = 'duo-closed';

PreviewDevice? previewDeviceByKey(String key) {
  for (final d in previewDevices) {
    if (d.key == key) return d;
  }
  return null;
}

/// 端末を切り替える。回転・ダークモードの指定は維持する。
Future<void> applyPreviewDevice(
  String key, {
  Orientation orientation = Orientation.portrait,
  Brightness? brightness,
}) async {
  final controller = DevicePreview.maybeController;
  final device = previewDeviceByKey(key);
  if (controller == null || device == null) return;

  final preset = device.preset;
  if (preset == null) {
    await controller.reset();
  } else {
    await controller.applyPreset(preset, orientation: orientation);
  }
  if (brightness != null && preset != null) {
    await controller.update((s) => s.copyWith(platformBrightness: brightness));
  }
}
