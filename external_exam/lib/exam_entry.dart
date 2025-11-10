import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'exam.dart';

class ExamEntryScreen extends StatefulWidget {
  final Exam? exam;
  const ExamEntryScreen({super.key, this.exam});
  @override
  State<ExamEntryScreen> createState() => _ExamEntryScreenState();
}

class _ExamEntryScreenState extends State<ExamEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _courseCodeController;
  late TextEditingController _venueController;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _docPath;
  String? _docName;

  @override
  void initState() {
    super.initState();
    _courseCodeController = TextEditingController(
      text: widget.exam?.courseCode,
    );
    _venueController = TextEditingController(text: widget.exam?.venue);
    _selectedDate = widget.exam?.date;
    _selectedTime = widget.exam?.time;
    _docPath = widget.exam?.docPath;
    if (_docPath != null) {
      _docName = p.basename(_docPath!);
    }
  }

  @override
  void dispose() {
    _courseCodeController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  void _selectDate() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    ).then((pickedDate) {
      if (pickedDate != null && pickedDate != _selectedDate) {
        setState(() {
          _selectedDate = pickedDate;
        });
      }
    });
  }

  void _selectTime() {
    showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    ).then((pickedTime) {
      if (pickedTime != null && pickedTime != _selectedTime) {
        setState(() {
          _selectedTime = pickedTime;
        });
      }
    });
  }

  void _pickDocument() {
    FilePicker.platform.pickFiles().then((result) {
      if (result != null) {
        setState(() {
          _docPath = result.files.single.path;
          _docName = result.files.single.name;
        });
      }
    });
  }

  void _saveExam() {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedTime != null) {
      final exam = Exam(
        id: widget.exam?.id,
        courseCode: _courseCodeController.text,
        venue: _venueController.text,
        date: _selectedDate!,
        time: _selectedTime!,
        docPath: _docPath,
      );

      if (widget.exam == null) {
        ExamStorage.create(exam).then((_) {
          if (mounted) Navigator.of(context).pop();
        });
      } else {
        ExamStorage.update(exam).then((_) {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select date/time'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exam == null ? 'Add Exam' : 'Edit Exam'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _courseCodeController,
                decoration: const InputDecoration(labelText: 'Course Code'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter course code' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _venueController,
                decoration: const InputDecoration(labelText: 'Venue'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter venue' : null,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDate == null
                        ? 'No date chosen'
                        : DateFormat.yMMMd().format(_selectedDate!),
                  ),
                  TextButton(
                    onPressed: _selectDate,
                    child: const Text('Choose Date'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedTime == null
                        ? 'No time chosen'
                        : _selectedTime!.format(context),
                  ),
                  TextButton(
                    onPressed: _selectTime,
                    child: const Text('Choose Time'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickDocument,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Supporting Document'),
              ),
              if (_docName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Chip(
                    label: Text(_docName!),
                    onDeleted: () {
                      setState(() {
                        _docPath = null;
                        _docName = null;
                      });
                    },
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveExam,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Exam'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
