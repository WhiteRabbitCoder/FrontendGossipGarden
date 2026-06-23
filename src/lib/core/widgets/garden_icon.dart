import 'package:flutter/material.dart';

class GardenIcon extends StatelessWidget {
  final String asset;
  final double size;
  final double? opacity;
  final Color? color;
  final BoxFit fit;

  const GardenIcon({
    super.key,
    required this.asset,
    this.size = 24,
    this.opacity,
    this.color,
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
        color: color ?? Colors.grey,
      ),
    );

    if (color != null) {
      image = ColorFiltered(
        colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
        child: image,
      );
    }

    if (opacity != null) {
      image = Opacity(opacity: opacity!, child: image);
    }

    return image;
  }
}
