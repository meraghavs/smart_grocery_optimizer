# Firestore Schema - Smart Grocery Optimizer

## 📋 Overview

This document defines the complete Firestore database schema for the Smart Grocery Optimizer application, including collections for users, pantry items with expiry tracking, shopping lists, and spending history.

## 🗂️ Database Structure

```
firestore/
├── users/                          # User profiles and preferences
│   └── {userId}/
│       ├── profile data
│       └── preferences/            # Subcollection
│
├── pantry_items/                   # Grocery items with expiry dates
│   └── {itemId}/
│
├── shopping_lists/                 # Shopping lists
│   └── {listId}/
│       └── items/                  # Subcollection
│
├── budget_entries/                 # Spending history
│   └── {entryId}/
│
├── recipes/                        # Saved recipes
│   └── {recipeId}/
│
└── notifications/                  # User notifications
    └── {notificationId}/
```

## 📊 Collection Schemas

### 1. Users Collection

**Path**: `/users/{userId}`

**Purpose**: Store user profiles, preferences, and settings

**Document Structure**:
```json
{
  "userId": "string (document ID)",
  "email": "string",
  "displayName": "string",
  "photoUrl": "string | null",
  "createdAt": "timestamp",
  "lastLoginAt": "timestamp",
  "preferences": {
    "notificationsEnabled": "boolean",
    "expiryAlertsEnabled": "boolean",
    "expiryAlertDays": "number (default: 3)",
    "currency": "string (default: 'USD')",
    "measurementSystem": "string ('metric' | 'imperial')",
    "dietaryRestrictions": ["string"],
    "allergens": ["string"],
    "monthlyBudget": "number | null"
  },
  "stats": {
    "totalPantryItems": "number",
    "totalRecipesSaved": "number",
    "totalSpent": "number",
    "itemsExpiredThisMonth": "number"
  }
}
```

**Indexes**:
- `email` (ascending)
- `createdAt` (descending)

**Security Rules**:
```javascript
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

**Example Document**:
```json
{
  "userId": "user123",
  "email": "john@example.com",
  "displayName": "John Doe",
  "photoUrl": "https://example.com/photo.jpg",
  "createdAt": "2026-05-01T10:00:00Z",
  "lastLoginAt": "2026-05-02T07:00:00Z",
  "preferences": {
    "notificationsEnabled": true,
    "expiryAlertsEnabled": true,
    "expiryAlertDays": 3,
    "currency": "USD",
    "measurementSystem": "metric",
    "dietaryRestrictions": ["vegetarian"],
    "allergens": ["peanuts", "shellfish"],
    "monthlyBudget": 500.00
  },
  "stats": {
    "totalPantryItems": 45,
    "totalRecipesSaved": 12,
    "totalSpent": 342.50,
    "itemsExpiredThisMonth": 2
  }
}
```

---

### 2. Pantry Items Collection

**Path**: `/pantry_items/{itemId}`

**Purpose**: Store grocery items with expiry dates and tracking

**Document Structure**:
```json
{
  "itemId": "string (document ID)",
  "userId": "string (indexed)",
  "name": "string",
  "category": "string",
  "quantity": "number",
  "unit": "string",
  "expiryDate": "timestamp",
  "purchaseDate": "timestamp",
  "price": "number",
  "imageUrl": "string | null",
  "barcode": "string | null",
  "isExpired": "boolean (computed)",
  "daysUntilExpiry": "number (computed)",
  "status": "string ('fresh' | 'expiring_soon' | 'expired')",
  "addedBy": "string ('manual' | 'scan' | 'receipt')",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Indexes**:
- `userId` (ascending) + `expiryDate` (ascending)
- `userId` (ascending) + `category` (ascending)
- `userId` (ascending) + `status` (ascending)
- `userId` (ascending) + `createdAt` (descending)

**Security Rules**:
```javascript
match /pantry_items/{itemId} {
  allow read, write: if request.auth != null && 
    request.resource.data.userId == request.auth.uid;
  allow delete: if request.auth != null && 
    resource.data.userId == request.auth.uid;
}
```

**Example Document**:
```json
{
  "itemId": "item_abc123",
  "userId": "user123",
  "name": "Milk",
  "category": "Dairy",
  "quantity": 1,
  "unit": "L",
  "expiryDate": "2026-05-05T00:00:00Z",
  "purchaseDate": "2026-05-01T10:30:00Z",
  "price": 3.99,
  "imageUrl": "https://storage.googleapis.com/bucket/milk.jpg",
  "barcode": "1234567890123",
  "isExpired": false,
  "daysUntilExpiry": 3,
  "status": "expiring_soon",
  "addedBy": "scan",
  "createdAt": "2026-05-01T10:30:00Z",
  "updatedAt": "2026-05-01T10:30:00Z"
}
```

**Query Examples**:
```dart
// Get all pantry items for a user
pantryItems.where('userId', isEqualTo: userId).get()

// Get items expiring soon (within 7 days)
pantryItems
  .where('userId', isEqualTo: userId)
  .where('status', isEqualTo: 'expiring_soon')
  .orderBy('expiryDate', descending: false)
  .get()

// Get items by category
pantryItems
  .where('userId', isEqualTo: userId)
  .where('category', isEqualTo: 'Dairy')
  .get()
```

---

### 3. Shopping Lists Collection

**Path**: `/shopping_lists/{listId}`

**Purpose**: Store shopping lists with items

**Document Structure**:
```json
{
  "listId": "string (document ID)",
  "userId": "string (indexed)",
  "name": "string",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "completedAt": "timestamp | null",
  "isCompleted": "boolean",
  "estimatedTotal": "number | null",
  "actualTotal": "number | null",
  "storeLocation": "string | null",
  "itemsCount": "number",
  "checkedItemsCount": "number",
  "sharedWith": ["string (userIds)"]
}
```

**Subcollection**: `/shopping_lists/{listId}/items/{itemId}`

**Item Structure**:
```json
{
  "itemId": "string (document ID)",
  "name": "string",
  "quantity": "number",
  "unit": "string",
  "category": "string | null",
  "isChecked": "boolean",
  "price": "number | null",
  "notes": "string | null",
  "addedAt": "timestamp",
  "checkedAt": "timestamp | null",
  "order": "number"
}
```

**Indexes**:
- `userId` (ascending) + `createdAt` (descending)
- `userId` (ascending) + `isCompleted` (ascending)

**Security Rules**:
```javascript
match /shopping_lists/{listId} {
  allow read: if request.auth != null && (
    resource.data.userId == request.auth.uid ||
    request.auth.uid in resource.data.sharedWith
  );
  allow write: if request.auth != null && 
    request.resource.data.userId == request.auth.uid;
  
  match /items/{itemId} {
    allow read, write: if request.auth != null;
  }
}
```

**Example Documents**:

Shopping List:
```json
{
  "listId": "list_xyz789",
  "userId": "user123",
  "name": "Weekly Groceries",
  "createdAt": "2026-05-01T08:00:00Z",
  "updatedAt": "2026-05-02T07:00:00Z",
  "completedAt": null,
  "isCompleted": false,
  "estimatedTotal": 85.50,
  "actualTotal": null,
  "storeLocation": "Walmart - Main St",
  "itemsCount": 12,
  "checkedItemsCount": 5,
  "sharedWith": ["user456"]
}
```

Shopping List Item:
```json
{
  "itemId": "item_001",
  "name": "Milk",
  "quantity": 2,
  "unit": "L",
  "category": "Dairy",
  "isChecked": false,
  "price": 3.99,
  "notes": "Get organic if available",
  "addedAt": "2026-05-01T08:00:00Z",
  "checkedAt": null,
  "order": 1
}
```

---

### 4. Budget Entries Collection

**Path**: `/budget_entries/{entryId}`

**Purpose**: Track spending history and expenses

**Document Structure**:
```json
{
  "entryId": "string (document ID)",
  "userId": "string (indexed)",
  "amount": "number",
  "category": "string",
  "date": "timestamp",
  "description": "string",
  "type": "string ('expense' | 'income')",
  "receiptImageUrl": "string | null",
  "itemIds": ["string (pantry item IDs)"],
  "shoppingListId": "string | null",
  "store": "string | null",
  "paymentMethod": "string | null",
  "tags": ["string"],
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Indexes**:
- `userId` (ascending) + `date` (descending)
- `userId` (ascending) + `category` (ascending) + `date` (descending)
- `userId` (ascending) + `type` (ascending) + `date` (descending)

**Security Rules**:
```javascript
match /budget_entries/{entryId} {
  allow read, write: if request.auth != null && 
    request.resource.data.userId == request.auth.uid;
  allow delete: if request.auth != null && 
    resource.data.userId == request.auth.uid;
}
```

**Example Document**:
```json
{
  "entryId": "entry_def456",
  "userId": "user123",
  "amount": 45.67,
  "category": "Groceries",
  "date": "2026-05-01T14:30:00Z",
  "description": "Weekly grocery shopping",
  "type": "expense",
  "receiptImageUrl": "https://storage.googleapis.com/bucket/receipt_001.jpg",
  "itemIds": ["item_abc123", "item_abc124", "item_abc125"],
  "shoppingListId": "list_xyz789",
  "store": "Walmart",
  "paymentMethod": "Credit Card",
  "tags": ["weekly", "essentials"],
  "createdAt": "2026-05-01T14:30:00Z",
  "updatedAt": "2026-05-01T14:30:00Z"
}
```

**Query Examples**:
```dart
// Get spending for current month
budgetEntries
  .where('userId', isEqualTo: userId)
  .where('type', isEqualTo: 'expense')
  .where('date', isGreaterThanOrEqualTo: startOfMonth)
  .where('date', isLessThan: endOfMonth)
  .get()

// Get spending by category
budgetEntries
  .where('userId', isEqualTo: userId)
  .where('category', isEqualTo: 'Groceries')
  .orderBy('date', descending: true)
  .limit(50)
  .get()
```

---

### 5. Recipes Collection (Saved)

**Path**: `/recipes/{recipeId}`

**Purpose**: Store user's saved/favorite recipes

**Document Structure**:
```json
{
  "recipeId": "string (document ID)",
  "userId": "string (indexed)",
  "spoonacularId": "string | null",
  "title": "string",
  "description": "string",
  "ingredients": ["string"],
  "instructions": ["string"],
  "prepTime": "number",
  "cookTime": "number",
  "servings": "number",
  "imageUrl": "string | null",
  "tags": ["string"],
  "rating": "number | null",
  "isFavorite": "boolean",
  "timesCooked": "number",
  "lastCookedAt": "timestamp | null",
  "savedAt": "timestamp",
  "source": "string ('spoonacular' | 'watson' | 'manual')"
}
```

**Indexes**:
- `userId` (ascending) + `savedAt` (descending)
- `userId` (ascending) + `isFavorite` (ascending)

**Security Rules**:
```javascript
match /recipes/{recipeId} {
  allow read, write: if request.auth != null && 
    request.resource.data.userId == request.auth.uid;
}
```

---

### 6. Notifications Collection

**Path**: `/notifications/{notificationId}`

**Purpose**: Store user notifications for expiry alerts, budget warnings, etc.

**Document Structure**:
```json
{
  "notificationId": "string (document ID)",
  "userId": "string (indexed)",
  "type": "string ('expiry_alert' | 'budget_warning' | 'shopping_reminder')",
  "title": "string",
  "message": "string",
  "isRead": "boolean",
  "createdAt": "timestamp",
  "readAt": "timestamp | null",
  "relatedItemId": "string | null",
  "actionUrl": "string | null",
  "priority": "string ('low' | 'medium' | 'high')"
}
```

**Indexes**:
- `userId` (ascending) + `isRead` (ascending) + `createdAt` (descending)

---

## 🔐 Security Rules Summary

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    // Users
    match /users/{userId} {
      allow read, write: if isAuthenticated() && isOwner(userId);
    }
    
    // Pantry Items
    match /pantry_items/{itemId} {
      allow read: if isAuthenticated() && 
        resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() && 
        request.resource.data.userId == request.auth.uid;
      allow update, delete: if isAuthenticated() && 
        resource.data.userId == request.auth.uid;
    }
    
    // Shopping Lists
    match /shopping_lists/{listId} {
      allow read: if isAuthenticated() && (
        resource.data.userId == request.auth.uid ||
        request.auth.uid in resource.data.sharedWith
      );
      allow write: if isAuthenticated() && 
        request.resource.data.userId == request.auth.uid;
      
      match /items/{itemId} {
        allow read, write: if isAuthenticated();
      }
    }
    
    // Budget Entries
    match /budget_entries/{entryId} {
      allow read: if isAuthenticated() && 
        resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() && 
        request.resource.data.userId == request.auth.uid;
      allow update, delete: if isAuthenticated() && 
        resource.data.userId == request.auth.uid;
    }
    
    // Recipes
    match /recipes/{recipeId} {
      allow read, write: if isAuthenticated() && 
        request.resource.data.userId == request.auth.uid;
    }
    
    // Notifications
    match /notifications/{notificationId} {
      allow read, write: if isAuthenticated() && 
        resource.data.userId == request.auth.uid;
    }
  }
}
```

## 📈 Data Aggregation Strategies

### Monthly Spending Summary
```dart
// Use Cloud Functions to aggregate
// Triggered on budget_entries write
exports.updateMonthlySpending = functions.firestore
  .document('budget_entries/{entryId}')
  .onWrite(async (change, context) => {
    // Aggregate spending by month
    // Update user stats
  });
```

### Expiry Status Updates
```dart
// Scheduled Cloud Function (daily)
exports.updateExpiryStatus = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    // Update isExpired and status fields
    // Send notifications for expiring items
  });
```

## 🔍 Common Queries

### Get Expiring Items
```dart
final expiringItems = await FirebaseFirestore.instance
  .collection('pantry_items')
  .where('userId', isEqualTo: userId)
  .where('status', isEqualTo: 'expiring_soon')
  .orderBy('expiryDate')
  .get();
```

### Get Monthly Budget Summary
```dart
final monthStart = DateTime(year, month, 1);
final monthEnd = DateTime(year, month + 1, 1);

final expenses = await FirebaseFirestore.instance
  .collection('budget_entries')
  .where('userId', isEqualTo: userId)
  .where('type', isEqualTo: 'expense')
  .where('date', isGreaterThanOrEqualTo: monthStart)
  .where('date', isLessThan: monthEnd)
  .get();
```

### Get Active Shopping Lists
```dart
final activeLists = await FirebaseFirestore.instance
  .collection('shopping_lists')
  .where('userId', isEqualTo: userId)
  .where('isCompleted', isEqualTo: false)
  .orderBy('createdAt', descending: true)
  .get();
```

## 💡 Best Practices

1. **Use Timestamps**: Always use Firestore timestamps for dates
2. **Index Strategically**: Create composite indexes for common queries
3. **Denormalize When Needed**: Store computed values (itemsCount, totalSpent)
4. **Batch Operations**: Use batch writes for multiple updates
5. **Offline Support**: Enable offline persistence
6. **Security First**: Always validate userId in security rules
7. **Subcollections**: Use for one-to-many relationships (shopping list items)
8. **Cloud Functions**: Use for aggregations and scheduled tasks

## 🚀 Implementation Example

```dart
// Add pantry item
Future<void> addPantryItem(GroceryItem item) async {
  await FirebaseFirestore.instance
    .collection('pantry_items')
    .doc(item.id)
    .set({
      'userId': currentUserId,
      'name': item.name,
      'category': item.category,
      'quantity': item.quantity,
      'unit': item.unit,
      'expiryDate': Timestamp.fromDate(item.expiryDate),
      'purchaseDate': Timestamp.fromDate(item.purchaseDate),
      'price': item.price,
      'imageUrl': item.imageUrl,
      'barcode': item.barcode,
      'status': _calculateStatus(item.expiryDate),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
}
```

---

**Schema Version**: 1.0  
**Last Updated**: 2026-05-02  
**Status**: Production Ready ✅