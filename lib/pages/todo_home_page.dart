import 'package:material_ui/material_ui.dart';

import '../layout/duo_layout.dart';
import '../models/sample_todos.dart';
import '../models/todo.dart';
import '../widgets/add_todo_sheet.dart';
import '../widgets/todo_detail_pane.dart';
import '../widgets/todo_list_pane.dart';

/// アプリのルート画面。ToDo の状態はすべてこの `State` が持つ。
///
/// - 1 ペイン (iPhone Duo を閉じた状態 / 通常の iPhone):
///   一覧 → タップで詳細を push。
/// - 2 ペイン (iPhone Duo を開いた状態 / iPad / 横向き):
///   左に一覧、右に詳細を並べる。
///
/// 開く・閉じるでモードが切り替わっても、選択中の ToDo を引き継ぐ
/// (App Continuity)。
class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key, this.initialTodos});

  /// テスト用に初期データを差し替えられるようにしている。
  final List<Todo>? initialTodos;

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  late final List<Todo> _todos = [...widget.initialTodos ?? sampleTodos()];
  TodoFilter _filter = TodoFilter.all;
  String? _selectedId;

  /// 1 ペイン時に push している詳細画面。2 ペインに切り替わったら閉じる。
  Route<void>? _detailRoute;
  PaneMode? _lastMode;

  /// モードが変わっても一覧のスクロール位置などを保持するための GlobalKey。
  /// 一覧専用の ScaffoldMessenger にも使い、SnackBar を一覧側に出す。
  final _listKey = GlobalKey<ScaffoldMessengerState>();

  Todo? get _selected {
    for (final t in _todos) {
      if (t.id == _selectedId) return t;
    }
    return null;
  }

  // ---- 状態の更新 ---------------------------------------------------------

  void _update(Todo todo) {
    setState(() {
      final i = _todos.indexWhere((t) => t.id == todo.id);
      if (i >= 0) _todos[i] = todo;
    });
  }

  void _toggle(Todo todo) => _update(todo.copyWith(isDone: !todo.isDone));

  void _delete(Todo todo) {
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index < 0) return;
    setState(() {
      _todos.removeAt(index);
      if (_selectedId == todo.id) _selectedId = null;
    });
    _listKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('「${todo.title}」を削除しました'),
          action: SnackBarAction(
            label: '元に戻す',
            onPressed: () => setState(
              () => _todos.insert(index.clamp(0, _todos.length), todo),
            ),
          ),
        ),
      );
  }

  Future<void> _add() async {
    final todo = await showAddTodoSheet(context);
    if (todo == null || !mounted) return;
    setState(() {
      _todos.insert(0, todo);
      _filter = TodoFilter.all;
      // 2 ペインなら作ったものをそのまま右に表示する
      if (DuoLayout.of(context).isDual) _selectedId = todo.id;
    });
  }

  void _select(Todo todo, DuoLayout layout) {
    setState(() => _selectedId = todo.id);
    if (!layout.isDual) _pushDetail();
  }

  // ---- 1 ペイン時の画面遷移 -------------------------------------------------

  void _pushDetail() {
    if (_selected == null || _detailRoute != null) return;
    final route = MaterialPageRoute<void>(
      // builder は再ビルドのたびに呼ばれるので、毎回最新の値を参照する。
      builder: (_) {
        final todo = _selected;
        if (todo == null) return const SizedBox.shrink();
        return TodoDetailPane(
          key: ValueKey(todo.id),
          todo: todo,
          onChanged: _update,
          onDelete: () {
            Navigator.of(context).pop();
            _delete(todo);
          },
        );
      },
    );
    _detailRoute = route;
    Navigator.of(context).push(route).then((_) {
      // ユーザーが戻った場合だけ選択を解除する。
      // (2 ペインへの切り替えで閉じた場合は選択を保持)
      if (_detailRoute == route) {
        _detailRoute = null;
        if (mounted) setState(() => _selectedId = null);
      }
    });
  }

  /// 開閉などでレイアウトモードが変わったときの引き継ぎ処理。
  void _onModeChanged(PaneMode mode) {
    if (!mounted) return;
    switch (mode) {
      case PaneMode.dual:
        // 閉じた状態で詳細を見ていた → 開いたら右ペインに表示
        final route = _detailRoute;
        if (route != null) {
          _detailRoute = null;
          Navigator.of(context).removeRoute(route);
        }
      case PaneMode.single:
        // 開いた状態で選択していた → 閉じたら詳細画面として表示
        _pushDetail();
    }
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final layout = DuoLayout.of(context);
    if (_lastMode != null && _lastMode != layout.mode) {
      final mode = layout.mode;
      WidgetsBinding.instance.addPostFrameCallback((_) => _onModeChanged(mode));
    }
    _lastMode = layout.mode;

    final list = ScaffoldMessenger(
      key: _listKey,
      child: TodoListPane(
        todos: _todos,
        filter: _filter,
        selectedId: layout.isDual ? _selectedId : null,
        onFilterChanged: (f) => setState(() => _filter = f),
        onTap: (t) => _select(t, layout),
        onToggle: _toggle,
        onDelete: _delete,
        onAdd: _add,
      ),
    );

    if (!layout.isDual) return list;

    final selected = _selected;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: DualPane(
        layout: layout,
        start: list,
        end: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: selected == null
              ? const EmptyDetailPane()
              : TodoDetailPane(
                  key: ValueKey(selected.id),
                  todo: selected,
                  onChanged: _update,
                  onDelete: () => _delete(selected),
                ),
        ),
      ),
    );
  }
}
