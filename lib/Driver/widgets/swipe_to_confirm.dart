import 'package:flutter/material.dart';

class SwipeToConfirm extends StatefulWidget {
  final VoidCallback onConfirm;
  final String text;
  final Color baseColor;
  final Color trackColor;

  const SwipeToConfirm({
    Key? key,
    required this.onConfirm,
    required this.text,
    required this.baseColor,
    required this.trackColor,
  }) : super(key: key);

  @override
  State<SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<SwipeToConfirm>
    with SingleTickerProviderStateMixin {
  double _position = 0.0;
  bool _confirmed = false;
  final double _height = 64.0;
  final double _thumbSize = 52.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxPosition = constraints.maxWidth - _thumbSize - 6;

        return Container(
          height: _height,
          decoration: BoxDecoration(
            color: widget.trackColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Stack(
            children: [
              // Text
              Center(
                child: Text(
                  _confirmed ? '' : widget.text,
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),

              // Confirmed Overlay (Fades In)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _confirmed ? 1.0 : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.baseColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.check,
                    color: Colors.black,
                    size: 32,
                  ),
                ),
              ),

              // Thumb Position
              if (!_confirmed)
                Positioned(
                  left: 3 + _position,
                  top: (_height - _thumbSize) / 2,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _position += details.delta.dx;
                        if (_position < 0) _position = 0;
                        if (_position > maxPosition) _position = maxPosition;
                      });
                    },
                    onPanEnd: (details) {
                      if (_position > maxPosition * 0.85) {
                        setState(() {
                          _position = maxPosition;
                          _confirmed = true;
                        });
                        Future.delayed(const Duration(milliseconds: 300), () {
                          widget.onConfirm();
                        });
                      } else {
                        // Snap back smoothly
                        setState(() {
                          _position = 0.0;
                        });
                      }
                    },
                    child: Container(
                      width: _thumbSize,
                      height: _thumbSize,
                      decoration: BoxDecoration(
                        color: widget.baseColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.double_arrow_rounded,
                        color: Colors.black,
                        size: 28,
                      ),
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
