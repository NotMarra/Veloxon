import 'package:flutter/material.dart';

/// Uniformní wrapper pro MenuAnchor s konzistentním stylingem
class VeloxonMenuAnchor<T> extends StatefulWidget {
  final String label;
  final List<VeloxonMenuItem<T>> items;
  final T currentValue;
  final ValueChanged<T> onChanged;
  final TextStyle? labelStyle;
  final ValueChanged<MenuController>? onControllerCreated;

  const VeloxonMenuAnchor({
    super.key,
    required this.label,
    required this.items,
    required this.currentValue,
    required this.onChanged,
    this.labelStyle,
    this.onControllerCreated,
  });

  @override
  State<VeloxonMenuAnchor<T>> createState() => _VeloxonMenuAnchorState<T>();
}

class _VeloxonMenuAnchorState<T> extends State<VeloxonMenuAnchor<T>> {
  MenuController? _menuController;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _menuController,
      onOpen: () {
        if (_menuController != null && widget.onControllerCreated != null) {
          widget.onControllerCreated!(_menuController!);
        }
      },
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(
          Colors.black.withValues(alpha: 0.9),
        ),
        elevation: WidgetStateProperty.all(8),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
            // Uložit referenci na controller při prvním buildování
            _menuController ??= controller;

            return TextButton(
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style:
                        widget.labelStyle ??
                        const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    controller.isOpen
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            );
          },
      menuChildren: widget.items.map((item) {
        final isSelected = item.value == widget.currentValue;
        return MenuItemButton(
          onPressed: () => widget.onChanged(item.value),
          style: MenuItemButton.styleFrom(
            backgroundColor: isSelected
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          leadingIcon: isSelected
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : const SizedBox(width: 18),
          child: Text(
            item.label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Položka menu
class VeloxonMenuItem<T> {
  final String label;
  final T value;

  const VeloxonMenuItem({required this.label, required this.value});
}
