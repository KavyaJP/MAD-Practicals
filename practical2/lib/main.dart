import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temperature Converter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const TemperatureConverterScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TemperatureConverterScreen extends StatefulWidget {
  const TemperatureConverterScreen({Key? key}) : super(key: key);

  @override
  State<TemperatureConverterScreen> createState() => _TemperatureConverterScreenState();
}

class _TemperatureConverterScreenState extends State<TemperatureConverterScreen> {
  final TextEditingController _controller = TextEditingController();
  String _selectedInput = 'Celsius';
  String _selectedOutput = 'Fahrenheit';
  String _result = '';

  void _convert() {
    double? input = double.tryParse(_controller.text);
    if (input == null) {
      setState(() {
        _result = 'Please enter a valid number.';
      });
      return;
    }
    double output = _convertTemperature(input, _selectedInput, _selectedOutput);
    setState(() {
      _result = '${output.toStringAsFixed(2)} $_selectedOutput';
    });
  }

  double _convertTemperature(double value, String from, String to) {
    if (from == to) return value;
    if (from == 'Celsius' && to == 'Fahrenheit') {
      return value * 9 / 5 + 32;
    } else if (from == 'Fahrenheit' && to == 'Celsius') {
      return (value - 32) * 5 / 9;
    } else if (from == 'Celsius' && to == 'Kelvin') {
      return value + 273.15;
    } else if (from == 'Kelvin' && to == 'Celsius') {
      return value - 273.15;
    } else if (from == 'Fahrenheit' && to == 'Kelvin') {
      return (value - 32) * 5 / 9 + 273.15;
    } else if (from == 'Kelvin' && to == 'Fahrenheit') {
      return (value - 273.15) * 9 / 5 + 32;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Temperature Converter')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter temperature',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DropdownButton<String>(
                  value: _selectedInput,
                  items: const [
                    DropdownMenuItem(value: 'Celsius', child: Text('Celsius')),
                    DropdownMenuItem(value: 'Fahrenheit', child: Text('Fahrenheit')),
                    DropdownMenuItem(value: 'Kelvin', child: Text('Kelvin')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedInput = value!;
                    });
                  },
                ),
                const Icon(Icons.arrow_forward),
                DropdownButton<String>(
                  value: _selectedOutput,
                  items: const [
                    DropdownMenuItem(value: 'Celsius', child: Text('Celsius')),
                    DropdownMenuItem(value: 'Fahrenheit', child: Text('Fahrenheit')),
                    DropdownMenuItem(value: 'Kelvin', child: Text('Kelvin')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedOutput = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _convert,
              child: const Text('Convert'),
            ),
            const SizedBox(height: 24),
            Text(
              _result,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
