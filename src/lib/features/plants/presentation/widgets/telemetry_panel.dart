import 'package:flutter/material.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/widgets/garden_icon.dart';

class TelemetryData {
  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final String iconAsset;
  final Color color;

  TelemetryData({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.iconAsset,
    required this.color,
  });

  bool get isInRange => value >= min && value <= max;
  double get percentage => ((value - min) / (max - min)).clamp(0.0, 1.0);
}

class TelemetryPanel extends StatefulWidget {
  final List<TelemetryData> telemetryData;
  final bool initiallyExpanded;

  const TelemetryPanel({
    super.key,
    required this.telemetryData,
    this.initiallyExpanded = false,
  });

  @override
  State<TelemetryPanel> createState() => _TelemetryPanelState();
}

class _TelemetryPanelState extends State<TelemetryPanel> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
          )
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (_expanded) _buildTelemetryGrid(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFDFCF8),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const GardenIcon(asset: GardenIcons.logroSensores, size: 22),
            const SizedBox(width: 12),
            const Text(
              'Telemetría',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            AnimatedRotation(
              duration: const Duration(milliseconds: 300),
              turns: _expanded ? 0.5 : 0,
              child: const Icon(Icons.expand_more, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryGrid() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: widget.telemetryData.length,
        itemBuilder: (context, index) {
          final data = widget.telemetryData[index];
          return _buildTelemetryCard(data);
        },
      ),
    );
  }

  Widget _buildTelemetryCard(TelemetryData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: data.isInRange
              ? data.color.withOpacity(0.2)
              : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GardenIcon(asset: data.iconAsset, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  data.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: data.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${data.value.toStringAsFixed(1)} ${data.unit}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _buildRangeIndicator(data),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${data.min}${data.unit}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
              Text(
                '${data.max}${data.unit}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          if (!data.isInRange) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning, size: 12, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    'Fuera de rango',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRangeIndicator(TelemetryData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final filledWidth = (data.percentage * totalWidth).clamp(0.0, totalWidth);
        final thumbLeft = (filledWidth - 8).clamp(0.0, totalWidth - 16);
        return SizedBox(
          height: 6,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  height: 6,
                  width: filledWidth,
                  decoration: BoxDecoration(
                    color: data.isInRange ? data.color : Colors.red,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Positioned(
                left: thumbLeft,
                top: -5,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: data.isInRange ? data.color : Colors.red,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}