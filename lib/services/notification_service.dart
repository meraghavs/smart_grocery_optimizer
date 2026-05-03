import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/grocery_item.dart';
import 'recipe_api.dart';

/// Service for Firebase Cloud Messaging and local notifications
/// 
/// Handles push notifications including:
/// - Expiry alerts 3 days before items expire
/// - Budget warnings
/// - Shopping reminders
/// - Recipe suggestions for expiring items
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  late RecipeApiService _recipeApi;
  String? _fcmToken;

  /// Initializes Firebase Cloud Messaging and local notifications
  Future<void> initialize({required RecipeApiService recipeApi}) async {
    _recipeApi = recipeApi;

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    // Request FCM permissions
    await requestPermissions();

    // Get FCM token
    _fcmToken = await _fcm.getToken();
    print('FCM Token: $_fcmToken');

    // Listen to token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      print('FCM Token refreshed: $newToken');
      // TODO: Send token to backend
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle notification when app is terminated
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  /// Creates Android notification channels
  Future<void> _createNotificationChannels() async {
    const expiryChannel = AndroidNotificationChannel(
      'expiry_alerts',
      'Expiry Alerts',
      description: 'Notifications for items about to expire',
      importance: Importance.high,
      playSound: true,
    );

    const budgetChannel = AndroidNotificationChannel(
      'budget_warnings',
      'Budget Warnings',
      description: 'Notifications for budget alerts',
      importance: Importance.high,
      playSound: true,
    );

    const reminderChannel = AndroidNotificationChannel(
      'shopping_reminders',
      'Shopping Reminders',
      description: 'Reminders for shopping tasks',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(expiryChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(budgetChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reminderChannel);
  }

  /// Handles foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');
    
    // Show local notification when app is in foreground
    if (message.notification != null) {
      showNotification(
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        payload: json.encode(message.data),
      );
    }
  }

  /// Handles background/terminated messages
  void _handleBackgroundMessage(RemoteMessage message) {
    print('Background message: ${message.notification?.title}');
    
    // Navigate to appropriate screen based on notification type
    final data = message.data;
    if (data['type'] == 'expiry_alert' && data['recipeUrl'] != null) {
      // TODO: Navigate to recipe detail screen
      print('Navigate to recipe: ${data['recipeUrl']}');
    }
  }

  /// Handles notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      if (data['type'] == 'expiry_alert' && data['recipeUrl'] != null) {
        // TODO: Navigate to recipe detail screen
        print('Navigate to recipe: ${data['recipeUrl']}');
      }
    }
  }

  /// Schedules expiry alert notification 3 days before item expires
  /// Includes item name and suggested recipe link
  /// 
  /// [item] - The grocery item that's expiring
  /// Returns notification ID
  Future<int> scheduleExpiryAlertWithRecipe({
    required GroceryItem item,
  }) async {
    try {
      final daysUntilExpiry = item.daysUntilExpiry;
      
      // Schedule notification 3 days before expiry
      if (daysUntilExpiry <= 3 && daysUntilExpiry > 0) {
        // Find recipe suggestions using the expiring item
        final recipes = await _recipeApi.findRecipesByExpiringIngredients([item]);
        
        String recipeTitle = 'Try a recipe';
        String recipeUrl = '';
        
        if (recipes.isNotEmpty) {
          recipeTitle = recipes.first.recipe.title;
          recipeUrl = 'recipe://${recipes.first.recipe.id}';
        }

        // Calculate notification time (3 days before expiry at 9 AM)
        final notificationTime = item.expiryDate.subtract(
          Duration(days: 3, hours: item.expiryDate.hour - 9),
        );

        // Generate unique notification ID
        final notificationId = item.id.hashCode;

        // Schedule local notification
        await _localNotifications.zonedSchedule(
          notificationId,
          '⚠️ ${item.name} expires in 3 days!',
          'Use it soon! Recipe suggestion: $recipeTitle',
          _convertToTZDateTime(notificationTime),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'expiry_alerts',
              'Expiry Alerts',
              channelDescription: 'Notifications for items about to expire',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              styleInformation: BigTextStyleInformation(
                'Your ${item.name} expires on ${_formatDate(item.expiryDate)}. '
                'Don\'t let it go to waste! Try this recipe: $recipeTitle',
              ),
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: json.encode({
            'type': 'expiry_alert',
            'itemId': item.id,
            'itemName': item.name,
            'expiryDate': item.expiryDate.toIso8601String(),
            'recipeUrl': recipeUrl,
            'recipeTitle': recipeTitle,
          }),
        );

        print('Scheduled expiry notification for ${item.name} at $notificationTime');
        return notificationId;
      }

      return -1; // No notification scheduled
    } catch (e) {
      print('Error scheduling expiry alert: $e');
      rethrow;
    }
  }

  /// Schedules expiry alerts for multiple items
  Future<List<int>> scheduleExpiryAlertsForItems({
    required List<GroceryItem> items,
  }) async {
    final notificationIds = <int>[];
    
    for (final item in items) {
      if (item.daysUntilExpiry <= 3 && item.daysUntilExpiry > 0) {
        try {
          final id = await scheduleExpiryAlertWithRecipe(item: item);
          if (id != -1) {
            notificationIds.add(id);
          }
        } catch (e) {
          print('Error scheduling notification for ${item.name}: $e');
        }
      }
    }

    return notificationIds;
  }

  /// Sends immediate expiry alert with recipe suggestion
  Future<void> sendImmediateExpiryAlert({
    required GroceryItem item,
    required String recipeTitle,
    required String recipeUrl,
  }) async {
    await showNotification(
      title: '⚠️ ${item.name} expires in ${item.daysUntilExpiry} days!',
      body: 'Try this recipe: $recipeTitle',
      payload: json.encode({
        'type': 'expiry_alert',
        'itemId': item.id,
        'itemName': item.name,
        'recipeUrl': recipeUrl,
        'recipeTitle': recipeTitle,
      }),
    );
  }

  /// Sends a budget warning notification
  Future<void> sendBudgetWarning({
    required String message,
    required double currentSpending,
    required double budgetLimit,
  }) async {
    final percentage = (currentSpending / budgetLimit * 100).toStringAsFixed(1);
    
    await showNotification(
      title: '💰 Budget Alert',
      body: '$message You\'ve used $percentage% of your budget.',
      payload: json.encode({
        'type': 'budget_warning',
        'currentSpending': currentSpending,
        'budgetLimit': budgetLimit,
      }),
    );
  }

  /// Schedules a shopping reminder
  Future<void> scheduleShoppingReminder({
    required String message,
    required DateTime scheduledTime,
  }) async {
    final notificationId = scheduledTime.millisecondsSinceEpoch ~/ 1000;

    await _localNotifications.zonedSchedule(
      notificationId,
      '🛒 Shopping Reminder',
      message,
      _convertToTZDateTime(scheduledTime),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'shopping_reminders',
          'Shopping Reminders',
          channelDescription: 'Reminders for shopping tasks',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: json.encode({
        'type': 'shopping_reminder',
        'message': message,
      }),
    );
  }

  /// Shows an immediate notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'expiry_alerts',
        'Expiry Alerts',
        channelDescription: 'Notifications for items about to expire',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Cancels a scheduled notification
  Future<void> cancelNotification(int notificationId) async {
    await _localNotifications.cancel(notificationId);
  }

  /// Cancels all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Requests notification permissions
  Future<bool> requestPermissions() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Checks if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _fcm.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Gets pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  /// Gets FCM token for backend registration
  String? get fcmToken => _fcmToken;

  /// Subscribes to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }

  /// Unsubscribes from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }

  // Helper methods

  /// Converts DateTime to TZDateTime (timezone-aware)
  /// Note: Requires timezone package
  dynamic _convertToTZDateTime(DateTime dateTime) {
    // TODO: Import timezone package and use proper conversion
    // For now, return the DateTime as-is
    // In production, use: TZDateTime.from(dateTime, local);
    return dateTime;
  }

  /// Formats date for display
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.notification?.title}');
  // Handle background message
}

// Made with Bob
