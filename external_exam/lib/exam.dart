import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Exam {
  final String id;
  final String courseCode;
  final DateTime date;
  final TimeOfDay time;
  final String venue;
  final String? documentPath;

  Exam({
    String? id,
    required this.courseCode,
    required this.date,
    required this.time,
    required this.venue,
    this.documentPath,
  }) : this.id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  DateTime get dateTime =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseCode': courseCode,
      'date': date.toIso8601String(),
      'time':
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'venue': venue,
      'documentPath': documentPath,
    };
  }

  factory Exam.fromJson(Map<String, dynamic> map) {
    final timeParts = (map['time'] as String).split(':');
    return Exam(
      id: map['id'] as String,
      courseCode: map['courseCode'] as String,
      date: DateTime.parse(map['date'] as String),
      time: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      venue: map['venue'] as String,
      documentPath: map['documentPath'] as String?,
    );
  }
}

class ExamStorage {
  static const String _storageKey = "exam_list";

  static Future<List<Exam>> readAllExams() async {
    final prefs = await SharedPreferences.getInstance();
    final String? examString = prefs.getString(_storageKey);
    if (examString == null) return [];
    final List<dynamic> jsonList = jsonDecode(examString);
    return jsonList.map((json) => Exam.fromJson(json)).toList();
  }

  static Future<void> _saveExams(List<Exam> exams) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList = exams
        .map((exam) => exam.toJson())
        .toList();
    final String examString = jsonEncode(jsonList);
    await prefs.setString(_storageKey, examString);
  }

  static Future<void> create(Exam exam) async {
    final List<Exam> exams = await readAllExams();
    exams.add(exam);
    await _saveExams(exams);
  }

  static Future<void> update(Exam updatedExam) async {
    final List<Exam> exams = await readAllExams();
    final int index = exams.indexWhere((exam) => exam.id == updatedExam.id);
    if (index != -1) {
      exams[index] = updatedExam;
      await _saveExams(exams);
    }
  }

  static Future<void> delete(String id) async {
    final List<Exam> exams = await readAllExams();
    exams.removeWhere((exam) => exam.id == id);
    await _saveExams(exams);
  }
}
