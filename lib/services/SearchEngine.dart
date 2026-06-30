import 'package:isar/isar.dart';
import 'package:storage_query_engine/models/media_item.dart';

class SearchEngine {
  final Isar isar;
  SearchEngine(this.isar);

  Future<List<MediaItem>> searchByText(String? text) async {
    var query = isar.mediaItems.filter();
    late List<MediaItem> results = [];

    if (text != null && text.isNotEmpty) {
      results = await query.group((query) => query
           .fileNameContains(text, caseSensitive: false)
           .or()
           .extractedTextContains(text, caseSensitive: false)
           .or()
           .albumNameContains(text, caseSensitive: false))
         .findAll();
    }

    return results;
  }

  Future<List<MediaItem>> searchByType(String? text) async {
    var query = isar.mediaItems.filter();
    late List<MediaItem> results = [];

    if (text != null && text.isNotEmpty) {
      results = await query.group((query) => query
          .mimeTypeContains(text, caseSensitive: false))
        .findAll();
    }

    return results;
  }

  Future<List<MediaItem>> searchByDate({
    DateTime? start,
    DateTime? end
  }) async {
    var query = isar.mediaItems.filter();
    late List<MediaItem> results = [];

    if (start != null && end != null) {
      results = await query.group((q) => q
          .createdAtLessThan(end)
          .and()
          .createdAtGreaterThan(start))
        .findAll();
    } else if (start != null ) {
      results = await query.group((q) => q
          .createdAtGreaterThan(start))
        .findAll();
    } else if (end != null) {
      results = await query.group((q) => q
          .createdAtLessThan(end))
        .findAll();
    }

    return results;
  }
}