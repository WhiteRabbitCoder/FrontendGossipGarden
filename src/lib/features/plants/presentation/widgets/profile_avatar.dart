import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/garden_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final Uint8List? localBytes;
  final double size;
  final double fontSize;

  const ProfileAvatar({
    super.key,
    this.photoUrl,
    this.localBytes,
    this.size = 100,
    this.fontSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: GardenColors.creamLight,
        shape: BoxShape.circle,
        border: Border.all(color: GardenColors.leafGreen, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (localBytes != null && localBytes!.isNotEmpty) {
      return Image.memory(localBytes!, fit: BoxFit.cover);
    }

    final url = photoUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        return Image.network(url, fit: BoxFit.cover);
      }
      if (!kIsWeb) {
        final file = File(url);
        if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.cover);
        }
      }
    }

    return Center(
      child: Text('🧑‍🌾', style: TextStyle(fontSize: fontSize)),
    );
  }
}
