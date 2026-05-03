import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

/// Camera screen that captures grocery items and runs OCR
/// to extract item names, then returns them to the calling screen
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  // Camera and ML Kit resources
  CameraController? _cameraController;
  final TextRecognizer _textRecognizer = TextRecognizer();

  // State flags
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String? _errorMessage;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    // App state changed before we got the chance to initialize
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  /// Initialize camera with permission handling
  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _errorMessage = 'Camera permission is required to scan items';
        });
        return;
      }

      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No camera found on this device';
        });
        return;
      }

      // Initialize camera controller with back camera
      _cameraController = CameraController(
        cameras[0], // Back camera
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  /// Capture image and process with OCR
  Future<void> _captureAndProcess() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Capture image
      final XFile image = await _cameraController!.takePicture();

      // Convert to InputImage for ML Kit
      final inputImage = InputImage.fromFilePath(image.path);

      // Process with OCR
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      // Parse text to extract item names
      final items = _parseItemsFromText(recognizedText.text);

      if (!mounted) return;

      if (items.isEmpty) {
        _showNoTextFoundDialog();
      } else {
        // Show confirmation dialog
        final confirmedItems = await _showConfirmationDialog(items);
        if (confirmedItems != null && mounted) {
          // Return items to calling screen
          Navigator.pop(context, confirmedItems);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to process image: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Parse OCR text to extract potential item names
  /// Simple line-by-line extraction with basic filtering
  List<String> _parseItemsFromText(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) =>
            line.isNotEmpty &&
            line.length > 2 &&
            !_isNumericOnly(line) &&
            !_isSymbolOnly(line))
        .toList();
  }

  /// Check if text contains only numbers and common separators
  bool _isNumericOnly(String text) {
    return RegExp(r'^[\d\s.,:/\-]+$').hasMatch(text);
  }

  /// Check if text contains only symbols
  bool _isSymbolOnly(String text) {
    return RegExp(r'^[^\w\s]+$').hasMatch(text);
  }

  /// Show confirmation dialog for detected items
  Future<List<String>?> _showConfirmationDialog(List<String> items) async {
    final editableItems = List<String>.from(items);

    return showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Detected Items'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Review and edit the detected items:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: editableItems.length,
                    itemBuilder: (context, index) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.shopping_basket),
                        title: TextField(
                          controller: TextEditingController(
                            text: editableItems[index],
                          ),
                          onChanged: (value) {
                            editableItems[index] = value;
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Item name',
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setDialogState(() {
                              editableItems.removeAt(index);
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                  onPressed: () {
                    setDialogState(() {
                      editableItems.add('');
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final validItems = editableItems
                    .where((item) => item.trim().isNotEmpty)
                    .toList();
                Navigator.pop(context, validItems);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show dialog when no text is detected
  void _showNoTextFoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Text Found'),
        content: const Text(
          'Could not detect any text in the image. Please try:\n\n'
          '• Better lighting\n'
          '• Holding camera steady\n'
          '• Moving closer to the label\n'
          '• Ensuring text is clear and visible',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _captureAndProcess,
        ),
      ),
    );
  }

  /// Toggle camera flash
  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;

    try {
      final newMode =
          _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;

      await _cameraController!.setFlashMode(newMode);
      setState(() => _flashMode = newMode);
    } catch (e) {
      _showErrorSnackBar('Failed to toggle flash');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Grocery Item'),
        actions: [
          if (_isCameraInitialized)
            IconButton(
              icon: Icon(
                _flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
              ),
              onPressed: _toggleFlash,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (!_isCameraInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera...'),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: CameraPreview(_cameraController!),
        ),

        // Scanning guide overlay
        Positioned.fill(
          child: CustomPaint(
            painter: ScanningGuidePainter(),
          ),
        ),

        // Bottom control panel
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildControlPanel(),
        ),
      ],
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Point camera at product label',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.large(
            onPressed: _isProcessing ? null : _captureAndProcess,
            backgroundColor: _isProcessing ? Colors.grey : null,
            child: _isProcessing
                ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  )
                : const Icon(Icons.camera, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (_errorMessage!.contains('permission'))
              ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
                onPressed: () => openAppSettings(),
              )
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: () {
                  setState(() => _errorMessage = null);
                  _initializeCamera();
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for scanning guide overlay with green targeting box
class ScanningGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Green paint for targeting box
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.8)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Semi-transparent overlay outside the box
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Draw rectangle guide in center
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.8,
      height: size.height * 0.4,
    );

    // Draw dark overlay outside the targeting box
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(rect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, overlayPaint);

    // Draw green corners
    const cornerLength = 40.0;

    // Top-left corner
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + const Offset(cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + const Offset(0, cornerLength),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      rect.topRight,
      rect.topRight + const Offset(-cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      rect.topRight,
      rect.topRight + const Offset(0, cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + const Offset(cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + const Offset(0, -cornerLength),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + const Offset(-cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + const Offset(0, -cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Made with Bob
