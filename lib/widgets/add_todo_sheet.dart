import 'package:material_ui/material_ui.dart';

import '../models/todo.dart';
import '../utils/date_format.dart';

/// 新規作成のボトムシートを開き、作成された [Todo] を返す (キャンセル時は null)。
///
/// 2 ペイン時に横いっぱいに広がらないよう maxWidth を指定している。
Future<Todo?> showAddTodoSheet(BuildContext context) {
  return showModalBottomSheet<Todo>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => const _AddTodoSheet(),
  );
}

class _AddTodoSheet extends StatefulWidget {
  const _AddTodoSheet();

  @override
  State<_AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<_AddTodoSheet> {
  final _controller = TextEditingController();
  Priority _priority = Priority.medium;
  DateTime? _dueDate;

  bool get _canSubmit => _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_canSubmit) return;
    Navigator.of(context).pop(
      Todo.create(
        title: _controller.text.trim(),
        priority: _priority,
        dueDate: _dueDate,
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final due = _dueDate;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('新しいタスク', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: '何をしますか?'),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in Priority.values)
                ChoiceChip(
                  avatar: Icon(Icons.circle, size: 12, color: p.color),
                  label: Text('優先度 ${p.label}'),
                  selected: p == _priority,
                  onSelected: (_) => setState(() => _priority = p),
                ),
              InputChip(
                avatar: const Icon(Icons.event_outlined, size: 18),
                label: Text(due == null ? '期限' : formatDate(due)),
                selected: due != null,
                showCheckmark: false,
                onPressed: _pickDate,
                onDeleted:
                    due == null ? null : () => setState(() => _dueDate = null),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _canSubmit ? _submit : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('追加する'),
          ),
        ],
      ),
    );
  }
}
