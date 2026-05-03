# Scanner Screen Architecture

## Component Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        ScannerScreen                             │
│                      (StatefulWidget)                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    _ScannerScreenState                           │
│                                                                   │
│  State Variables:                                                │
│  • CameraController? _cameraController                           │
│  • TextRecognizer _textRecognizer                                │
│  • bool _isCameraInitialized                                     │
│  • bool _isProcessing                                            │
│  • String? _errorMessage                                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────┴─────────────────────┐
        │                                             │
        ▼                                             ▼
┌──────────────────┐                      ┌──────────────────────┐
│   initState()    │                      │     dispose()        │
│                  │                      │                      │
│ • Request perms  │                      │ • Dispose camera     │
│ • Init camera    │                      │ • Close ML Kit       │
└──────────────────┘                      └──────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│              Camera Initialization Flow                          │
│                                                                   │
│  1. Request Permission (permission_handler)                      │
│     ├─ Granted → Continue                                        │
│     └─ Denied → Show error + Settings button                     │
│                                                                   │
│  2. Get Available Cameras (availableCameras())                   │
│     ├─ Found → Select back camera                                │
│     └─ None → Show "No camera" error                             │
│                                                                   │
│  3. Initialize CameraController                                  │
│     • Camera: back camera                                        │
│     • Resolution: ResolutionPreset.high                          │
│     • Audio: disabled                                            │
│                                                                   │
│  4. Wait for initialization (await controller.initialize())      │
│                                                                   │
│  5. Update state: _isCameraInitialized = true                    │
└─────────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│                        UI Build Tree                             │
│                                                                   │
│  Scaffold                                                        │
│  ├─ AppBar                                                       │
│  │  ├─ Title: "Scan Grocery Item"                               │
│  │  └─ Actions: [Flash Toggle Button]                           │
│  │                                                               │
│  └─ Body: Stack                                                  │
│     ├─ Layer 1: CameraPreview (full screen)                     │
│     │                                                            │
│     ├─ Layer 2: Scanning Guide Overlay (optional)               │
│     │  └─ Semi-transparent rectangle with corners                │
│     │                                                            │
│     └─ Layer 3: Bottom Control Panel                            │
│        └─ Positioned(bottom: 0)                                  │
│           ├─ Instruction text                                    │
│           └─ Capture Button (FAB)                                │
│              • Normal: Camera icon                               │
│              • Processing: CircularProgressIndicator             │
└─────────────────────────────────────────────────────────────────┘
        │
        │ (User taps capture button)
        ▼
┌─────────────────────────────────────────────────────────────────┐
│              Image Capture & Processing Flow                     │
│                                                                   │
│  1. _captureAndProcess() called                                  │
│     └─ setState(() => _isProcessing = true)                      │
│                                                                   │
│  2. Capture Image                                                │
│     └─ XFile image = await _cameraController!.takePicture()      │
│                                                                   │
│  3. Convert to InputImage                                        │
│     └─ InputImage inputImage =                                   │
│        InputImage.fromFilePath(image.path)                       │
│                                                                   │
│  4. Process with ML Kit OCR                                      │
│     └─ RecognizedText result =                                   │
│        await _textRecognizer.processImage(inputImage)            │
│                                                                   │
│  5. Extract Text                                                 │
│     └─ String fullText = result.text                             │
│                                                                   │
│  6. Parse Items                                                  │
│     └─ List<String> items = _parseItemsFromText(fullText)        │
│                                                                   │
│  7. Show Confirmation                                            │
│     └─ await _showConfirmationDialog(items)                      │
│                                                                   │
│  8. Return Results                                               │
│     └─ Navigator.pop(context, confirmedItems)                    │
│                                                                   │
│  9. Cleanup                                                      │
│     └─ setState(() => _isProcessing = false)                     │
└─────────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Text Parsing Logic                             │
│                                                                   │
│  Input: Raw OCR text (multi-line string)                         │
│                                                                   │
│  Process:                                                        │
│  1. Split by newlines: text.split('\n')                          │
│  2. Trim whitespace: line.trim()                                 │
│  3. Filter empty lines: line.isNotEmpty                          │
│  4. Filter short text: line.length > 2                           │
│  5. Filter numeric-only: !isNumeric(line)                        │
│  6. Filter symbol-only: !isSymbolOnly(line)                      │
│                                                                   │
│  Output: List<String> of potential item names                    │
│                                                                   │
│  Example:                                                        │
│  Input:  "WHOLE MILK\n1L\n$3.99\nEXP: 05/15\nBRAND NAME"        │
│  Output: ["WHOLE MILK", "BRAND NAME"]                            │
└─────────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Confirmation Dialog                             │
│                                                                   │
│  AlertDialog                                                     │
│  ├─ Title: "Detected Items"                                      │
│  │                                                               │
│  ├─ Content: SingleChildScrollView                               │
│  │  └─ Column                                                    │
│  │     ├─ For each detected item:                                │
│  │     │  └─ ListTile                                            │
│  │     │     ├─ Leading: Drag handle icon                        │
│  │     │     ├─ Title: TextField (editable)                      │
│  │     │     └─ Trailing: Delete IconButton                      │
│  │     │                                                          │
│  │     └─ Add Item Button                                        │
│  │        └─ Opens dialog to add new item manually               │
│  │                                                               │
│  └─ Actions                                                      │
│     ├─ Cancel Button                                             │
│     │  └─ Navigator.pop(context) // No return                    │
│     │                                                            │
│     └─ Confirm Button                                            │
│        └─ Navigator.pop(context) // Close dialog                 │
│           Navigator.pop(context, items) // Return to caller      │
└─────────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Return to Caller                              │
│                                                                   │
│  Data Format: List<String>                                       │
│                                                                   │
│  Example:                                                        │
│  [                                                               │
│    "Whole Milk",                                                 │
│    "Organic Bread",                                              │
│    "Fresh Eggs"                                                  │
│  ]                                                               │
│                                                                   │
│  Caller receives via:                                            │
│  final items = await Navigator.push(                             │
│    context,                                                      │
│    MaterialPageRoute(                                            │
│      builder: (context) => ScannerScreen()                       │
│    )                                                             │
│  );                                                              │
└─────────────────────────────────────────────────────────────────┘
```

## Error Handling Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                      Error Scenarios                             │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  Permission  │    │  Camera Init     │    │  OCR Failed     │
│   Denied     │    │    Failed        │    │                 │
└──────────────┘    └──────────────────┘    └─────────────────┘
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ Show Error   │    │ Show Error       │    │ Show Snackbar   │
│ + Settings   │    │ + Retry Button   │    │ + Retry Capture │
│   Button     │    │                  │    │                 │
└──────────────┘    └──────────────────┘    └─────────────────┘
```

## State Management

```
┌─────────────────────────────────────────────────────────────────┐
│                        State Variables                           │
└─────────────────────────────────────────────────────────────────┘

_isCameraInitialized: bool
├─ false → Show loading spinner
└─ true → Show camera preview

_isProcessing: bool
├─ false → Capture button enabled
└─ true → Show processing indicator

_errorMessage: String?
├─ null → Normal operation
└─ "error text" → Show error view

_cameraController: CameraController?
├─ null → Not initialized
└─ initialized → Ready for capture

_textRecognizer: TextRecognizer
└─ Always initialized (singleton)
```

## Lifecycle Management

```
┌─────────────────────────────────────────────────────────────────┐
│                    App Lifecycle States                          │
└─────────────────────────────────────────────────────────────────┘

resumed (foreground)
└─ Resume camera if initialized

paused (background)
└─ Pause camera to save battery

inactive (transitioning)
└─ No action needed

detached (app closing)
└─ Dispose resources
```

## Memory Management

```
┌─────────────────────────────────────────────────────────────────┐
│                    Resource Cleanup                              │
└─────────────────────────────────────────────────────────────────┘

dispose() called:
├─ _cameraController?.dispose()
├─ _textRecognizer.close()
└─ Delete temporary image files

After OCR processing:
└─ Delete captured image file (XFile)
```

## Dependencies Integration

```
┌─────────────────────────────────────────────────────────────────┐
│                    Package Dependencies                          │
└─────────────────────────────────────────────────────────────────┘

camera: ^0.12.0+1
├─ availableCameras() → List<CameraDescription>
├─ CameraController → Control camera
├─ CameraPreview → Display feed
└─ takePicture() → XFile

google_ml_kit: ^0.21.0
└─ google_mlkit_text_recognition
   ├─ TextRecognizer() → OCR engine
   ├─ InputImage.fromFilePath() → Convert image
   └─ processImage() → RecognizedText

permission_handler: ^12.0.1
├─ Permission.camera → Camera permission
├─ request() → Request permission
├─ status → Check status
└─ openAppSettings() → Open settings
```

## Performance Optimization

```
┌─────────────────────────────────────────────────────────────────┐
│                  Performance Considerations                      │
└─────────────────────────────────────────────────────────────────┘

Image Resolution
└─ ResolutionPreset.high
   ├─ Good OCR accuracy
   ├─ Reasonable file size
   └─ Fast processing (~1-3 seconds)

Memory Usage
├─ Dispose camera when not needed
├─ Close ML Kit resources
└─ Delete temporary files

UI Responsiveness
├─ Show loading indicators
├─ Process OCR asynchronously
└─ Don't block UI thread
```

## Testing Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│                      Test Scenarios                              │
└─────────────────────────────────────────────────────────────────┘

Unit Tests
├─ Text parsing logic
├─ Item filtering
└─ Data format validation

Widget Tests
├─ UI renders correctly
├─ Buttons respond to taps
└─ State updates properly

Integration Tests
├─ Camera initialization
├─ Image capture
├─ OCR processing
└─ Navigation flow

Manual Tests
├─ Various lighting conditions
├─ Different product labels
├─ Multiple languages
└─ Edge cases (no text, blurry)
```

## Security & Privacy

```
┌─────────────────────────────────────────────────────────────────┐
│                  Privacy Considerations                          │
└─────────────────────────────────────────────────────────────────┘

Camera Access
└─ Request permission with clear explanation

Image Storage
├─ Temporary files only
├─ Delete after processing
└─ No cloud upload

Data Handling
├─ Process locally (on-device)
├─ No external API calls
└─ User controls all data