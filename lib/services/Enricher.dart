import 'package:isar/isar.dart';
import 'package:storage_query_engine/models/media_file.dart';

import 'DBEnrichment/MediaEnricher.dart';
import 'DBEnrichment/PDFEnricher.dart';

Future<void> enrichUnprocessedMedia({required Isar isar}) async {
  const batchSize = 20;
  int enriched = 0;

  while(true) {
    final unprocessed = await isar.mediaFiles
        .filter()
        .metadataProcessedEqualTo(false)
        .metadataFailedEqualTo(false)
        .limit(batchSize)
        .findAll();

    if (unprocessed.isEmpty) break;

    for (MediaFile media in unprocessed) {
      try {
        if (media.mimeType.startsWith("image") ||
            media.mimeType.startsWith("video")) {
          await processMediaMetadata(media);
          enriched++;
        } else if (media.mimeType == "application/pdf") {
          await processPDFMetadata(media);
          enriched++;
        }

        // Its stuck in an inf-loop
        print("Metadata processed for: ${media.fileName}");


        // TODO: Remove error handling from here
        // Error handling in individual enrichers
      } catch (e) {
        print("Metadata Processing failed for ${media.fileName}");
        print(e);
      }
    }

    await isar.writeTxn(() async {
      await isar.mediaFiles.putAll(unprocessed);
    });

    await Future.delayed(Duration(milliseconds: 100));
  }
  print("Enriched $enriched files");
}