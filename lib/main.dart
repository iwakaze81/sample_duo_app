import 'package:material_ui/material_ui.dart';

import 'app_theme.dart';
import 'models/todo.dart';
import 'pages/todo_home_page.dart';
import 'preview/web_preview_bridge_stub.dart'
    if (dart.library.js_interop) 'preview/web_preview_bridge.dart';

void main() {
  // Web 版のみ device_preview を有効にして、端末サイズを切り替えて確認できるようにする。
  // iOS / Android ではスタブが読み込まれるので何も起きない。
  installWebPreviewBridge();
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key, this.initialTodos});

  /// テスト / VRT 用に初期データを差し替えられるようにしている。
  final List<Todo>? initialTodos;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Duo ToDo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: TodoHomePage(initialTodos: initialTodos),
    );
  }
}
