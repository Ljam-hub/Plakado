import 'package:flutter/material.dart';
import '../../services/image_processing_service.dart';

class YoloBoundingBoxWidget extends StatefulWidget {
  final YoloBoundingBox? detectedBox;
  final bool isScanning;
  final VoidCallback? onTap;

  const YoloBoundingBoxWidget({
    super.key,
    this.detectedBox,
    this.isScanning = false,
    this.onTap,
  });

  @override
  State<YoloBoundingBoxWidget> createState() => _YoloBoundingBoxWidgetState();
}

class _YoloBoundingBoxWidgetState extends State<YoloBoundingBoxWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // Default viewfinder or YOLO detected box
        final box = widget.detectedBox ??
            YoloBoundingBox(
              x: 0.15,
              y: 0.35,
              width: 0.70,
              height: 0.28,
              confidence: 0.0,
            );

        final left = box.x * width;
        final top = box.y * height;
        final boxW = box.width * width;
        final boxH = box.height * height;

        return Stack(
          children: [
            // Darkened background overlay outside the box
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.55),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: Container(
                      margin: EdgeInsets.fromLTRB(left, top, width - (left + boxW), height - (top + boxH)),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // YOLO Bounding Box Rectangle
            Positioned(
              left: left,
              top: top,
              width: boxW,
              height: boxH,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.detectedBox != null ? const Color(0xFF10B981) : Colors.white70,
                    width: 2.5,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // YOLO Model Detection Tag
                    Positioned(
                      top: -24,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: widget.detectedBox != null ? const Color(0xFF10B981) : Colors.blueAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              widget.detectedBox != null
                                  ? 'YOLOv8: license_plate ${(widget.detectedBox!.confidence * 100).toStringAsFixed(1)}%'
                                  : 'YOLO VIEWPORT',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Scanning laser line animation
                    if (widget.isScanning)
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return Positioned(
                            top: _animController.value * (boxH - 4),
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: const Color(0xFF34D399),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.8),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
