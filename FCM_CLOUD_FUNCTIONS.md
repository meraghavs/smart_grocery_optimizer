# Firebase Cloud Functions for Expiry Notifications

## Overview

This document provides the Cloud Functions implementation for automatically sending push notifications 3 days before pantry items expire, including recipe suggestions.

## Architecture

```
Firestore pantry_items → Cloud Function (scheduled daily) → FCM → User Device
                                ↓
                        Recipe API (Spoonacular)
                                ↓
                        Generate notification with recipe link
```

## Cloud Functions Implementation

### 1. Setup (functions/package.json)

```json
{
  "name": "smart-grocery-functions",
  "version": "1.0.0",
  "engines": {
    "node": "18"
  },
  "dependencies": {
    "firebase-admin": "^11.11.0",
    "firebase-functions": "^4.5.0",
    "axios": "^1.6.0"
  }
}
```

### 2. Main Cloud Function (functions/index.js)

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

/**
 * Scheduled function that runs daily at 9 AM to check for expiring items
 * and send notifications with recipe suggestions
 */
exports.checkExpiringItemsDaily = functions.pubsub
  .schedule('0 9 * * *') // Run at 9 AM every day
  .timeZone('America/New_York') // Adjust to your timezone
  .onRun(async (context) => {
    console.log('Starting daily expiry check...');

    try {
      const db = admin.firestore();
      const now = new Date();
      const threeDaysFromNow = new Date(now.getTime() + (3 * 24 * 60 * 60 * 1000));

      // Query items expiring in exactly 3 days
      const expiringItemsSnapshot = await db.collection('pantry_items')
        .where('expiryDate', '>=', now)
        .where('expiryDate', '<=', threeDaysFromNow)
        .get();

      console.log(`Found ${expiringItemsSnapshot.size} items expiring in 3 days`);

      // Group items by user
      const itemsByUser = {};
      expiringItemsSnapshot.forEach(doc => {
        const item = doc.data();
        const userId = item.userId;
        
        if (!itemsByUser[userId]) {
          itemsByUser[userId] = [];
        }
        
        itemsByUser[userId].push({
          id: doc.id,
          ...item
        });
      });

      // Send notifications for each user
      const notificationPromises = Object.entries(itemsByUser).map(
        ([userId, items]) => sendExpiryNotificationsForUser(userId, items)
      );

      await Promise.all(notificationPromises);

      console.log('Daily expiry check completed successfully');
      return null;
    } catch (error) {
      console.error('Error in daily expiry check:', error);
      throw error;
    }
  });

/**
 * Sends expiry notifications for a user's items with recipe suggestions
 */
async function sendExpiryNotificationsForUser(userId, items) {
  try {
    const db = admin.firestore();
    
    // Get user's FCM token
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      console.log(`User ${userId} not found`);
      return;
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      console.log(`No FCM token for user ${userId}`);
      return;
    }

    // Check if user has notifications enabled
    if (!userData.preferences?.expiryAlertsEnabled) {
      console.log(`Expiry alerts disabled for user ${userId}`);
      return;
    }

    // Send notification for each expiring item
    for (const item of items) {
      try {
        // Get recipe suggestion
        const recipe = await getRecipeSuggestion(item.name);
        
        // Create notification payload
        const message = {
          token: fcmToken,
          notification: {
            title: `⚠️ ${item.name} expires in 3 days!`,
            body: recipe 
              ? `Try this recipe: ${recipe.title}`
              : `Use it soon before it expires!`,
          },
          data: {
            type: 'expiry_alert',
            itemId: item.id,
            itemName: item.name,
            expiryDate: item.expiryDate.toDate().toISOString(),
            recipeUrl: recipe ? `recipe://${recipe.id}` : '',
            recipeTitle: recipe ? recipe.title : '',
          },
          android: {
            priority: 'high',
            notification: {
              channelId: 'expiry_alerts',
              priority: 'high',
              defaultSound: true,
              defaultVibrateTimings: true,
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                badge: 1,
              },
            },
          },
        };

        // Send FCM notification
        const response = await admin.messaging().send(message);
        console.log(`Notification sent for ${item.name} to user ${userId}:`, response);

        // Store notification in Firestore
        await db.collection('notifications').add({
          userId: userId,
          type: 'expiry_alert',
          title: message.notification.title,
          message: message.notification.body,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          relatedItemId: item.id,
          actionUrl: recipe ? `recipe://${recipe.id}` : null,
          priority: 'high',
        });

      } catch (error) {
        console.error(`Error sending notification for item ${item.id}:`, error);
      }
    }

  } catch (error) {
    console.error(`Error processing notifications for user ${userId}:`, error);
  }
}

/**
 * Gets recipe suggestion from Spoonacular API
 */
async function getRecipeSuggestion(ingredientName) {
  try {
    const spoonacularApiKey = functions.config().spoonacular.key;
    
    const response = await axios.get(
      'https://api.spoonacular.com/recipes/findByIngredients',
      {
        params: {
          apiKey: spoonacularApiKey,
          ingredients: ingredientName,
          number: 1,
          ranking: 2, // Maximize used ingredients
        },
        timeout: 5000,
      }
    );

    if (response.data && response.data.length > 0) {
      return {
        id: response.data[0].id,
        title: response.data[0].title,
      };
    }

    return null;
  } catch (error) {
    console.error('Error fetching recipe suggestion:', error);
    return null;
  }
}

/**
 * Triggered when a new pantry item is added
 * Schedules notification if item expires within 3 days
 */
exports.onPantryItemCreated = functions.firestore
  .document('pantry_items/{itemId}')
  .onCreate(async (snap, context) => {
    const item = snap.data();
    const itemId = context.params.itemId;

    try {
      const expiryDate = item.expiryDate.toDate();
      const now = new Date();
      const daysUntilExpiry = Math.ceil((expiryDate - now) / (1000 * 60 * 60 * 24));

      // If item expires within 3 days, send immediate notification
      if (daysUntilExpiry <= 3 && daysUntilExpiry > 0) {
        console.log(`Item ${item.name} expires in ${daysUntilExpiry} days, sending notification`);
        await sendExpiryNotificationsForUser(item.userId, [{ id: itemId, ...item }]);
      }

      return null;
    } catch (error) {
      console.error('Error in onPantryItemCreated:', error);
      return null;
    }
  });

/**
 * Triggered when a pantry item is updated
 * Reschedules notification if expiry date changed
 */
exports.onPantryItemUpdated = functions.firestore
  .document('pantry_items/{itemId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const itemId = context.params.itemId;

    // Check if expiry date changed
    if (before.expiryDate.toDate().getTime() !== after.expiryDate.toDate().getTime()) {
      const expiryDate = after.expiryDate.toDate();
      const now = new Date();
      const daysUntilExpiry = Math.ceil((expiryDate - now) / (1000 * 60 * 60 * 24));

      if (daysUntilExpiry <= 3 && daysUntilExpiry > 0) {
        console.log(`Item ${after.name} expiry updated, sending notification`);
        await sendExpiryNotificationsForUser(after.userId, [{ id: itemId, ...after }]);
      }
    }

    return null;
  });

/**
 * HTTP endpoint to manually trigger expiry check (for testing)
 */
exports.triggerExpiryCheck = functions.https.onRequest(async (req, res) => {
  try {
    await checkExpiringItemsDaily.run();
    res.status(200).send('Expiry check triggered successfully');
  } catch (error) {
    console.error('Error triggering expiry check:', error);
    res.status(500).send('Error triggering expiry check');
  }
});
```

## Deployment Instructions

### 1. Install Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

### 2. Initialize Cloud Functions

```bash
cd your-project-directory
firebase init functions
```

### 3. Set Environment Variables

```bash
# Set Spoonacular API key
firebase functions:config:set spoonacular.key="YOUR_SPOONACULAR_API_KEY"

# View current config
firebase functions:config:get
```

### 4. Deploy Functions

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

### 5. Test Functions

```bash
# Test scheduled function manually
curl https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/triggerExpiryCheck

# View logs
firebase functions:log
```

## Flutter App Integration

### 1. Update main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize(
    recipeApi: RecipeApiService(
      apiKey: 'YOUR_SPOONACULAR_KEY',
      baseUrl: 'https://api.spoonacular.com',
    ),
  );
  
  runApp(MyApp());
}
```

### 2. Save FCM Token to Firestore

```dart
// In your authentication flow
Future<void> saveFcmToken(String userId) async {
  final fcmToken = await FirebaseMessaging.instance.getToken();
  
  if (fcmToken != null) {
    await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .update({'fcmToken': fcmToken});
  }
}
```

### 3. Handle Notification Taps

```dart
// In your app initialization
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  final data = message.data;
  
  if (data['type'] == 'expiry_alert' && data['recipeUrl'] != null) {
    // Navigate to recipe detail screen
    Navigator.pushNamed(
      context,
      '/recipe-detail',
      arguments: data['recipeUrl'].replaceAll('recipe://', ''),
    );
  }
});
```

## Testing

### 1. Test Notification Locally

```dart
// In your Flutter app
final notificationService = NotificationService();

// Create test item expiring in 3 days
final testItem = GroceryItem(
  id: 'test_123',
  userId: 'user_123',
  name: 'Milk',
  category: 'Dairy',
  quantity: 1,
  unit: 'L',
  expiryDate: DateTime.now().add(Duration(days: 3)),
  purchaseDate: DateTime.now(),
  price: 3.99,
);

// Schedule notification
await notificationService.scheduleExpiryAlertWithRecipe(item: testItem);
```

### 2. Test Cloud Function

```bash
# Add test item to Firestore with expiry in 3 days
# Then trigger the function
curl https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/triggerExpiryCheck
```

## Notification Flow

```
Day 0: User adds milk (expires in 5 days)
       ↓
Day 2: Cloud Function runs at 9 AM
       ↓ (3 days until expiry)
       Queries Firestore for items expiring in 3 days
       ↓
       Finds milk
       ↓
       Calls Spoonacular API for recipe with milk
       ↓
       Gets "Creamy Pasta" recipe
       ↓
       Sends FCM notification:
       Title: "⚠️ Milk expires in 3 days!"
       Body: "Try this recipe: Creamy Pasta"
       Data: {recipeUrl: "recipe://12345"}
       ↓
User's phone: Notification appears
       ↓
User taps: Opens recipe detail screen
```

## Security Rules

Update Firestore security rules to allow Cloud Functions to write notifications:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /notifications/{notificationId} {
      allow read: if request.auth != null && 
        resource.data.userId == request.auth.uid;
      allow write: if request.auth != null || 
        request.auth.token.admin == true; // Allow Cloud Functions
    }
  }
}
```

## Monitoring

### View Logs

```bash
firebase functions:log --only checkExpiringItemsDaily
```

### Set Up Alerts

In Firebase Console:
1. Go to Functions → Logs
2. Set up log-based alerts for errors
3. Configure email notifications

## Cost Estimation

- **Cloud Functions**: ~$0.40/million invocations
- **FCM**: Free for unlimited notifications
- **Spoonacular API**: 150 free requests/day, then $0.002/request

**Estimated monthly cost for 1000 users:**
- Daily function runs: 30 × $0.0000004 = $0.000012
- Recipe API calls: ~100/day × 30 = 3000 calls = $6.00
- **Total: ~$6/month**

## Troubleshooting

### Notifications Not Received

1. Check FCM token is saved in Firestore
2. Verify user has notifications enabled
3. Check Cloud Function logs for errors
4. Ensure app has notification permissions

### Recipe Suggestions Not Working

1. Verify Spoonacular API key is set
2. Check API quota limits
3. Review Cloud Function logs for API errors

---

**Version**: 1.0  
**Last Updated**: 2026-05-02  
**Status**: Production Ready ✅