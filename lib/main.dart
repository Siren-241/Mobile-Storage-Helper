import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:storage_query_engine/services/Enricher.dart';
import 'package:storage_query_engine/services/SearchEngine.dart';
import 'package:open_filex/open_filex.dart';

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
  searchEngine = SearchEngine(isar);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return const MaterialApp(
      home: MediaCounterScreen(),
      debugShowCheckedModeBanner: false,
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

  TextEditingController controller = TextEditingController();

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

  Icon _getIcon(String mime) {
    if (mime.startsWith("image")) return Icon(Icons.image);
    if (mime.startsWith("video")) return Icon(Icons.video_file);
    if (mime == "application/pdf") return Icon(Icons.picture_as_pdf);

    return Icon(Icons.insert_drive_file);
  }

  void _performSearch() {
    final query = controller.text;
    if (query.isEmpty) return;
    setState(() {
      searchFuture = searchEngine.searchByText(query);
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Storage Helper"),
        elevation: 4,

      ),
      body: Center (
        child: Column (
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
              child: Column(
                children: [
                  TextField(
                    onSubmitted: (value) {
                      _performSearch();
                    },
                    controller: controller,
                    decoration: InputDecoration(
                      hint: Text("Search for media"),
                      prefixIcon: Icon(Icons.search)
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                      onPressed: () async {
                        _performSearch();
                      },
                      child: Text("Search")
                  ),
                ],
              ),
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
                      final file = results[index];
                      return ListTile(
                        leading: _getIcon(file.mimeType),

                        title: Text(file.fileName),

                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(file.mimeType),
                            Text("Created at: ${file.createdAt.toString()}"),
                          ],
                        ),

                        onTap: () async {
                          if (file.path != null){
                            await OpenFilex.open(file.path!);
                          }
                        },
                      );

                    },
                  );
                },
              ),
            ),
          ],
        )
      )
    );
  }
}
