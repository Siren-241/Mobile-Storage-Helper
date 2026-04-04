import 'package:flutter/material.dart';
import 'package:storage_query_engine/utils.dart';
import 'models/media_file.dart';
import 'package:open_filex/open_filex.dart';

Widget buildList(List<MediaFile> results) {
  return ListView.builder(
    itemCount: results.length,
    itemBuilder: (context, index) {
      return GestureDetector(
        onTap: () async {
          if(results[index].path != null) {
            await OpenFilex.open(results[index].path!);
          }
        },
        child: _FileCard(file: results[index]),
      );
    },
  );
}

class _FileCard extends StatelessWidget {
  final MediaFile file;

  const _FileCard({required this.file});

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
          Icon(getIcon(file.mimeType)),
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
          file.createdAt.toString(),
          style: TextStyle(color: Colors.grey, fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

}
