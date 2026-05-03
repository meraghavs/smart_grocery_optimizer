# Watson Visual Recognition Setup Guide

This guide explains how to set up IBM Watson Visual Recognition for AI-powered grocery item identification in the Smart Grocery Optimizer app.

## Overview

The app uses IBM Watson Visual Recognition API to identify grocery items from photos. When you take a picture of a tomato, for example, Watson AI will automatically recognize it and suggest adding it to your shopping list with the appropriate category.

## Features

- **AI Image Recognition**: Identifies grocery items from photos (fruits, vegetables, dairy, meat, etc.)
- **Confidence Scores**: Shows how confident the AI is about each identification
- **Category Detection**: Automatically categorizes items (Fruit, Vegetable, Dairy, etc.)
- **Dual Mode**: Switch between AI recognition and OCR text reading
- **Fallback Support**: Falls back to OCR if AI recognition fails

## Setup Instructions

### 1. Get IBM Watson Credentials

1. Sign up for IBM Cloud account at https://cloud.ibm.com/
2. Create a Watson Visual Recognition service instance
3. Get your API key and service URL from the credentials page

### 2. Configure the App

#### Option A: Environment Variables (Recommended for Production)

Set these environment variables:

```bash
export WATSON_API_KEY="your-api-key-here"
export WATSON_API_URL="your-api-url-here"
export WATSON_VISUAL_RECOGNITION_URL="your-visual-recognition-url-here"
```

#### Option B: Configuration File (For Development)

Create a file `lib/config/watson_config.dart`:

```dart
class WatsonConfig {
  static const String apiKey = 'YOUR_WATSON_API_KEY';
  static const String apiUrl = 'YOUR_WATSON_API_URL';
  static const String visualRecognitionUrl = 'YOUR_WATSON_VISUAL_RECOGNITION_URL';
}
```

**Important**: Add this file to `.gitignore` to keep credentials secure!

#### Option C: Update Scanner Screen Directly

Edit `lib/screens/scanner_screen.dart` and replace the placeholder values in the `_initializeWatsonService()` method:

```dart
_watsonService = WatsonService(
  apiKey: 'YOUR_WATSON_API_KEY',
  apiUrl: 'YOUR_WATSON_API_URL',
  visualRecognitionUrl: 'YOUR_WATSON_VISUAL_RECOGNITION_URL',
);
```

### 3. Update .gitignore

Add these lines to `.gitignore` to prevent committing credentials:

```
# Watson credentials
lib/config/watson_config.dart
.env
```

## Usage

### In the App

1. Open the Shopping List screen
2. Tap the camera icon in the app bar
3. The scanner opens in **AI Mode** by default (blue badge)
4. Point camera at a grocery item (e.g., tomato, apple, milk carton)
5. Tap the camera button to capture
6. Watson AI will identify the item with confidence scores
7. Select items to add to your shopping list

### Switching Modes

- Tap the **AI/OCR icon** in the app bar to switch modes
- **AI Mode** (🤖): Identifies items from images
- **OCR Mode** (📝): Reads text from product labels

### Tips for Best Results

**AI Mode:**
- Use good lighting
- Center the item in the frame
- Avoid cluttered backgrounds
- Hold camera steady
- Get close enough to see details

**OCR Mode:**
- Point at product labels with clear text
- Ensure text is readable and in focus
- Works best with printed labels

## API Response Format

Watson Visual Recognition returns items in this format:

```json
{
  "images": [{
    "objects": {
      "collections": [{
        "objects": [{
          "class": "food/fruit/apple",
          "score": 0.95
        }]
      }]
    },
    "food": {
      "items": [{
        "name": "apple",
        "score": 0.95
      }]
    }
  }]
}
```

The app parses this and displays:
- **Name**: Apple
- **Category**: Fruit
- **Confidence**: 95%

## Troubleshooting

### "Watson AI recognition failed"

- Check your API credentials are correct
- Verify your IBM Cloud account is active
- Ensure you have API quota remaining
- Check internet connection

### "No Items Found"

- Try better lighting
- Move closer to the item
- Ensure item is clearly visible
- Switch to OCR mode for product labels
- Try a different angle

### App Falls Back to OCR

This is normal behavior when:
- Watson service is not configured
- API call fails
- No items detected with sufficient confidence
- Network issues occur

## Cost Considerations

- IBM Watson Visual Recognition has a free tier with limited API calls
- Monitor your usage in IBM Cloud dashboard
- Consider implementing caching for frequently scanned items
- The app automatically falls back to free OCR if Watson fails

## Security Best Practices

1. **Never commit API keys** to version control
2. Use environment variables in production
3. Rotate API keys regularly
4. Monitor API usage for unusual activity
5. Use separate keys for development and production

## Alternative Services

If Watson Visual Recognition is not available, consider:

1. **Google Cloud Vision API**: Similar functionality, different pricing
2. **AWS Rekognition**: Amazon's image recognition service
3. **TensorFlow Lite**: On-device ML models (no API costs)
4. **Custom ML Models**: Train your own grocery recognition model

## Support

For issues with:
- **Watson API**: Contact IBM Cloud Support
- **App Integration**: Check the app logs and error messages
- **Feature Requests**: Open an issue in the project repository

## References

- [IBM Watson Visual Recognition Docs](https://cloud.ibm.com/docs/visual-recognition)
- [IBM Cloud Console](https://cloud.ibm.com/)
- [Watson API Reference](https://cloud.ibm.com/apidocs/visual-recognition)

---

**Note**: IBM Watson Visual Recognition was deprecated in December 2021. This implementation is designed to work with IBM watsonx or alternative visual recognition services. Update the API endpoints accordingly for your chosen service.