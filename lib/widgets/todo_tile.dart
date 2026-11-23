import 'package:material_ui/material_ui.dart';

import '../models/todo.dart';
import '../utils/date_format.dart';

/// 一覧の 1 行。スワイプで削除、タップで詳細、丸チェックで完了切り替え。
class TodoTile extends StatelessWidget {
  const TodoTile({
    super.key,
    required this.todo,
    required this.selected,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  final Todo todo;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Dismissible(
      key: ValueKey('dismiss-${todo.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      child: Card(
        color: selected ? scheme.primaryContainer : null,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
            child: Row(
              children: [
                CheckCircle(
                  checked: todo.isDone,
                  color: todo.priority.color,
                  onTap: onToggle,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: theme.textTheme.titleMedium!.copyWith(
                          decoration:
                              todo.isDone ? TextDecoration.lineThrough : null,
                          color: todo.isDone
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                        ),
                        child: Text(
                          todo.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _MetaRow(todo: todo),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.todo});

  final Todo todo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.textTheme.labelMedium!
        .copyWith(color: scheme.onSurfaceVariant);
    final due = todo.dueDate;

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: todo.priority.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text('優先度 ${todo.priority.label}', style: style),
          ],
        ),
        if (due != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_outlined,
                size: 14,
                color: todo.isOverdue ? scheme.error : style.color,
              ),
              const SizedBox(width: 2),
              Text(
                formatDate(due),
                style: todo.isOverdue
                    ? style.copyWith(color: scheme.error)
                    : style,
              ),
            ],
          ),
        if (todo.note.isNotEmpty)
          Icon(Icons.notes, size: 14, color: style.color),
      ],
    );
  }
}

/// アニメーション付きの丸いチェックボックス。
class CheckCircle extends StatelessWidget {
  const CheckCircle({
    super.key,
    required this.checked,
    required this.color,
    required this.onTap,
    this.size = 26,
  });

  final bool checked;
  final Color color;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: checked ? '未完了に戻す' : '完了にする',
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: checked ? color : Colors.transparent,
          border: Border.all(color: color, width: 2),
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: checked ? 1 : 0,
          child: Icon(Icons.check, size: size * 0.65, color: Colors.white),
        ),
      ),
    );
  }
}
