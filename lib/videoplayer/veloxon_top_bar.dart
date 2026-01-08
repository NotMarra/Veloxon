import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class VeloxonTopBar extends StatelessWidget {
  final String? title;

  const VeloxonTopBar({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                LucideIcons.arrowLeft,
                color: Colors.white,
                size: 28,
              ),
            ),
            if (title != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else
              const Spacer(),
          ],
        ),
      ),
    );
  }
}
