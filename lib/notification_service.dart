import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:device_info_plus/device_info_plus.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Firebase Messaging instance
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  // Stream controllers for notifications
  final StreamController<RemoteMessage> _notificationStream = StreamController<RemoteMessage>.broadcast();
  final StreamController<Map<String, dynamic>> _localNotificationStream = StreamController<Map<String, dynamic>>.broadcast();
  
  // Get streams
  Stream<RemoteMessage> get notificationStream => _notificationStream.stream;
  Stream<Map<String, dynamic>> get localNotificationStream => _localNotificationStream.stream;
  
  // Current user ID
  String? get currentUserId => auth.FirebaseAuth.instance.currentUser?.uid;
  
  // Initialize notification service
  Future<void> initialize() async {
    try {
      debugPrint('Initializing Notification Service...');
      
      // Request permission
      await _requestPermission();
      
      // Get token
      await _getToken();
      
      // Set up foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Set up background message handler
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      
      // Set up background message handler (when app is terminated)
      FirebaseMessaging.instance.getInitialMessage().then(_handleInitialMessage);
      
      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
      
      debugPrint('Notification Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Notification Service: $e');
    }
  }
  
  // Request notification permission
  Future<void> _requestPermission() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      debugPrint('Notification permission status: ${settings.authorizationStatus}');
      
      // For Android 13+, we need to check and request permission
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          // You might want to use a permission handler package for Android 13+
          debugPrint('Android 13+ detected, consider using permission_handler package');
        }
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }
  
  // Get and store device token
  Future<String?> _getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      
      if (token != null) {
        debugPrint('Device Token: $token');
        await _storeDeviceToken(token);
        return token;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting device token: $e');
      return null;
    }
  }
  
  // Store device token in Firestore
  Future<void> _storeDeviceToken(String token) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        debugPrint('No user logged in, skipping token storage');
        return;
      }
      
      final deviceInfo = {
        'deviceToken': token,
        'deviceType': Platform.isIOS ? 'iOS' : Platform.isAndroid ? 'Android' : 'Web',
        'platform': Platform.operatingSystem,
        'platformVersion': Platform.operatingSystemVersion,
        'lastUpdated': FieldValue.serverTimestamp(),
        'isActive': true,
      };
      
      // Update user document with device token
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
            'devices.$token': deviceInfo,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      // Also store in separate collection for easier querying
      await FirebaseFirestore.instance
          .collection('user_devices')
          .doc(token)
          .set({
            'userId': userId,
            'deviceToken': token,
            'deviceInfo': deviceInfo,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'isActive': true,
          });
      
      debugPrint('Device token stored successfully');
    } catch (e) {
      debugPrint('Error storing device token: $e');
    }
  }
  
  // Handle token refresh
  Future<void> _onTokenRefresh(String newToken) async {
    try {
      debugPrint('Token refreshed: $newToken');
      
      // Delete old token from user's devices
      final userId = currentUserId;
      if (userId != null) {
        // Get old tokens
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          final devices = userData?['devices'] as Map<String, dynamic>?;
          
          if (devices != null) {
            // Mark old tokens as inactive
            for (var token in devices.keys) {
              await FirebaseFirestore.instance
                  .collection('user_devices')
                  .doc(token)
                  .update({
                    'isActive': false,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
            }
          }
        }
      }
      
      // Store new token
      await _storeDeviceToken(newToken);
    } catch (e) {
      debugPrint('Error handling token refresh: $e');
    }
  }
  
  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      debugPrint('Foreground message received: ${message.messageId}');
      debugPrint('Message data: ${message.data}');
      debugPrint('Message notification: ${message.notification}');
      
      // Add to stream for UI updates
      _notificationStream.add(message);
      
      // Show local notification
      await _showLocalNotification(message);
      
      // Update notification count in Firestore
      await _updateNotificationBadgeCount(1);
    } catch (e) {
      debugPrint('Error handling foreground message: $e');
    }
  }
  
  // Handle when message opens the app
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    try {
      debugPrint('App opened from notification: ${message.messageId}');
      debugPrint('Message data: ${message.data}');
      
      // Handle navigation based on message data
      await _handleNotificationNavigation(message.data);
    } catch (e) {
      debugPrint('Error handling message opened app: $e');
    }
  }
  
  // Handle initial message (app terminated)
  Future<void> _handleInitialMessage(RemoteMessage? message) async {
    try {
      if (message != null) {
        debugPrint('Initial message: ${message.messageId}');
        debugPrint('Message data: ${message.data}');
        
        // Handle navigation based on message data
        await _handleNotificationNavigation(message.data);
      }
    } catch (e) {
      debugPrint('Error handling initial message: $e');
    }
  }
  
  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      // For iOS/macOS, we can use the built-in notification
      if (Platform.isIOS || Platform.isMacOS) {
        // iOS handles notifications automatically
        return;
      }
      
      // For Android/Web, we need to show a custom notification
      final notification = message.notification;
      
      if (notification != null) {
        final Map<String, dynamic> notificationData = {
          'title': notification.title ?? 'New Notification',
          'body': notification.body ?? 'You have a new message',
          'data': message.data,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        
        // Add to local notification stream
        _localNotificationStream.add(notificationData);
      }
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }
  
  // Handle notification navigation
  Future<void> _handleNotificationNavigation(Map<String, dynamic> data) async {
    try {
      // Extract navigation info from data
      final screen = data['screen']?.toString();
      final id = data['id']?.toString();
      final type = data['type']?.toString();
      
      // Mark notification as read in Firestore
      await _markNotificationAsRead(data['notificationId']?.toString());
      
      // Navigate based on screen type
      switch (screen) {
        case 'announcement':
          // Navigate to announcement details
          _localNotificationStream.add({
            'action': 'navigate',
            'screen': 'announcement_detail',
            'id': id,
          });
          break;
        case 'assignment':
          // Navigate to assignment details
          _localNotificationStream.add({
            'action': 'navigate',
            'screen': 'assignment_detail',
            'id': id,
          });
          break;
        case 'exam':
          // Navigate to exam details
          _localNotificationStream.add({
            'action': 'navigate',
            'screen': 'exam_detail',
            'id': id,
          });
          break;
        case 'message':
          // Navigate to messages
          _localNotificationStream.add({
            'action': 'navigate',
            'screen': 'messages',
            'id': id,
          });
          break;
        default:
          // Navigate to notifications screen
          _localNotificationStream.add({
            'action': 'navigate',
            'screen': 'notifications',
          });
      }
    } catch (e) {
      debugPrint('Error handling notification navigation: $e');
    }
  }
  
  // Mark notification as read
  Future<void> _markNotificationAsRead(String? notificationId) async {
    try {
      if (notificationId == null || notificationId.isEmpty) return;
      
      final userId = currentUserId;
      if (userId == null) return;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({
            'read': true,
            'readAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
  
  // Update notification badge count
  Future<void> _updateNotificationBadgeCount(int increment) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
            'unreadNotificationCount': FieldValue.increment(increment),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error updating notification badge count: $e');
    }
  }
  
  // Subscribe to topics
  Future<void> subscribeToTopics(List<String> topics) async {
    try {
      for (final topic in topics) {
        await _firebaseMessaging.subscribeToTopic(topic);
        debugPrint('Subscribed to topic: $topic');
      }
    } catch (e) {
      debugPrint('Error subscribing to topics: $e');
    }
  }
  
  // Unsubscribe from topics
  Future<void> unsubscribeFromTopics(List<String> topics) async {
    try {
      for (final topic in topics) {
        await _firebaseMessaging.unsubscribeFromTopic(topic);
        debugPrint('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      debugPrint('Error unsubscribing from topics: $e');
    }
  }
  
  // Get user topics based on user data
  Future<List<String>> getUserTopics() async {
    try {
      final userId = currentUserId;
      if (userId == null) return [];
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) return [];
      
      final userData = userDoc.data();
      final college = userData?['college']?.toString().toLowerCase().replaceAll(' ', '_');
      final department = userData?['department']?.toString().toLowerCase().replaceAll(' ', '_');
      final level = userData?['level']?.toString();
      
      final topics = <String>[
        'all_users',
        if (college != null && college.isNotEmpty) 'college_$college',
        if (department != null && department.isNotEmpty) 'department_$department',
        if (level != null && level.isNotEmpty) 'level_$level',
      ];
      
      return topics;
    } catch (e) {
      debugPrint('Error getting user topics: $e');
      return [];
    }
  }
  
  // Setup user topics (call this after login/signup)
  Future<void> setupUserTopics() async {
    try {
      final topics = await getUserTopics();
      await subscribeToTopics(topics);
      debugPrint('User topics setup complete: $topics');
    } catch (e) {
      debugPrint('Error setting up user topics: $e');
    }
  }
  
  // Clear all subscriptions
  Future<void> clearAllSubscriptions() async {
    try {
      final topics = await getUserTopics();
      await unsubscribeFromTopics(topics);
      debugPrint('Cleared all topic subscriptions');
    } catch (e) {
      debugPrint('Error clearing subscriptions: $e');
    }
  }
  
  // Delete device token (call on logout)
  Future<void> deleteDeviceToken(String token) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;
      
      // Mark token as inactive in user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
            'devices.$token.isActive': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      // Mark token as inactive in user_devices collection
      await FirebaseFirestore.instance
          .collection('user_devices')
          .doc(token)
          .update({
            'isActive': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      debugPrint('Device token marked as inactive');
    } catch (e) {
      debugPrint('Error deleting device token: $e');
    }
  }
  
  // Get current device token
  Future<String?> getCurrentToken() async {
    return await _firebaseMessaging.getToken();
  }
  
  // Check notification permission
  Future<bool> checkPermission() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
             settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('Error checking permission: $e');
      return false;
    }
  }
  
  // Dispose streams
  void dispose() {
    _notificationStream.close();
    _localNotificationStream.close();
  }
}

// DeviceInfoPlugin import for platform detection

final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

// Helper extension for FirebaseMessaging
extension FirebaseMessagingExtension on FirebaseMessaging {
  Future<String?> get token async {
    try {
      return await getToken();
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }
}