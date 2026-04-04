import 'package:flutter/material.dart';
import 'models/media_file.dart';

class FileCard extends StatelessWidget {
  final MediaFile file;

  const FileCard({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withValues(alpha: 0.05),
          )
        ],
      ),
      child: Row(
        children: [
          _buildLeading(),
          const SizedBox(width: 12),
          Expanded(child: _buildText()),
        ],
      ),
    );
  }

  Widget _buildText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          file.fileName,
          style: TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4),
        Text(
          file.createdAt.toString() ?? "",
          style: TextStyle(color: Colors.grey, fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildLeading() {
    if (file.mimeType.contains("image")) {
      return Icon(Icons.image, size: 40);
    } else if (file.mimeType.contains("video")) {
      return Icon(Icons.videocam, size: 40);
    } else {
      return Icon(Icons.picture_as_pdf, size: 40);
    }
  }
}