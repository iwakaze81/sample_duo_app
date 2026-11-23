import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_duo_app/app_theme.dart';
import 'package:sample_duo_app/layout/duo_layout.dart';
import 'package:sample_duo_app/models/todo.dart';
import 'package:sample_duo_app/pages/todo_home_page.dart';
import 'package:sample_duo_app/widgets/todo_detail_pane.dart';

/// iPhone を閉じた状態 (通常の iPhone 相当) の論理サイズ。
const closedSize = Size(390, 844);

/// iPhone Duo の内側ディスプレイを開いた状態を想定した論理サイズ。
const openSize = Size(900, 760);

List<Todo> fixtures() => [
      Todo.create(title: '買い物', priority: Priority.low),
      Todo.create(title: '資料作成', priority: Priority.high),
      Todo.create(title: '掃除').copyWith(isDone: true),
    ];

Future<void> pumpApp(WidgetTester tester, Size size) async {
  setSize(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: TodoHomePage(initialTodos: fixtures()),
    ),
  );
  await tester.pumpAndSettle();
}

void setSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

void main() {
  group('1 ペイン (閉じた状態)', () {
    testWidgets('タップで詳細画面へ push し、戻ると一覧に戻る', (tester) async {
      await pumpApp(tester, closedSize);

      expect(find.byType(EmptyDetailPane), findsNothing);
      expect(find.text('詳細'), findsNothing);

      await tester.tap(find.text('資料作成'));
      await tester.pumpAndSettle();
      expect(find.text('詳細'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('詳細'), findsNothing);
    });

    testWidgets('詳細での編集が一覧に反映される', (tester) async {
      await pumpApp(tester, closedSize);

      await tester.tap(find.text('買い物'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, '買い物'), '買い物に行く');
      await tester.tap(find.text('完了にする'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('買い物に行く'), findsOneWidget);
      expect(find.text('2 / 3'), findsOneWidget);
    });
  });

  group('2 ペイン (開いた状態)', () {
    testWidgets('一覧と詳細を左右に表示する', (tester) async {
      await pumpApp(tester, openSize);

      expect(find.byType(EmptyDetailPane), findsOneWidget);

      await tester.tap(find.text('資料作成'));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyDetailPane), findsNothing);
      expect(find.text('詳細'), findsOneWidget);
      // push されていないので戻るボタンはない
      expect(find.byType(BackButton), findsNothing);
      // 詳細は画面の右側にある
      expect(tester.getTopLeft(find.text('詳細')).dx, greaterThan(320));
    });

    testWidgets('一覧のチェックが詳細にも反映される', (tester) async {
      await pumpApp(tester, openSize);

      await tester.tap(find.text('買い物'));
      await tester.pumpAndSettle();
      expect(find.text('完了にする'), findsOneWidget);

      await tester.tap(find.byTooltip('完了にする').first);
      await tester.pumpAndSettle();
      expect(find.text('未完了に戻す'), findsOneWidget);
    });

    testWidgets('削除して元に戻せる', (tester) async {
      await pumpApp(tester, openSize);

      await tester.tap(find.text('資料作成'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('削除'));
      await tester.pumpAndSettle();

      expect(find.text('資料作成'), findsNothing);
      expect(find.byType(EmptyDetailPane), findsOneWidget);

      await tester.tap(find.text('元に戻す'));
      await tester.pumpAndSettle();
      expect(find.text('資料作成'), findsOneWidget);
    });
  });

  group('開閉時の引き継ぎ (App Continuity)', () {
    testWidgets('閉 → 開: push した詳細が右ペインに移る', (tester) async {
      await pumpApp(tester, closedSize);
      await tester.tap(find.text('資料作成'));
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsOneWidget);

      setSize(tester, openSize);
      await tester.pumpAndSettle();

      expect(find.text('詳細'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      expect(find.byType(EmptyDetailPane), findsNothing);
      expect(find.text('買い物'), findsOneWidget); // 一覧も見えている
    });

    testWidgets('開 → 閉: 選択中の詳細が push される', (tester) async {
      await pumpApp(tester, openSize);
      await tester.tap(find.text('資料作成'));
      await tester.pumpAndSettle();

      setSize(tester, closedSize);
      await tester.pumpAndSettle();

      expect(find.text('詳細'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('詳細'), findsNothing);
    });
  });

  testWidgets('ボトムシートから追加できる', (tester) async {
    await pumpApp(tester, closedSize);

    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '新しいタスク A');
    await tester.pump();
    await tester.tap(find.text('追加する'));
    await tester.pumpAndSettle();

    expect(find.text('新しいタスク A'), findsOneWidget);
    expect(find.text('1 / 4'), findsOneWidget);
  });

  group('DuoLayout', () {
    Future<DuoLayout> layoutFor(
      WidgetTester tester, {
      required Size size,
      List<DisplayFeature> features = const [],
    }) async {
      late DuoLayout result;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size, displayFeatures: features),
          child: Builder(
            builder: (context) {
              result = DuoLayout.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      return result;
    }

    testWidgets('幅で 1 / 2 ペインを切り替える', (tester) async {
      expect((await layoutFor(tester, size: closedSize)).mode, PaneMode.single);
      expect((await layoutFor(tester, size: openSize)).mode, PaneMode.dual);
    });

    testWidgets('縦のヒンジがあれば狭くても 2 ペインにしてヒンジで分割', (tester) async {
      const hinge = Rect.fromLTWH(270, 0, 20, 720);
      final layout = await layoutFor(
        tester,
        size: const Size(560, 720),
        features: const [
          DisplayFeature(
            bounds: hinge,
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.postureFlat,
          ),
        ],
      );
      expect(layout.mode, PaneMode.dual);
      expect(layout.hinge, hinge);
    });

    testWidgets('フラットな折り目は分割扱いしない', (tester) async {
      final layout = await layoutFor(
        tester,
        size: openSize,
        features: const [
          DisplayFeature(
            bounds: Rect.fromLTWH(450, 0, 0, 760),
            type: DisplayFeatureType.fold,
            state: DisplayFeatureState.postureFlat,
          ),
        ],
      );
      expect(layout.mode, PaneMode.dual);
      expect(layout.hinge, isNull);
    });
  });
}
