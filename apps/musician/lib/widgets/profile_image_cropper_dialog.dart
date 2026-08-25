import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ProfileImageCropperDialog extends StatefulWidget {
  final File imageFile;

  const ProfileImageCropperDialog({
    super.key,
    required this.imageFile,
  });

  @override
  State<ProfileImageCropperDialog> createState() => _ProfileImageCropperDialogState();
}

class _ProfileImageCropperDialogState extends State<ProfileImageCropperDialog> {
  final GlobalKey _cropKey = GlobalKey();
  Offset _offset = Offset.zero;
  double _zoomScale = 1.0;
  double _baseScale = 1.0;
  bool _isProcessing = false;

  void _onSliderZoomChanged(double value) {
    setState(() {
      _zoomScale = value;
    });
  }

  void _resetPosition() {
    setState(() {
      _offset = Offset.zero;
      _zoomScale = 1.0;
    });
  }

  Future<void> _cropAndSave() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final RenderRepaintBoundary boundary =
          _cropKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = Directory.systemTemp;
      final croppedFile = File(
        '${tempDir.path}/cropped_profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await croppedFile.writeAsBytes(pngBytes);

      if (mounted) {
        Navigator.of(context).pop(croppedFile);
      }
    } catch (e) {
      debugPrint('Error cropping profile image: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cropping image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFA1F301), width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Adjust Profile Picture',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  tooltip: 'Reset position',
                  icon: const Icon(Icons.center_focus_strong, color: Color(0xFFA1F301), size: 22),
                  onPressed: _resetPosition,
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              'Drag with one finger to move photo. Pinch or use slider to zoom.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),

            // Circular Crop Viewport with Gesture Pan & Zoom
            RepaintBoundary(
              key: _cropKey,
              child: ClipOval(
                child: Container(
                  width: 250,
                  height: 250,
                  color: Colors.black,
                  child: GestureDetector(
                    onScaleStart: (details) {
                      _baseScale = _zoomScale;
                    },
                    onScaleUpdate: (details) {
                      setState(() {
                        if (details.scale != 1.0) {
                          _zoomScale = (_baseScale * details.scale).clamp(1.0, 3.5);
                        }
                        _offset += details.focalPointDelta;
                      });
                    },
                    child: Transform.translate(
                      offset: _offset,
                      child: Transform.scale(
                        scale: _zoomScale,
                        child: Image.file(
                          widget.imageFile,
                          fit: BoxFit.cover,
                          width: 250,
                          height: 250,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Zoom Slider Controls
            Row(
              children: [
                const Icon(Icons.zoom_out, color: Colors.white70, size: 20),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFFA1F301),
                      inactiveTrackColor: Colors.grey[800],
                      thumbColor: const Color(0xFFA1F301),
                      overlayColor: const Color(0xFFA1F301).withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: _zoomScale.clamp(1.0, 3.5),
                      min: 1.0,
                      max: 3.5,
                      onChanged: _onSliderZoomChanged,
                    ),
                  ),
                ),
                const Icon(Icons.zoom_in, color: Colors.white70, size: 20),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _cropAndSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA1F301),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Photo',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
