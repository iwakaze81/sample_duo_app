import 'package:material_ui/material_ui.dart';

import '../utils/date_format.dart';

/// 一覧上部の進捗サマリー。
class ProgressCard extends StatelessWidget {
  const ProgressCard({super.key, required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ratio = total == 0 ? 0.0 : done / total;
    final remaining = total - done;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatDate(DateTime.now()),
            style: theme.textTheme.labelLarge!
                .copyWith(color: scheme.onPrimary.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 4),
          Text(
            total == 0
                ? 'タスクはありません'
                : remaining == 0
                    ? 'すべて完了しました 🎉'
                    : 'あと $remaining 件',
            style: theme.textTheme.headlineSmall!.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: ratio),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      color: scheme.onPrimary,
                      backgroundColor: scheme.onPrimary.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$done / $total',
                style: theme.textTheme.labelLarge!
                    .copyWith(color: scheme.onPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
