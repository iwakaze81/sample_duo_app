import 'package:material_ui/material_ui.dart';

/// 優先度。色とラベルを持たせて UI 側の分岐を減らす。
enum Priority {
  low('低', Color(0xFF3FA796)),
  medium('中', Color(0xFFE0A030)),
  high('高', Color(0xFFE05A5A));

  const Priority(this.label, this.color);

  final String label;
  final Color color;
}

/// ToDo 1 件分のイミュータブルなモデル。
///
/// 更新は [copyWith] で新しいインスタンスを作る。
/// 状態は各画面の `State` が持ち、グローバルな状態管理は使わない。
@immutable
class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.createdAt,
    this.note = '',
    this.isDone = false,
    this.priority = Priority.medium,
    this.dueDate,
  });

  final String id;
  final String title;
  final String note;
  final bool isDone;
  final Priority priority;
  final DateTime? dueDate;
  final DateTime createdAt;

  static int _seq = 0;

  /// 新規作成用のファクトリ。ID は時刻 + 連番で一意にする。
  factory Todo.create({
    required String title,
    String note = '',
    Priority priority = Priority.medium,
    DateTime? dueDate,
  }) {
    final now = DateTime.now();
    return Todo(
      id: '${now.microsecondsSinceEpoch}-${_seq++}',
      title: title,
      note: note,
      priority: priority,
      dueDate: dueDate,
      createdAt: now,
    );
  }

  /// [dueDate] を null に戻したい場合は [clearDueDate] を true にする。
  Todo copyWith({
    String? title,
    String? note,
    bool? isDone,
    Priority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      isDone: isDone ?? this.isDone,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt,
    );
  }

  bool get isOverdue {
    final due = dueDate;
    if (due == null || isDone) return false;
    final today = DateUtils.dateOnly(DateTime.now());
    return due.isBefore(today);
  }

  @override
  bool operator ==(Object other) =>
      other is Todo &&
      other.id == id &&
      other.title == title &&
      other.note == note &&
      other.isDone == isDone &&
      other.priority == priority &&
      other.dueDate == dueDate &&
      other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(id, title, note, isDone, priority, dueDate, createdAt);
}

/// 一覧のフィルタ。
enum TodoFilter {
  all('すべて'),
  active('未完了'),
  done('完了');

  const TodoFilter(this.label);

  final String label;

  bool test(Todo todo) => switch (this) {
        TodoFilter.all => true,
        TodoFilter.active => !todo.isDone,
        TodoFilter.done => todo.isDone,
      };
}
