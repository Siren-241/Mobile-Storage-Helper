import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:storage_query_engine/models/media_file.dart';

Future<void> processPDFMetadata(MediaFile media) async {
  try {
    if (media.path == null) {
      final asset = await AssetEntity.fromId(media.assetId);
      final file = await asset?.file;
      media.path = file?.path;
    }
    if (media.path == null) throw Exception("Path is null"); // Requires path to be filled in before func call

    final bytes = await File(media.path!).readAsBytes();
    final doc = PdfDocument(inputBytes: bytes);

    final extractor = PdfTextExtractor(doc);
    final text = extractor.extractText();

    media.extractedText = text.length > 5000
        ? text.substring(0, 5000)
        : text;

    media.metadataProcessed = true;

    doc.dispose();
  } catch (e) {
    print("Metadata Enrichment Failed for ${media.fileName}: $e");
    media.metadataFailed = true;
  }
}