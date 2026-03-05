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
    String text = '';

    final pageCount = doc.pages.count;

    if (pageCount > 999) {
      throw Exception("File too large to parse"); // Fix this in future
    }

    final maxPages = pageCount > 3 ? 3 : pageCount;
    for (int i = 0; i < maxPages; i++) {
      text += extractor.extractText(startPageIndex: i, endPageIndex: i);
    }

    media.extractedText = text.substring(0, 5000);
    // Research apache pdfbox to optimize extraction

    media.metadataProcessed = true;

    doc.dispose();

    await Future.delayed(Duration(milliseconds: 50));
  } catch (e) {
    print("Metadata Enrichment Failed for ${media.fileName}: $e");
    media.metadataFailed = true;
  }
}