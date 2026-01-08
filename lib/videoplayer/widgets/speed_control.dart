import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:veloxon/ui/menu_anchor.dart';

class SpeedControl extends StatefulWidget {
  final Player player;
  final VoidCallback stopHideTimer;
  final VoidCallback restartHideTimer;

  const SpeedControl({
    super.key,
    required this.player,
    required this.stopHideTimer,
    required this.restartHideTimer,
  });

  @override
  State<SpeedControl> createState() => _SpeedControlState();
}

class _SpeedControlState extends State<SpeedControl> {
  MenuController? _speedMenuController;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: widget.player.stream.rate,
      builder: (context, snapshot) {
        final rate = snapshot.data ?? 1.0;
        final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

        return VeloxonMenuAnchor<double>(
          label: '${rate}x',
          currentValue: rate,
          items: speeds
              .map((speed) => VeloxonMenuItem(label: '${speed}x', value: speed))
              .toList(),
          onChanged: (newSpeed) {
            widget.player.setRate(newSpeed);
          },
          onControllerCreated: (controller) {
            _speedMenuController = controller;
          },
          onOpen: widget.stopHideTimer,
          onClose: widget.restartHideTimer,
        );
      },
    );
  }
}
