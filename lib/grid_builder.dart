import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:storage_query_engine/utils.dart';
import 'models/media_file.dart';
import 'package:open_filex/open_filex.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

Widget buildGrid(List<MediaFile> results) {
  return GridView.builder(
    itemCount: results.length,
    padding: const EdgeInsets.all(8),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3, // TODO: Don't hardcode this
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.75,
    ),
    itemBuilder: (context, index) {
      return GestureDetector(
        onTap: () async {
          if (results[index].path != null) {
            OpenFilex.open(results[index].path!);
          }
        },
        child: _GridCard(file: results[index]),
      );
    },
  );
}

class _GridCard extends StatelessWidget {
  final MediaFile file;

  const _GridCard({required this.file});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[200],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildPreview()),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              file.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          )
        ]
      )
    );
  }

  Widget _buildPreview() {
    return FutureBuilder(
      future: _loadThumbnail(),
      builder: (context, snapshot) {

        // TODO: Confirm this works properly
        // Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              color: Colors.white38,
              child: Icon(getIcon(file.mimeType)),
            )
          );
        }

        // Error State
        if (snapshot.hasError) {
          return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                color: Colors.white38,
              )
          );
        }

        // Empty State
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Icon(
              getIcon(file.mimeType),
              size: 40,
              color: Colors.grey,
            )
          );
        }

        // Actual Payload
        if (snapshot.hasData && snapshot.connectionState == ConnectionState.done) {
          return ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16)
            ),
            child: Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              width: double.infinity
            ),
          );
        }

        // Fallback
        return Center(
          child: Icon(
            getIcon(file.mimeType),
            size: 40,
            color: Colors.grey,
          )
        );
      }
    );
  }

  Future _loadThumbnail() async {
    if (file.mimeType.contains("image")){
      final asset = await AssetEntity.fromId(file.assetId);
      return await asset?.thumbnailDataWithSize(
        const ThumbnailSize(300, 300)
      );
    }
    if (file.mimeType.contains("video")) {
      return await VideoThumbnail.thumbnailData(
        video: file.path!,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        quality: 75,
      );
    }
  }

}