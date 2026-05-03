# Scanner Screen Quick Reference

## 📋 Implementation Checklist

### Phase 1: Platform Setup
- [ ] Add `<uses-permission android:name="android.permission.CAMERA" />` to AndroidManifest.xml
- [ ] Add `NSCameraUsageDescription` to iOS Info.plist
- [ ] Verify dependencies in pubspec.yaml

### Phase 2: Core Implementation
- [ ] Import required packages
- [ ] Create state variables
- [ ] Implement camera initialization
- [ ] Build camera preview UI
- [ ] Add capture button
- [ ] Implement OCR processing
- [ ] Create text parsing logic

### Phase 3: User Experience
- [ ] Build confirmation dialog
- [ ] Add permission handling
- [ ] Implement error handling
- [ ] Add loading indicators
- [ ] Test return mechanism

## 🔧 Required Imports

```dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
```

## 📦 State Variables Template

```dart
class _ScannerScreenState extends State<ScannerScreen> 
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String? _errorMessage;
  FlashMode _flashMode = FlashMode.off;
}
```

## 🎬 Camera Initialization Pattern

```dart
Future<void> _initializeCamera() async {
  try {
    // 1. Request permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _errorMessage = 'Camera permission denied');
      return;
    }

    // 2. Get cameras
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() => _errorMessage = 'No camera found');
      return;
    }

    // 3. Initialize controller
    _cameraController = CameraController(
      cameras[0], // Back camera
      ResolutionPreset.high,
      enableAudio: false,
    );

    // 4. Wait for initialization
    await _cameraController!.initialize();

    // 5. Update state
    if (mounted) {
      setState(() => _isCameraInitialized = true);
    }
  } catch (e) {
    setState(() => _errorMessage = 'Camera initialization failed: $e');
  }
}
```

## 📸 Capture & Process Pattern

```dart
Future<void> _captureAndProcess() async {
  if (_cameraController == null || !_cameraController!.value.isInitialized) {
    return;
  }

  setState(() => _isProcessing = true);

  try {
    // 1. Capture image
    final XFile image = await _cameraController!.takePicture();

    // 2. Convert to InputImage
    final inputImage = InputImage.fromFilePath(image.path);

    // 3. Process with OCR
    final RecognizedText recognizedText = 
        await _textRecognizer.processImage(inputImage);

    // 4. Parse text
    final items = _parseItemsFromText(recognizedText.text);

    // 5. Show confirmation
    if (items.isEmpty) {
      _showNoTextFoundDialog();
    } else {
      final confirmedItems = await _showConfirmationDialog(items);
      if (confirmedItems != null && mounted) {
        Navigator.pop(context, confirmedItems);
      }
    }
  } catch (e) {
    _showErrorSnackBar('Failed to process image: $e');
  } finally {
    setState(() => _isProcessing = false);
  }
}
```

## 🔍 Text Parsing Pattern

```dart
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

bool _isNumericOnly(String text) {
  return RegExp(r'^[\d\s.,]+$').hasMatch(text);
}

bool _isSymbolOnly(String text) {
  return RegExp(r'^[^\w\s]+$').hasMatch(text);
}
```

## 💬 Confirmation Dialog Pattern

```dart
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
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: editableItems.length,
                  itemBuilder: (context, index) => ListTile(
                    title: TextField(
                      controller: TextEditingController(
                        text: editableItems[index],
                      ),
                      onChanged: (value) {
                        editableItems[index] = value;
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setDialogState(() {
                          editableItems.removeAt(index);
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
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
            onPressed: () => Navigator.pop(
              context,
              editableItems.where((item) => item.trim().isNotEmpty).toList(),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ),
  );
}
```

## 🎨 UI Build Pattern

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Scan Grocery Item'),
      actions: [
        if (_isCameraInitialized)
          IconButton(
            icon: Icon(_flashMode == FlashMode.off 
                ? Icons.flash_off 
                : Icons.flash_on),
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
    return const Center(child: CircularProgressIndicator());
  }
  
  return Stack(
    children: [
      // Camera preview
      Positioned.fill(
        child: CameraPreview(_cameraController!),
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
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 16),
        FloatingActionButton.large(
          onPressed: _isProcessing ? null : _captureAndProcess,
          child: _isProcessing
              ? const CircularProgressIndicator(color: Colors.white)
              : const Icon(Icons.camera, size: 32),
        ),
      ],
    ),
  );
}
```

## 🧹 Cleanup Pattern

```dart
@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  _cameraController?.dispose();
  _textRecognizer.close();
  super.dispose();
}

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (_cameraController == null || !_cameraController!.value.isInitialized) {
    return;
  }

  if (state == AppLifecycleState.inactive) {
    _cameraController?.dispose();
  } else if (state == AppLifecycleState.resumed) {
    _initializeCamera();
  }
}
```

## 🚨 Error Handling Patterns

```dart
Widget _buildErrorView() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
```

## 🔦 Flash Toggle Pattern

```dart
Future<void> _toggleFlash() async {
  if (_cameraController == null) return;

  try {
    final newMode = _flashMode == FlashMode.off 
        ? FlashMode.torch 
        : FlashMode.off;
    
    await _cameraController!.setFlashMode(newMode);
    setState(() => _flashMode = newMode);
  } catch (e) {
    _showErrorSnackBar('Failed to toggle flash');
  }
}
```

## 📱 Platform Permissions

### Android (AndroidManifest.xml)
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    
    <application>
        <!-- ... -->
    </application>
</manifest>
```

### iOS (Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan grocery items and extract product information</string>
```

## 🧪 Testing Checklist

### Functional Tests
- [ ] Camera opens successfully
- [ ] Camera preview displays correctly
- [ ] Capture button takes photo
- [ ] OCR extracts text from image
- [ ] Text parsing filters correctly
- [ ] Confirmation dialog shows items
- [ ] Items can be edited
- [ ] Items can be deleted
- [ ] New items can be added
- [ ] Confirmed items return correctly

### Error Tests
- [ ] Permission denied handling
- [ ] No camera available handling
- [ ] Camera initialization failure
- [ ] OCR processing failure
- [ ] No text detected handling
- [ ] App lifecycle changes

### UI Tests
- [ ] Loading indicator shows during init
- [ ] Processing indicator shows during OCR
- [ ] Error view displays correctly
- [ ] Flash toggle works
- [ ] Buttons are responsive

## 📊 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Camera not initializing | Check permissions, verify camera availability |
| OCR returns no text | Improve lighting, hold camera steady, use higher resolution |
| App crashes on dispose | Ensure proper null checks, dispose in correct order |
| Memory leaks | Always dispose camera and ML Kit resources |
| Slow OCR processing | Use ResolutionPreset.high (not max), process on background isolate |
| Permission denied | Show clear message, provide settings button |

## 🎯 Key Implementation Points

1. **Always check mounted** before setState after async operations
2. **Dispose resources** in correct order: camera → ML Kit → super
3. **Handle lifecycle** changes to pause/resume camera
4. **Use try-catch** around all camera and OCR operations
5. **Provide feedback** with loading indicators and error messages
6. **Clean up files** after OCR processing
7. **Test on real devices** - emulators may not have camera support

## 📚 Additional Resources

- [Camera Plugin Documentation](https://pub.dev/packages/camera)
- [Google ML Kit Text Recognition](https://pub.dev/packages/google_mlkit_text_recognition)
- [Permission Handler](https://pub.dev/packages/permission_handler)
- [Flutter Camera Best Practices](https://docs.flutter.dev/cookbook/plugins/picture-using-camera)