import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'models/media_file.dart';
import 'services/MediaIndexer.dart';

late Isar isar;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  isar = await Isar.open(
    [MediaFileSchema],
    directory: dir.path,
    inspector: true
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return const MaterialApp(
      home: MediaCounterScreen(),
    );
  }
}

class MediaCounterScreen extends StatefulWidget {
  const MediaCounterScreen({super.key});

  @override
  State<MediaCounterScreen> createState() => _MediaCounterScreenState();
}

class _MediaCounterScreenState extends State<MediaCounterScreen> {
  int newlyIndexedMediaCount = 0;
  int totalInDB = 0;

  String status = "Requesting Permissions...";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _startIndexing();
  }

  Future<void> _startIndexing() async {
    final indexer = MediaIndexer(
        isar: isar,
        onStatusUpdate: (newStatus) {
          if (mounted) {
            setState(() {
              status = newStatus;
            });
          }
        }
    );

    // Refactor below names
    newlyIndexedMediaCount += await indexer.runFullIndex();

    final mediaCount = await isar.mediaFiles.count();

    if(mounted){
      setState(() {
        totalInDB = mediaCount;
        status = "Done";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Storage Helper")),
      body: Center (
        child: Text(
          status == "Done"
              ? "Indexed $newlyIndexedMediaCount more media\n$totalInDB media in DB"
              : status,

          style: const TextStyle(fontSize: 22),
          textAlign: TextAlign.center,
        )
      )
    );
  }
}
