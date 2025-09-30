import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const StudentApp());
}

class Student {
  final int? id;
  final String name;
  final String rollNo;
  final int age;
  final String course;

  Student({
    this.id,
    required this.name,
    required this.rollNo,
    required this.age,
    required this.course,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'rollNo': rollNo,
    'age': age,
    'course': course,
  };

  factory Student.fromMap(Map<String, Object?> map) => Student(
    id: map['id'] as int?,
    name: map['name'] as String? ?? '',
    rollNo: map['rollNo'] as String? ?? '',
    age: (map['age'] is int)
        ? map['age'] as int
        : int.tryParse(map['age'].toString()) ?? 0,
    course: map['course'] as String? ?? '',
  );
}

class StudentApp extends StatelessWidget {
  const StudentApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Records',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const StudentListPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});
  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  late Future<Database> _dbFuture;
  List<Student> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _dbFuture = _initDb();
    _refresh();
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'students_simple.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE students (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            rollNo TEXT NOT NULL UNIQUE,
            age INTEGER NOT NULL,
            course TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final db = await _dbFuture;
    final maps = await db.query('students', orderBy: 'id DESC');
    setState(() {
      _students = maps.map((m) => Student.fromMap(m)).toList();
      _loading = false;
    });
  }

  Future<void> _delete(int id) async {
    final db = await _dbFuture;
    await db.delete('students', where: 'id = ?', whereArgs: [id]);
    _refresh();
  }

  Future<void> _deleteAll() async {
    final db = await _dbFuture;
    await db.delete('students');
    _refresh();
  }

  Future<void> _addOrEdit({Student? student}) async {
    final result = await showDialog<Student>(
      context: context,
      builder: (ctx) => StudentFormDialog(student: student),
    );
    if (result != null) {
      try {
        final db = await _dbFuture;
        if (student == null) {
          await db.insert('students', result.toMap());
        } else {
          await db.update(
            'students',
            result.toMap()..remove('id'),
            where: 'id = ?',
            whereArgs: [student.id],
          );
        }
        _refresh();
      } on DatabaseException catch (e) {
        if (mounted && e.isUniqueConstraintError()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This Roll No already exists.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Delete all',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete all records?'),
                  content: const Text('This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true) _deleteAll();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
          ? const Center(child: Text('No records yet. Tap + to add a student.'))
          : ListView.separated(
              itemCount: _students.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final s = _students[index];
                return Dismissible(
                  key: ValueKey(s.id ?? s.rollNo),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete student?'),
                        content: Text('Delete ${s.name} (${s.rollNo})?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) => _delete(s.id!),
                  child: ListTile(
                    title: Text('${s.name}  •  ${s.course}'),
                    subtitle: Text('Roll: ${s.rollNo}   Age: ${s.age}'),
                    onTap: () => _addOrEdit(student: s),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _addOrEdit(student: s),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}

class StudentFormDialog extends StatefulWidget {
  final Student? student;
  const StudentFormDialog({super.key, this.student});
  @override
  State<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _rollCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _courseCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.student?.name ?? '');
    _rollCtrl = TextEditingController(text: widget.student?.rollNo ?? '');
    _ageCtrl = TextEditingController(
      text: widget.student?.age.toString() ?? '',
    );
    _courseCtrl = TextEditingController(text: widget.student?.course ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rollCtrl.dispose();
    _ageCtrl.dispose();
    _courseCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final age = int.tryParse(_ageCtrl.text.trim()) ?? 0;
      final data = Student(
        id: widget.student?.id,
        name: _nameCtrl.text.trim(),
        rollNo: _rollCtrl.text.trim(),
        age: age,
        course: _courseCtrl.text.trim(),
      );
      Navigator.of(context).pop(data);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.student != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Student' : 'Add Student'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _rollCtrl,
                decoration: const InputDecoration(labelText: 'Roll No'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Roll No is required'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ageCtrl,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Age is required';
                  final n = int.tryParse(v.trim());
                  if (n == null) return 'Enter a valid number';
                  if (n < 0) return 'Age cannot be negative';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _courseCtrl,
                decoration: const InputDecoration(labelText: 'Course'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Course is required'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(isEdit ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}
