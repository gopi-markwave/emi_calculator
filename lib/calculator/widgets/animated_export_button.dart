import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedExportButton extends StatefulWidget {
  final bool isYearly;
  final VoidCallback onPressed;

  const AnimatedExportButton({
    super.key,
    required this.isYearly,
    required this.onPressed,
  });

  @override
  State<AnimatedExportButton> createState() => _AnimatedExportButtonState();
}

class _AnimatedExportButtonState extends State<AnimatedExportButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          height: 48,
          width: _isHovered ? 170.0 : 48.0,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isHovered) ...[
                Expanded(
                  child: Text(
                    'Export ${widget.isYearly ? "Yearly" : "Monthly"}',
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              Icon(Icons.download, color: Colors.grey.shade800, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
