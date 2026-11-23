import 'package:material_ui/material_ui.dart';

import '../models/todo.dart';
import 'progress_card.dart';
import 'todo_tile.dart';

/// 左ペイン (1 ペイン時は画面全体) の一覧。
///
/// 状態は持たず、親 ([TodoHomePage]) から受け取った値を描画するだけ。
class TodoListPane extends StatelessWidget {
  const TodoListPane({
    super.key,
    required this.todos,
    required this.filter,
    required this.selectedId,
    required this.onFilterChanged,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
    required this.onAdd,
  });

  final List<Todo> todos;
  final TodoFilter filter;

  /// 2 ペイン時に選択中の行をハイライトするための ID。
  final String? selectedId;
  final ValueChanged<TodoFilter> onFilterChanged;
  final ValueChanged<Todo> onTap;
  final ValueChanged<Todo> onToggle;
  final ValueChanged<Todo> onDelete;
  final VoidCallback onAdd;

  /// 未完了 → 完了 の順。同じグループ内は元の並び順を保つ。
  List<Todo> get _visible {
    final indexed = todos.indexed.where((e) => filter.test(e.$2)).toList()
      ..sort((a, b) {
        if (a.$2.isDone != b.$2.isDone) return a.$2.isDone ? 1 : -1;
        return a.$1.compareTo(b.$1);
      });
    return [for (final e in indexed) e.$2];
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final done = todos.where((t) => t.isDone).length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(title: Text('ToDo')),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: ProgressCard(done: done, total: todos.length),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SegmentedButton<TodoFilter>(
                showSelectedIcon: false,
                segments: [
                  for (final f in TodoFilter.values)
                    ButtonSegment(
                      value: f,
                      label: Text('${f.label} ${todos.where(f.test).length}'),
                    ),
                ],
                selected: {filter},
                onSelectionChanged: (s) => onFilterChanged(s.first),
              ),
            ),
          ),
          if (visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyList(filter: filter),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 104),
              sliver: SliverList.separated(
                itemCount: visible.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final todo = visible[i];
                  return TodoTile(
                    key: ValueKey(todo.id),
                    todo: todo,
                    selected: todo.id == selectedId,
                    onTap: () => onTap(todo),
                    onToggle: () => onToggle(todo),
                    onDelete: () => onDelete(todo),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('追加'),
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.filter});

  final TodoFilter filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = switch (filter) {
      TodoFilter.all => 'まだタスクがありません\n「追加」から作成しましょう',
      TodoFilter.active => '未完了のタスクはありません',
      TodoFilter.done => '完了したタスクはありません',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 96),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 64,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge!
                .copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
