// VRT (Visual Regression Test) 用のスクリーンショット生成。
//
// `flutter test test_vrt` で test_vrt/screenshots/*.png を書き出す。
// 比較はしない (比較とレポートは tool/vrt/compare.mjs が行う)。
//
// 日本語フォントは環境変数 VRT_CJK_FONT のパスから読み込む。
// CI では fonts-noto-cjk の NotoSansCJK を使う。
import 'dart:io';
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_duo_app/app_theme.dart';
import 'package:sample_duo_app/main.dart';
import 'package:sample_duo_app/models/todo.dart';

/// 端末ごとの論理サイズと安全領域。
class VrtDevice {
  const VrtDevice(this.name, this.size, {this.padding = EdgeInsets.zero});

  final String name;
  final Size size;
  final EdgeInsets padding;
}

const phone = VrtDevice(
  'phone',
  Size(402, 874), // iPhone 17 相当 (iPhone Duo を閉じた状態)
  padding: EdgeInsets.only(top: 62, bottom: 34),
);
const duoOpen = VrtDevice(
  'duo-open',
  Size(800, 980), // iPhone Duo を開いた状態 (想定サイズ)
  padding: EdgeInsets.only(top: 32, bottom: 20),
);
const tabletLandscape = VrtDevice(
  'tablet-landscape',
  Size(1180, 820),
  padding: EdgeInsets.only(top: 24, bottom: 20),
);

const _pixelRatio = 2.0;

/// 日付が変わっても画像が変わらないよう、期限は 昨日 / 今日 / 明日 だけにする。
List<Todo> fixtures() {
  final now = DateTime.now();
  DateTime day(int offset) => DateTime(now.year, now.month, now.day + offset);
  return [
    Todo.create(
      title: 'iPhone Duo の実機で開閉を確認する',
      note: '閉じた状態 → 開いた状態で、選択中の ToDo が引き継がれるか確認。',
      priority: Priority.high,
      dueDate: day(0),
    ),
    Todo.create(
      title: '2 ペインのレイアウトを調整',
      priority: Priority.medium,
      dueDate: day(1),
    ),
    Todo.create(title: '牛乳を買う', priority: Priority.low, dueDate: day(-1)),
    Todo.create(title: 'displayFeatures を調べる'),
    Todo.create(title: 'README を書く', priority: Priority.low)
        .copyWith(isDone: true),
  ];
}

Future<void> _loadFont(String family, Iterable<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

/// テスト環境の既定フォント (Ahem: 文字が四角になる) を実フォントに差し替える。
Future<void> loadFonts() async {
  // flutter_tester は <flutter>/bin/cache/artifacts/engine/<platform>/ にある
  final artifacts = File(Platform.resolvedExecutable).parent.parent.parent;
  final materialFonts = '${artifacts.path}/material_fonts';

  final cjk = Platform.environment['VRT_CJK_FONT'];
  await _loadFont('Roboto', [
    for (final w in ['Regular', 'Medium', 'Bold'])
      '$materialFonts/Roboto-$w.ttf',
  ]);
  // AppTheme.fontFamilyFallback のすべての名前に同じフォントを登録する。
  // テスト環境では未登録のファミリー名が Ahem (四角い文字) に解決されてしまうため。
  if (cjk != null && cjk.isNotEmpty) {
    for (final family in AppTheme.fontFamilyFallback) {
      await _loadFont(family, [cjk]);
    }
  }
  await _loadFont('MaterialIcons', ['$materialFonts/MaterialIcons-Regular.otf']);
}

Future<void> pumpScreen(
  WidgetTester tester,
  VrtDevice device, {
  Brightness brightness = Brightness.light,
  List<DisplayFeature> displayFeatures = const [],
}) async {
  tester.view
    ..devicePixelRatio = _pixelRatio
    ..physicalSize = device.size * _pixelRatio
    ..padding = FakeViewPadding(
      top: device.padding.top * _pixelRatio,
      bottom: device.padding.bottom * _pixelRatio,
    )
    ..displayFeatures = displayFeatures;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  // flutter_test は影を黒い枠線で描く設定なので、実機に近い影に戻す
  debugDisableShadows = false;
  addTearDown(() => debugDisableShadows = true);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

  await tester.pumpWidget(TodoApp(initialTodos: fixtures()));
  await tester.pumpAndSettle();
}

Future<void> snap(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(TodoApp),
    matchesGoldenFile('screenshots/$name.png'),
  );
}

void main() {
  // 常に書き出すだけ (比較は別ツール)
  autoUpdateGoldenFiles = true;

  setUpAll(loadFonts);

  group('phone (閉じた状態)', () {
    testWidgets('一覧', (tester) async {
      await pumpScreen(tester, phone);
      await snap(tester, 'phone-list');
    });

    testWidgets('詳細', (tester) async {
      await pumpScreen(tester, phone);
      await tester.tap(find.text('iPhone Duo の実機で開閉を確認する'));
      await snap(tester, 'phone-detail');
    });

    testWidgets('追加シート', (tester) async {
      await pumpScreen(tester, phone);
      await tester.tap(find.text('追加'));
      await snap(tester, 'phone-add-sheet');
    });

    testWidgets('一覧 (ダーク)', (tester) async {
      await pumpScreen(tester, phone, brightness: Brightness.dark);
      await snap(tester, 'phone-list-dark');
    });
  });

  group('duo-open (開いた状態)', () {
    testWidgets('未選択', (tester) async {
      await pumpScreen(tester, duoOpen);
      await snap(tester, 'duo-open-empty');
    });

    testWidgets('詳細', (tester) async {
      await pumpScreen(tester, duoOpen);
      await tester.tap(find.text('iPhone Duo の実機で開閉を確認する'));
      await snap(tester, 'duo-open-detail');
    });

    testWidgets('半開き (折り目で分割)', (tester) async {
      await pumpScreen(
        tester,
        duoOpen,
        displayFeatures: [
          DisplayFeature(
            bounds: Rect.fromLTRB(
              duoOpen.size.width / 2 * _pixelRatio,
              0,
              duoOpen.size.width / 2 * _pixelRatio,
              duoOpen.size.height * _pixelRatio,
            ),
            type: DisplayFeatureType.fold,
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ],
      );
      await tester.tap(find.text('牛乳を買う'));
      await snap(tester, 'duo-half-open-detail');
    });

    testWidgets('詳細 (ダーク)', (tester) async {
      await pumpScreen(tester, duoOpen, brightness: Brightness.dark);
      await tester.tap(find.text('2 ペインのレイアウトを調整'));
      await snap(tester, 'duo-open-detail-dark');
    });
  });

  testWidgets('tablet-landscape 詳細', (tester) async {
    await pumpScreen(tester, tabletLandscape);
    await tester.tap(find.text('2 ペインのレイアウトを調整'));
    await snap(tester, 'tablet-landscape-detail');
  });
}
