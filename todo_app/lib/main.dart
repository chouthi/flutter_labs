import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class Todo {
  String title;
  bool done;
  Todo({required this.title, this.done = false});

  Map<String, dynamic> toJson() => {'title': title, 'done': done};
  factory Todo.fromJson(Map<String, dynamic> json) =>
      Todo(title: json['title'] as String, done: json['done'] as bool);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TodoHomePage(),
    );
  }
}

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  final List<Todo> _todos = [];
  final TextEditingController _controller = TextEditingController();
  late SharedPreferences _prefs;
  static const String _storageKey = 'todos_v1';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_storageKey);
    if (raw != null) {
      final List<dynamic> list = jsonDecode(raw);
      _todos.clear();
      _todos.addAll(list.map((e) => Todo.fromJson(e as Map<String, dynamic>)));
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> _saveTodos() async {
    final raw = jsonEncode(_todos.map((t) => t.toJson()).toList());
    await _prefs.setString(_storageKey, raw);
  }

  void _addTodo(String title) {
    if (title.trim().isEmpty) return;
    setState(() {
      _todos.insert(0, Todo(title: title.trim()));
      _controller.clear();
    });
    _saveTodos();
  }

  void _toggleDone(int index) {
    setState(() {
      _todos[index].done = !_todos[index].done;
    });
    _saveTodos();
  }

  void _deleteTodo(int index) {
    setState(() {
      _todos.removeAt(index);
    });
    _saveTodos();
  }

  Future<void> _showAddDialog() async {
    _controller.clear();
    await showDialog(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text('Add task'),
            content: TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Enter task'),
              onSubmitted: (v) {
                Navigator.of(c).pop();
                _addTodo(v);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(c).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(c).pop();
                  _addTodo(_controller.text);
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear completed',
            onPressed: () {
              setState(() {
                _todos.removeWhere((t) => t.done);
              });
              _saveTodos();
            },
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _todos.isEmpty
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No tasks yet'),
                    const SizedBox(height: 12),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _todos.length,
                itemBuilder: (context, index) {
                  final todo = _todos[index];
                  return Dismissible(
                    key: ValueKey(todo.title + index.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => _deleteTodo(index),
                    child: ListTile(
                      leading: Checkbox(
                        value: todo.done,
                        onChanged: (_) => _toggleDone(index),
                      ),
                      title: Text(
                        todo.title,
                        style: TextStyle(
                          decoration:
                              todo.done ? TextDecoration.lineThrough : null,
                          color: todo.done ? Colors.grey : null,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteTodo(index),
                      ),
                      onTap: () => _toggleDone(index),
                    ),
                  );
                },
              ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: 12,
            top: 6,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Add task',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onSubmitted: (v) => _addTodo(v),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _addTodo(_controller.text),
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
