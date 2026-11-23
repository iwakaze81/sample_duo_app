import 'package:material_ui/material_ui.dart';

import '../models/todo.dart';
import '../utils/date_format.dart';
import 'todo_tile.dart';

/// 右ペイン (1 ペイン時は push される画面) の詳細・編集画面。
///
/// 編集中のテキストは自分の `State` で保持し、変更のたびに [onChanged] で
/// 親へ通知する。親が持つ値が正 (single source of truth)。
class TodoDetailPane extends StatefulWidget {
  const TodoDetailPane({
    super.key,
    required this.todo,
    required this.onChanged,
    required this.onDelete,
  });

  final Todo todo;
  final ValueChanged<Todo> onChanged;
  final VoidCallback onDelete;

  @override
  State<TodoDetailPane> createState() => _TodoDetailPaneState();
}

class _TodoDetailPaneState extends State<TodoDetailPane> {
  late Todo _todo = widget.todo;
  late final _titleController = TextEditingController(text: _todo.title);
  late final _noteController = TextEditingController(text: _todo.note);

  @override
  void didUpdateWidget(TodoDetailPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 一覧側でチェックされた等、外から値が変わった場合に同期する。
    if (widget.todo != _todo) {
      _todo = widget.todo;
      if (_titleController.text != _todo.title) {
        _titleController.text = _todo.title;
      }
      if (_noteController.text != _todo.note) {
        _noteController.text = _todo.note;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _update(Todo next) {
    setState(() => _todo = next);
    widget.onChanged(next);
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _todo.dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) _update(_todo.copyWith(dueDate: picked));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final due = _todo.dueDate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('詳細'),
        actions: [
          IconButton(
            tooltip: '削除',
            icon: const Icon(Icons.delete_outline),
            onPressed: widget.onDelete,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: CheckCircle(
                      checked: _todo.isDone,
                      color: _todo.priority.color,
                      size: 30,
                      onTap: () =>
                          _update(_todo.copyWith(isDone: !_todo.isDone)),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      style: theme.textTheme.headlineSmall,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'タイトル',
                        filled: false,
                        border: InputBorder.none,
                      ),
                      onChanged: (v) => _update(_todo.copyWith(title: v)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionLabel('優先度'),
              SegmentedButton<Priority>(
                showSelectedIcon: false,
                segments: [
                  for (final p in Priority.values)
                    ButtonSegment(
                      value: p,
                      label: Text(p.label),
                      icon: Icon(Icons.circle, size: 12, color: p.color),
                    ),
                ],
                selected: {_todo.priority},
                onSelectionChanged: (s) =>
                    _update(_todo.copyWith(priority: s.first)),
              ),
              const SizedBox(height: 24),
              const _SectionLabel('期限'),
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: Icon(
                    Icons.event_outlined,
                    color: _todo.isOverdue ? scheme.error : null,
                  ),
                  title: Text(
                    due == null ? '未設定' : formatDate(due),
                    style: _todo.isOverdue
                        ? TextStyle(color: scheme.error)
                        : null,
                  ),
                  trailing: due == null
                      ? const Icon(Icons.chevron_right)
                      : IconButton(
                          tooltip: '期限をクリア',
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              _update(_todo.copyWith(clearDueDate: true)),
                        ),
                  onTap: _pickDueDate,
                ),
              ),
              const SizedBox(height: 24),
              const _SectionLabel('メモ'),
              TextField(
                controller: _noteController,
                minLines: 4,
                maxLines: null,
                decoration: const InputDecoration(hintText: 'メモを追加'),
                onChanged: (v) => _update(_todo.copyWith(note: v)),
              ),
              const SizedBox(height: 32),
              FilledButton.tonalIcon(
                onPressed: () =>
                    _update(_todo.copyWith(isDone: !_todo.isDone)),
                icon: Icon(_todo.isDone ? Icons.undo : Icons.check),
                label: Text(_todo.isDone ? '未完了に戻す' : '完了にする'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '作成日: ${formatDate(_todo.createdAt)}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall!
                    .copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.labelLarge!
            .copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// 2 ペイン時、何も選択されていない右ペイン。
class EmptyDetailPane extends StatelessWidget {
  const EmptyDetailPane({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.checklist_rtl,
                size: 48,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text('ToDo を選択してください', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '左の一覧から選ぶと、ここに詳細が表示されます',
              style: theme.textTheme.bodyMedium!
                  .copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
