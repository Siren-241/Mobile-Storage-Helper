import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'grid_builder.dart';
import 'models/media_file.dart';
import 'services/MediaIndexer.dart';

import 'package:storage_query_engine/list_builder.dart';
import 'package:storage_query_engine/services/Enricher.dart';
import 'package:storage_query_engine/services/SearchEngine.dart';

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


enum ViewMode { list, grid }

class _MediaCounterScreenState extends State<MediaCounterScreen> {
  int newlyIndexedMediaCount = 0;
  int totalInDB = 0;

  String status = "Requesting Permissions...";

  TextEditingController controller = TextEditingController();

  ViewMode viewMode = ViewMode.grid;

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

  void _smartSearch() async {
    final query = controller.text;

    if (query.isEmpty) return;

    // Type detection
    if (query.contains("pdf")) {
      setState(() {
        searchFuture = searchEngine.searchByType("application/pdf");
      });
      return;
    }

    // Year detection
    final yearMatch = RegExp(r'\b(20\d{2})\b').firstMatch(query);
    if (yearMatch != null) {
      final year = int.parse(yearMatch.group(0)!);
      setState(() {
        searchFuture = searchEngine.searchByDate(
          start: DateTime(year, 1, 1),
          end: DateTime(year, 12, 31),
        );
      });
      return;
    }

    // Default text search
    setState(() {
      searchFuture = searchEngine.searchByText(query);
    });
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Storage Helper"),
        elevation: 4,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              viewMode == ViewMode.list
                  ? Icons.grid_view
                  : Icons.list
            ),
            onPressed: () {
              setState(() {
                viewMode = viewMode == ViewMode.list
                    ? ViewMode.grid
                    : ViewMode.list;
              });
            },
          )
        ],
      ),
      body: Center (
        child: Column (
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.only(top: 12), // TODO: This is a hardcoded value, fix before release
                          hintText: "Search your files...",
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _smartSearch(),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                      onPressed: () async {
                        _smartSearch();
                      },
                      child: Text("Search")
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<MediaFile>> (
                future: searchFuture,
                builder: (context, snapshot) {

                  // TODO: Make buildPlaceholderList and buildPlaceholderGrid members of the builders
                  // Loading state
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView.builder(
                      itemCount: 6,
                      itemBuilder: (_, _) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white54,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 10,
                              color: Colors.black.withValues(alpha: 0.05),
                            )
                          ],
                        ),
                        child: SizedBox(height: 41,),
                      ),
                    );
                  }

                  // Error state
                  if (snapshot.hasError) {
                    return Text(snapshot.error.toString());
                  }

                  // Empty data state
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text("No results"));
                  }

                  final results = snapshot.data!;

                  return viewMode == ViewMode.list
                    ? buildList(results)
                    : buildGrid(results);
                },
              ),
            ),
          ],
        )
      )
    );
  }
}
