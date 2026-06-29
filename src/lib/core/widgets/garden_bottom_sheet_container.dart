import 'package:flutter/material.dart';
import '../theme/garden_colors.dart';

class GardenBottomSheetContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GardenBottomSheetContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: GardenColors.creamPaper,
        image: DecorationImage(
          image: AssetImage('assets/images/paper_texture.png'),
          fit: BoxFit.cover,
        ),
        border: Border.all(color: GardenColors.ink, width: 2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: child,
    );
  }
}
