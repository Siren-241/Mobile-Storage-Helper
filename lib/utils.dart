import 'package:flutter/material.dart';

IconData getIcon(String mime) {
  if (mime.startsWith("image")) return Icons.image;
  if (mime.startsWith("video")) return Icons.video_file;
  if (mime == "application/pdf") return Icons.picture_as_pdf;

  return Icons.insert_drive_file;
}

