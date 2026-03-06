import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:storage_query_engine/services/Enricher.dart';
import 'package:storage_query_engine/services/SearchEngine.dart';

import 'models/media_file.dart';
import 'services/MediaIndexer.dart';

late Isar isar;
late SearchEngine searchEngine;
Future<List<MediaFile>>? searchFuture;

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

    if (mounted) {
      setState(() {
        totalInDB = mediaCount;
        status = "Enriching Metadata...";
      });
    }

    await _startBackgroundEnrichment();

    if (mounted) {
      setState(() {
        status = "Done";
      });
    }
  }

  Future<void> _startBackgroundEnrichment() async {
    final count = await isar.mediaFiles
        .filter()
        .metadataProcessedEqualTo(false)
        .count();
    if (count == 0) return;

    await enrichUnprocessedMedia(isar: isar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Storage Helper")),
      body: Center (
        child: Column (
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () async {
                  // for (final asset in results){
                  //   print(asset.fileName);
                  //   print(asset.path);
                  //   print("\n");
                  // }

                  setState(() {
                    searchFuture = searchEngine.searchByText("VIT");
                  });
                }
                , child: Text("Search")
            ),
            TextField(
              onSubmitted: (value) {
                setState(() {
                  // searchFuture = searchEngine.searchByText(value);
                });
              },
            ),
            (status != "Done")
                ?
            Text(
              "Indexed $newlyIndexedMediaCount more media\n$totalInDB media in DB",
              style: const TextStyle(fontSize: 22),
              textAlign: TextAlign.center,
            )
                :
            Expanded(
              child: FutureBuilder<List<MediaFile>> (
                future: searchFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text(snapshot.error.toString());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text("No results"));
                  }

                  final results = snapshot.data!;

                  return ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(results[index].fileName),
                        subtitle: Text(results[index].path ?? ""),
                      );
                    },
                  );
                },
              ),
            ),
            // ListView.builder(
            //     itemCount: searchResults.length,
            //     itemBuilder: (context, index) {
            //       final media = searchResults[index];
            //
            //       return ListTile(
            //         title: Text(media.fileName),
            //         subtitle: Text(media.path ?? ""),
            //       );
            //     }
            // ),
          ],
        )
      )
    );
  }
}
