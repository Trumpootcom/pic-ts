import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ToolBubbleButton extends StatelessWidget {
  final String iconAsset;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const ToolBubbleButton({
    super.key,
    required this.iconAsset,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleSize = active ? 60.0 : 52.0;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              width: bubbleSize,
              height: bubbleSize,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? const Color(0xFFFF9800)
                    : const Color.fromARGB(255, 62, 101, 121),
                boxShadow: [
                  if (active)
                    const BoxShadow(
                      color: Color(0xCCFF9800),
                      blurRadius: 14,
                      spreadRadius: 2,
                    )
                  else
                    const BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                ],
              ),
              child: SvgPicture.asset(
                iconAsset,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: active ? Colors.orange : Colors.black,
                fontSize: 11,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}