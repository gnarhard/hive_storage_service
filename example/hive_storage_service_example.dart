import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_storage_service/hive_storage_service.dart';
import 'package:hive_storage_service/src/mock_hive_model.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Hive Storage Service App',
      home: MyHomePage(title: 'Hive Storage Service Home Page'),
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
  late final _storageService = GetIt.I<HiveStorageService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          ElevatedButton(
            key: Key('set-data-button'),
              onPressed: () async {
                await _storageService.set(
                    'test', MockHiveModel(name: 'test', id: 1));
              },
              child: Text('Set Data')),
          const SizedBox(height: 8),
          Center(child: Text('Hive Storage Service Example')),
          ElevatedButton(
            key: Key('wipe-data-button'),
              onPressed: () async {
                await _storageService.wipe();
              },
              child: Text('Wipe Data')),
        ],
      ),
    );
  }
}
