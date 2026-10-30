import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/scan_models.dart';

class DetectionOverlay extends StatelessWidget {
  final List<DetectedObject> objects;
  final DetectedObject? selectedObject;
  final ValueChanged<DetectedObject> onSelectObject;

  const DetectionOverlay({
    super.key,
    required this.objects,
    required this.selectedObject,
    required this.onSelectObject,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          children: objects.map((obj) {
            final left = obj.box.x * w;
            final top = obj.box.y * h;
            final width = obj.box.width * w;
            final height = obj.box.height * h;
            final isSelected = selectedObject?.id == obj.id;

            return Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: GestureDetector(
                onTap: () => onSelectObject(obj),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.white,
                      width: isSelected ? 3 : 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Label Tag on top-left of box
                      Positioned(
                        top: -14,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryDark : Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                obj.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${(obj.confidence * 100).toInt()}%',
                                style: TextStyle(
                                  color: AppColors.primaryLight.withValues(alpha: 0.9),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

