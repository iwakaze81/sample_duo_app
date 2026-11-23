import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:material_ui/material_ui.dart';

/// 画面を 1 ペインで使うか、2 ペインで使うか。
enum PaneMode { single, dual }

/// 折りたたみ端末 (iPhone Duo / Android foldable) 向けのレイアウト判定。
///
/// 判定の優先順:
///  1. `MediaQuery.displayFeaturesOf` に画面を左右に分断するヒンジ / 折り目
///     があれば、その位置でペインを分割する (現状 Android のみ値が入る)。
///  2. それ以外は画面幅で判定する。iPhone Duo の内側ディスプレイを開いた状態や
///     iPad、横向きのスマホでは幅が [dualPaneBreakpoint] を超えるので 2 ペインになる。
///
/// iOS の Flutter はまだヒンジ情報を返さないため、2 の幅ベース判定が
/// iPhone Duo での実質的な判定方法になる。
@immutable
class DuoLayout {
  const DuoLayout._({required this.mode, this.hinge});

  /// Material 3 の window size class で "medium" が始まる幅。
  static const double dualPaneBreakpoint = 600;

  final PaneMode mode;

  /// 画面を左右に分断している物理的なヒンジ / 折り目 (グローバル座標)。
  final Rect? hinge;

  bool get isDual => mode == PaneMode.dual;

  static DuoLayout of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final features = MediaQuery.displayFeaturesOf(context);

    final hinge = _findVerticalSeparator(features, size);
    if (hinge != null) {
      return DuoLayout._(mode: PaneMode.dual, hinge: hinge);
    }
    return DuoLayout._(
      mode: size.width >= dualPaneBreakpoint ? PaneMode.dual : PaneMode.single,
    );
  }

  /// 画面を上から下まで縦に貫き、左右に分割しているディスプレイ特性を探す。
  ///
  /// - hinge: 物理的に表示できない領域があるので常に分割扱い。
  /// - fold: 半開き (本のように持っている) 状態のときだけ分割扱い。
  ///   完全に開いてフラットな時は 1 枚の大画面として幅判定に任せる。
  static Rect? _findVerticalSeparator(
    List<DisplayFeature> features,
    Size size,
  ) {
    for (final f in features) {
      final separates = switch (f.type) {
        DisplayFeatureType.hinge => true,
        DisplayFeatureType.fold =>
          f.state == DisplayFeatureState.postureHalfOpened,
        _ => false,
      };
      if (!separates) continue;
      final b = f.bounds;
      final isVertical = b.top <= 0 && b.bottom >= size.height;
      final insideScreen = b.left > 0 && b.right < size.width;
      if (isVertical && insideScreen) return b;
    }
    return null;
  }
}

/// 2 ペインを左右に並べるウィジェット。
///
/// ヒンジがあればヒンジをまたがないように分割し、
/// なければ左ペインを固定幅寄り (40%, 320〜420px) にしたリスト/詳細レイアウトにする。
/// 画面全幅に置かれる前提 (ヒンジの座標がグローバル座標のため)。
class DualPane extends StatelessWidget {
  const DualPane({
    super.key,
    required this.layout,
    required this.start,
    required this.end,
  });

  final DuoLayout layout;
  final Widget start;
  final Widget end;

  @override
  Widget build(BuildContext context) {
    final hinge = layout.hinge;
    if (hinge != null) {
      return Row(
        children: [
          SizedBox(width: hinge.left, child: start),
          // ヒンジ部分には何も描かない (物理的に見えない / 折れている)
          SizedBox(width: hinge.width),
          Expanded(child: end),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final startWidth = (constraints.maxWidth * 0.4).clamp(320.0, 420.0);
        return Row(
          children: [
            SizedBox(width: startWidth, child: start),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: end),
          ],
        );
      },
    );
  }
}
