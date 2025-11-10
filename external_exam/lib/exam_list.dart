import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'exam.dart';
import 'exam_entry.dart';

class ExamListScreen extends StatefulWidget {
  const ExamListScreen({super.key});

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  List<Exam> _exams = [];
  List<Exam> _filteredExams = [];
  Exam? _nextExam;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshExams();
    _searchController.addListener(_filterExams);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshExams() {
    setState(() => _isLoading = true);

    ExamStorage.readAllExams().then((data) {
      final now = DateTime.now();

      data.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      Exam? foundNextExam;
      for (var exam in data) {
        if (exam.dateTime.isAfter(now)) {
          foundNextExam = exam;
          break;
        }
      }

      setState(() {
        _exams = data;
        _nextExam = foundNextExam;
        _filterExams();
        _isLoading = false;
      });
    });
  }

  void _filterExams() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredExams = _exams
          .where((exam) => exam.courseCode.toLowerCase().contains(query))
          .toList();
    });
  }

  void _navigateAndRefresh(BuildContext context, {Exam? exam}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExamEntryScreen(exam: exam)),
    ).then((_) {
      _refreshExams();
    });
  }

  Widget _buildCountdownCard() {
    if (_nextExam == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final difference = _nextExam!.date
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    String countdownText;

    if (difference == 0) {
      countdownText = "Today";
    } else if (difference == 1) {
      countdownText = "in 1 day";
    } else {
      countdownText = "in $difference days";
    }

    return Card(
      color: Colors.indigo.shade700,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Next Exam $countdownText: ${_nextExam!.courseCode}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Schedule')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  _buildCountdownCard(),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search by Course Code',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12.0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _filteredExams.isEmpty
                        ? const Center(child: Text('No exams found.'))
                        : ListView.builder(
                            itemCount: _filteredExams.length,
                            itemBuilder: (context, index) {
                              final exam = _filteredExams[index];
                              final isNextExam = exam.id == _nextExam?.id;
                              return Card(
                                color: isNextExam
                                    ? Colors.indigo.withOpacity(0.3)
                                    : null,
                                child: ListTile(
                                  title: Text(
                                    exam.courseCode,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${DateFormat.yMMMd().format(exam.date)} at ${exam.time.format(context)}\nVenue: ${exam.venue}',
                                  ),
                                  isThreeLine: true,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (exam.documentPath != null &&
                                          exam.documentPath!.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.attach_file,
                                            color: Colors.blueAccent,
                                          ),
                                          onPressed: () =>
                                              OpenFile.open(exam.documentPath),
                                        ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () => _navigateAndRefresh(
                                          context,
                                          exam: exam,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () {
                                          ExamStorage.delete(exam.id).then((_) {
                                            _refreshExams();
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateAndRefresh(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
