import 'package:flutter/material.dart';

class GardenIcon extends StatelessWidget {
  final String asset;
  final double size;
  final double? opacity;
  final BoxFit fit;

  const GardenIcon({
    super.key,
    required this.asset,
    this.size = 24,
    this.opacity,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      asset,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (_, __, ___) => Icon(
        Icons.image_not_supported_outlined,
        size: size,
        color: Colors.grey,
      ),
    );

    if (opacity != null) {
      image = Opacity(opacity: opacity!, child: image);
    }

    return image;
  }
}
