import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notice Board',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const NoticeBoardScreen(),
    );
  }
}

class Notice {
  String title;
  String description;
  String category;
  String? filePath;

  Notice({
    required this.title,
    required this.description,
    required this.category,
    this.filePath,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'category': category,
    'filePath': filePath,
  };

  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
    title: json['title'],
    description: json['description'],
    category: json['category'],
    filePath: json['filePath'],
  );
}

class NoticeBoardScreen extends StatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  final List<Notice> allNotices = [];
  List<Notice> filteredNotices = [];
  String currentFilter = "All";
  final List<String> categories = ['General', 'Exam', 'Event', 'Academic'];

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _saveNotices() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> noticesJson = allNotices
        .map((notice) => jsonEncode(notice.toJson()))
        .toList();
    await prefs.setStringList('notices_data', noticesJson);
  }

  Future<void> _loadNotices() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? noticesJson = prefs.getStringList('notices_data');
    if (noticesJson != null) {
      setState(() {
        allNotices.clear();
        allNotices.addAll(
          noticesJson.map((json) => Notice.fromJson(jsonDecode(json))),
        );
        _filterNotices(currentFilter);
      });
    }
  }

  void _updateNotice(Notice originalNotice, Notice updatedNotice) {
    final int index = allNotices.indexOf(originalNotice);
    if (index != -1) {
      setState(() {
        allNotices[index] = updatedNotice;
        _filterNotices(currentFilter);
      });
      _saveNotices();
    }
  }

  void _filterNotices(String category) {
    setState(() {
      currentFilter = category;
      if (category == "All") {
        filteredNotices = allNotices;
      } else {
        filteredNotices = allNotices
            .where((notice) => notice.category == category)
            .toList();
      }
    });
  }

  void _showAddNoticeDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = categories[0];
    String? pickedFilePath;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add New Notice"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: "Title"),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                      ),
                      maxLines: 3,
                    ),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: selectedCategory,
                      items: categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setDialogState(() {
                          selectedCategory = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.attach_file),
                      label: const Text("Attach File"),
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform
                            .pickFiles();
                        if (result != null) {
                          setDialogState(() {
                            pickedFilePath = result.files.single.path;
                          });
                        }
                      },
                    ),
                    if (pickedFilePath != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "File: ${p.basename(pickedFilePath!)}",
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text("Add"),
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      final newNotice = Notice(
                        title: titleController.text,
                        description: descriptionController.text,
                        category: selectedCategory,
                        filePath: pickedFilePath,
                      );

                      setState(() {
                        allNotices.add(newNotice);
                        _filterNotices(currentFilter);
                      });

                      _saveNotices();
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notice Board")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    categories.expand((cat) {
                      return [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ActionChip(
                            label: Text(cat),
                            onPressed: () => _filterNotices(cat),
                          ),
                        ),
                      ];
                    }).toList()..insert(
                      0,
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ActionChip(
                          label: const Text("All"),
                          onPressed: () => _filterNotices("All"),
                        ),
                      ),
                    ),
              ),
            ),
          ),
          Expanded(
            child: filteredNotices.isEmpty
                ? const Center(child: Text("No notices yet. Add one!"))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: filteredNotices.length,
                    itemBuilder: (context, index) {
                      final notice = filteredNotices[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            notice.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            notice.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () async {
                            final updatedNotice = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    NoticeDetailScreen(notice: notice),
                              ),
                            );
                            if (updatedNotice != null) {
                              _updateNotice(notice, updatedNotice);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoticeDialog,
        tooltip: 'Add Notice',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NoticeDetailScreen extends StatefulWidget {
  final Notice notice;

  const NoticeDetailScreen({super.key, required this.notice});

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  late Notice currentNotice;
  bool hasChanges = false;

  @override
  void initState() {
    super.initState();
    currentNotice = Notice.fromJson(widget.notice.toJson());
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        currentNotice.filePath = result.files.single.path;
        hasChanges = true;
      });
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Exam':
        return Colors.red.shade100;
      case 'Event':
        return Colors.green.shade100;
      case 'Academic':
        return Colors.orange.shade100;
      default:
        return Colors.blue.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentNotice.title),
        actions: [
          if (hasChanges)
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Save Changes',
              onPressed: () {
                Navigator.pop(context, currentNotice);
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Chip(
                label: Text(currentNotice.category),
                backgroundColor: _getCategoryColor(currentNotice.category),
              ),
              const SizedBox(height: 16),
              Text(
                currentNotice.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 24),
              Text(
                currentNotice.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              if (currentNotice.filePath != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.attachment),
                    label: Text("View: ${p.basename(currentNotice.filePath!)}"),
                    onPressed: () {
                      OpenFile.open(currentNotice.filePath);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Update Attachment"),
                  onPressed: _pickFile,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
