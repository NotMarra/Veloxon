import 'package:flutter/material.dart';

/// Uniformní wrapper pro MenuAnchor s konzistentním stylingem
class VeloxonMenuAnchor<T> extends StatefulWidget {
  final String label;
  final List<VeloxonMenuItem<T>> items;
  final T currentValue;
  final ValueChanged<T> onChanged;
  final TextStyle? labelStyle;
  final ValueChanged<MenuController>? onControllerCreated;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  const VeloxonMenuAnchor({
    super.key,
    required this.label,
    required this.items,
    required this.currentValue,
    required this.onChanged,
    this.labelStyle,
    this.onControllerCreated,
    this.onOpen,
    this.onClose,
  });

  @override
  State<VeloxonMenuAnchor<T>> createState() => _VeloxonMenuAnchorState<T>();
}

class _VeloxonMenuAnchorState<T> extends State<VeloxonMenuAnchor<T>> {
  MenuController? _menuController;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxMenuHeight = screenHeight * 0.5; // 50% výšky obrazovky

    return MenuAnchor(
      controller: _menuController,
      onOpen: () {
        if (_menuController != null && widget.onControllerCreated != null) {
          widget.onControllerCreated!(_menuController!);
        }
        widget.onOpen?.call();
      },
      onClose: () {
        widget.onClose?.call();
      },
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(
          Colors.black.withValues(alpha: 0.9),
        ),
        elevation: WidgetStateProperty.all(8),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        maximumSize: WidgetStateProperty.all(
          Size(double.infinity, maxMenuHeight),
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

/// Menu s ikonou místo textu (pro settings atd.)
class VeloxonIconMenuAnchor extends StatefulWidget {
  final IconData icon;
  final List<Widget> menuChildren;
  final ValueChanged<MenuController>? onControllerCreated;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  const VeloxonIconMenuAnchor({
    super.key,
    required this.icon,
    required this.menuChildren,
    this.onControllerCreated,
    this.onOpen,
    this.onClose,
  });

  @override
  State<VeloxonIconMenuAnchor> createState() => _VeloxonIconMenuAnchorState();
}

class _VeloxonIconMenuAnchorState extends State<VeloxonIconMenuAnchor> {
  MenuController? _menuController;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxMenuHeight = screenHeight * 0.5;

    return MenuAnchor(
      controller: _menuController,
      onOpen: () {
        if (_menuController != null && widget.onControllerCreated != null) {
          widget.onControllerCreated!(_menuController!);
        }
        widget.onOpen?.call();
      },
      onClose: () {
        widget.onClose?.call();
      },
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(
          Colors.black.withValues(alpha: 0.9),
        ),
        elevation: WidgetStateProperty.all(8),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        maximumSize: WidgetStateProperty.all(
          Size(double.infinity, maxMenuHeight),
        ),
      ),
      builder: (context, controller, child) {
        _menuController ??= controller;
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: Icon(widget.icon, color: Colors.white),
        );
      },
      menuChildren: widget.menuChildren,
    );
  }
}

/// Menu s podporou submenu (otevírá se vpravo)
class VeloxonSubmenuAnchor extends StatefulWidget {
  final String label;
  final IconData? icon;
  final List<Widget> menuChildren;
  final ValueChanged<MenuController>? onControllerCreated;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  const VeloxonSubmenuAnchor({
    super.key,
    required this.label,
    this.icon,
    required this.menuChildren,
    this.onControllerCreated,
    this.onOpen,
    this.onClose,
  });

  @override
  State<VeloxonSubmenuAnchor> createState() => _VeloxonSubmenuAnchorState();
}

class _VeloxonSubmenuAnchorState extends State<VeloxonSubmenuAnchor> {
  MenuController? _menuController;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxMenuHeight = screenHeight * 0.5; // 50% výšky obrazovky

    return SubmenuButton(
      controller: _menuController,
      onOpen: () {
        if (_menuController != null && widget.onControllerCreated != null) {
          widget.onControllerCreated!(_menuController!);
        }
        widget.onOpen?.call();
      },
      onClose: () {
        widget.onClose?.call();
      },
      style: MenuItemButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(
          Colors.black.withValues(alpha: 0.9),
        ),
        elevation: WidgetStateProperty.all(8),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        maximumSize: WidgetStateProperty.all(
          Size(double.infinity, maxMenuHeight),
        ),
      ),
      alignmentOffset: const Offset(0, 0),
      menuChildren: widget.menuChildren,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: Colors.white, size: 18),
            const SizedBox(width: 12),
          ] else
            const SizedBox(width: 18),
          Expanded(
            child: Text(
              widget.label,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white, size: 18),
        ],
      ),
    );
  }
}
