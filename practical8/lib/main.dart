import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Weather App using API'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // ...existing code...

  final List<String> cities = [
    'London',
    'New York',
    'Tokyo',
    'Paris',
    'Mumbai',
    'Beijing',
    'Moscow',
    'Sydney',
    'Dubai',
    'Los Angeles',
  ];

  Future<List<Map<String, dynamic>>> fetchWeatherForCities() async {
    const apiKey = '6024e7845da440478f5120834252109';
    List<Map<String, dynamic>> results = [];
    for (String city in cities) {
      final url = 'https://api.weatherapi.com/v1/current.json?key=$apiKey&q=$city';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        results.add(json.decode(response.body));
      } else {
        results.add({'error': 'Failed to load $city'});
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    // ...existing code...
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchWeatherForCities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final weatherList = snapshot.data!;
            return ListView.builder(
              itemCount: weatherList.length,
              itemBuilder: (context, index) {
                final weather = weatherList[index];
                if (weather.containsKey('error')) {
                  return ListTile(
                    title: Text(cities[index]),
                    subtitle: Text(weather['error']),
                  );
                }
                final location = weather['location'];
                final current = weather['current'];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text('${location['name']}, ${location['country']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Temp (°C): ${current['temp_c']}'),
                        Text('Condition: ${current['condition']['text']}'),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No data'));
          }
        },
      ),
    );
  }
}
