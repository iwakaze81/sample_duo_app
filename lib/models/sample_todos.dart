import 'todo.dart';

/// 起動時に表示するサンプルデータ。
List<Todo> sampleTodos() {
  final today = DateTime.now();
  DateTime day(int offset) =>
      DateTime(today.year, today.month, today.day + offset);

  return [
    Todo.create(
      title: 'iPhone Duo の実機で開閉を確認する',
      note: '閉じた状態 → 開いた状態で、選択中の ToDo が引き継がれるか確認。',
      priority: Priority.high,
      dueDate: day(0),
    ),
    Todo.create(
      title: '2 ペインのレイアウトを調整',
      note: '左ペインは 320〜420px、右ペインは残り。',
      priority: Priority.medium,
      dueDate: day(2),
    ),
    Todo.create(
      title: '牛乳を買う',
      priority: Priority.low,
      dueDate: day(-1),
    ),
    Todo.create(
      title: 'Flutter の displayFeatures を調べる',
      priority: Priority.medium,
    ),
    Todo.create(title: 'README を書く', priority: Priority.low)
        .copyWith(isDone: true),
  ];
}
