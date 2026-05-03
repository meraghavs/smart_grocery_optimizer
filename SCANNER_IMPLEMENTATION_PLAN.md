# Scanner Screen Implementation Plan

## Overview
Implementation plan for `lib/screens/scanner_screen.dart` - a full-featured camera screen with OCR text recognition for extracting grocery item names from product labels.

## Requirements Summary
- **Camera**: Live viewfinder using the camera package
- **Capture**: Bottom-positioned capture button
- **OCR**: Google ML Kit text recognition after image capture
- **Parsing**: Simple line-by-line text extraction
- **Confirmation**: Review/edit screen before returning items
- **Return**: List of detected item names back to calling screen
- **Mode**: OCR only (no barcode scanning)

## Architecture

```
ScannerScreen (Main Camera View)
    ↓ (capture image)
CameraController.takePicture()
    ↓ (process image)
TextRecognizer.processImage()
    ↓ (parse text)
_parseItemsFromText()
    ↓ (show confirmation)
ConfirmationDialog/Screen
    ↓ (user confirms)
Navigator.pop(context, detectedItems)
```

## Dependencies

### Current Dependencies (from pubspec.yaml)
```yaml
camera: ^0.12.0+1
google_ml_kit: ^0.21.0
permission_handler: ^12.0.1
```

**Note**: The `google_ml_kit` package is a meta-package. For text recognition specifically, we'll use:
- `google_mlkit_text_recognition` (included in google_ml_kit)

## Implementation Steps

### 1. Platform Permissions

#### Android Manifest (`android/app/src/main/AndroidManifest.xml`)
Add before `<application>` tag:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

#### iOS Info.plist (`ios/Runner/Info.plist`)
Add before closing `</dict>`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan grocery items and extract product information</string>
```

### 2. Scanner Screen Structure

#### State Variables
```dart
CameraController? _cameraController;
final TextRecognizer _textRecognizer = TextRecognizer();
bool _isCameraInitialized = false;
bool _isProcessing = false;
String? _errorMessage;
```

#### Lifecycle Methods
- `initState()`: Initialize camera and request permissions
- `dispose()`: Dispose camera controller and ML Kit resources
- `_initializeCamera()`: Async camera setup
- `_requestCameraPermission()`: Handle permission requests

### 3. Camera Implementation

#### Camera Initialization Flow
1. Request camera permission using `permission_handler`
2. Get available cameras using `availableCameras()`
3. Select back camera (index 0 typically)
4. Initialize `CameraController` with:
   - Selected camera
   - `ResolutionPreset.high` for good OCR quality
   - `enableAudio: false` (not needed)
5. Wait for controller initialization
6. Update state to show camera preview

#### Camera Preview UI
```dart
CameraPreview(_cameraController!)
```
- Full-screen camera viewfinder
- Overlay with scanning guide (optional rectangle)
- Flash toggle button in app bar
- Capture button at bottom

### 4. Image Capture & OCR Processing

#### Capture Flow
1. User taps capture button
2. Set `_isProcessing = true` (show loading indicator)
3. Call `_cameraController!.takePicture()` → returns `XFile`
4. Convert `XFile` to `InputImage` for ML Kit:
   ```dart
   final inputImage = InputImage.fromFilePath(xFile.path);
   ```
5. Process with TextRecognizer:
   ```dart
   final RecognizedText recognizedText = 
       await _textRecognizer.processImage(inputImage);
   ```
6. Parse text to extract item names
7. Show confirmation screen with results
8. Set `_isProcessing = false`

#### Text Parsing Logic (Simple)
```dart
List<String> _parseItemsFromText(String text) {
  // Split by lines
  final lines = text.split('\n');
  
  // Filter and clean
  final items = lines
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && line.length > 2)
      .where((line) => !_isNumericOrSymbol(line))
      .toList();
  
  return items;
}
```

**Filtering Rules**:
- Remove empty lines
- Remove very short text (< 3 characters)
- Remove purely numeric lines
- Remove lines with only symbols
- Keep potential product names

### 5. Confirmation Screen

#### Option A: Dialog Approach
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Detected Items'),
    content: Column(
      children: [
        ...detectedItems.map((item) => 
          ListTile(
            title: TextField(initialValue: item),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => removeItem(item),
            ),
          )
        ),
        TextButton(
          child: Text('Add Item'),
          onPressed: () => addNewItem(),
        ),
      ],
    ),
    actions: [
      TextButton(
        child: Text('Cancel'),
        onPressed: () => Navigator.pop(context),
      ),
      ElevatedButton(
        child: Text('Confirm'),
        onPressed: () {
          Navigator.pop(context); // Close dialog
          Navigator.pop(context, confirmedItems); // Return to caller
        },
      ),
    ],
  ),
);
```

#### Option B: Full Screen Approach
Navigate to a separate confirmation screen:
```dart
final confirmedItems = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ItemConfirmationScreen(
      detectedItems: detectedItems,
    ),
  ),
);

if (confirmedItems != null) {
  Navigator.pop(context, confirmedItems);
}
```

**Recommended**: Option A (Dialog) for simplicity

### 6. Error Handling

#### Error Scenarios
1. **Camera Permission Denied**
   - Show error message
   - Provide button to open app settings
   
2. **Camera Initialization Failed**
   - Display error message
   - Offer retry button
   
3. **No Camera Available**
   - Show "No camera found" message
   - Disable capture functionality
   
4. **OCR Processing Failed**
   - Show error toast/snackbar
   - Allow user to retry capture
   
5. **No Text Detected**
   - Show "No text found" message
   - Suggest better lighting or closer distance
   - Allow retry

#### Error UI Pattern
```dart
if (_errorMessage != null) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red),
        SizedBox(height: 16),
        Text(_errorMessage!),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: _retryInitialization,
          child: Text('Retry'),
        ),
      ],
    ),
  );
}
```

### 7. UI Components

#### App Bar
- Title: "Scan Grocery Item"
- Back button (automatic)
- Flash toggle button (right side)

#### Camera Preview
- Full-screen camera feed
- Semi-transparent overlay with scanning guide
- Optional: Grid lines for alignment

#### Bottom Control Panel
```dart
Positioned(
  bottom: 0,
  left: 0,
  right: 0,
  child: Container(
    padding: EdgeInsets.all(24),
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
      children: [
        Text(
          'Point camera at product label',
          style: TextStyle(color: Colors.white),
        ),
        SizedBox(height: 16),
        FloatingActionButton.large(
          onPressed: _isProcessing ? null : _captureAndProcess,
          child: _isProcessing
              ? CircularProgressIndicator(color: Colors.white)
              : Icon(Icons.camera, size: 32),
        ),
      ],
    ),
  ),
)
```

### 8. Return Data Format

```dart
// Return List<String> of item names
List<String> detectedItems = [
  'Whole Milk',
  'Organic Bread',
  'Fresh Eggs',
];

Navigator.pop(context, detectedItems);
```

**Calling Screen Usage**:
```dart
final items = await Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => ScannerScreen()),
);

if (items != null && items is List<String>) {
  // Process detected items
  for (String itemName in items) {
    // Add to shopping list or pantry
  }
}
```

## Code Structure

### Main Widget Structure
```
ScannerScreen (StatefulWidget)
├── _ScannerScreenState
│   ├── State Variables
│   │   ├── _cameraController
│   │   ├── _textRecognizer
│   │   ├── _isCameraInitialized
│   │   ├── _isProcessing
│   │   └── _errorMessage
│   │
│   ├── Lifecycle Methods
│   │   ├── initState()
│   │   ├── dispose()
│   │   └── didChangeAppLifecycleState()
│   │
│   ├── Camera Methods
│   │   ├── _initializeCamera()
│   │   ├── _requestCameraPermission()
│   │   └── _toggleFlash()
│   │
│   ├── Processing Methods
│   │   ├── _captureAndProcess()
│   │   ├── _processImage()
│   │   └── _parseItemsFromText()
│   │
│   ├── UI Methods
│   │   ├── _showConfirmationDialog()
│   │   ├── _buildCameraPreview()
│   │   ├── _buildErrorView()
│   │   └── _buildLoadingView()
│   │
│   └── build() method
│       └── Scaffold
│           ├── AppBar
│           └── Body (Stack)
│               ├── CameraPreview
│               ├── Scanning Guide Overlay
│               └── Bottom Control Panel
```

## Testing Checklist

- [ ] Camera permission request works on Android
- [ ] Camera permission request works on iOS
- [ ] Camera initializes correctly
- [ ] Camera preview displays properly
- [ ] Capture button takes photo
- [ ] OCR processes image and extracts text
- [ ] Text parsing filters out noise
- [ ] Confirmation dialog shows detected items
- [ ] Items can be edited in confirmation dialog
- [ ] Items can be removed in confirmation dialog
- [ ] New items can be added manually
- [ ] Confirmed items return to calling screen correctly
- [ ] Error handling works for permission denial
- [ ] Error handling works for camera failure
- [ ] Error handling works for OCR failure
- [ ] Flash toggle works
- [ ] App handles lifecycle changes (background/foreground)
- [ ] Memory is properly released on dispose

## Performance Considerations

1. **Image Resolution**: Use `ResolutionPreset.high` for good OCR accuracy without excessive processing time
2. **Memory Management**: Dispose camera controller and ML Kit resources properly
3. **Processing Time**: Show loading indicator during OCR processing (typically 1-3 seconds)
4. **Image Cleanup**: Delete captured image file after processing to save storage

## Future Enhancements (Out of Scope)

- Real-time text detection (continuous scanning)
- Barcode scanning mode
- Multi-language OCR support
- Quantity and unit extraction with regex
- Product name validation against database
- Batch scanning (multiple items at once)
- Image preprocessing for better OCR accuracy

## Dependencies Reference

### Camera Package
```dart
import 'package:camera/camera.dart';
```
- `availableCameras()`: Get list of available cameras
- `CameraController`: Control camera operations
- `CameraPreview`: Display camera feed
- `XFile`: Captured image file

### Google ML Kit
```dart
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
```
- `TextRecognizer`: OCR engine
- `InputImage`: Image input for ML Kit
- `RecognizedText`: OCR result with text blocks

### Permission Handler
```dart
import 'package:permission_handler/permission_handler.dart';
```
- `Permission.camera`: Camera permission
- `request()`: Request permission
- `status`: Check permission status
- `openAppSettings()`: Open app settings

## Implementation Priority

1. **High Priority** (Core Functionality)
   - Camera initialization and preview
   - Image capture
   - OCR text recognition
   - Basic text parsing
   - Return detected items

2. **Medium Priority** (User Experience)
   - Confirmation dialog with edit capability
   - Error handling and user feedback
   - Loading states
   - Permission handling

3. **Low Priority** (Polish)
   - Flash toggle
   - Scanning guide overlay
   - Better text filtering
   - UI animations

## Estimated Implementation Time

- Platform permissions: 15 minutes
- Camera setup: 1 hour
- OCR integration: 1 hour
- Text parsing: 30 minutes
- Confirmation UI: 1 hour
- Error handling: 45 minutes
- Testing & refinement: 1 hour

**Total**: ~5-6 hours

## Success Criteria

✅ Camera opens and shows live preview
✅ Capture button takes a photo
✅ OCR extracts text from the image
✅ Detected items are displayed for confirmation
✅ User can edit/remove/add items
✅ Confirmed items return to calling screen as List<String>
✅ Proper error handling for all failure scenarios
✅ Clean resource management (no memory leaks)