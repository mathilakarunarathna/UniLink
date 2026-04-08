import 'package:flutter/material.dart';

// Provides global state notifiers for dashboard live updates
class GlobalState {
  static final ValueNotifier<String> parkingStatus = ValueNotifier("None");
  static final ValueNotifier<String> parkingLot = ValueNotifier("");

  static final ValueNotifier<String> foodOrderStatus = ValueNotifier("None");
  static final ValueNotifier<String> foodOrderDetails = ValueNotifier("");
  static final ValueNotifier<int> pendingFoodOrderId = ValueNotifier(0);

  static final ValueNotifier<String> studyRoomStatus = ValueNotifier("None");
  static final ValueNotifier<String> studyRoomDetails = ValueNotifier("");

  static final ValueNotifier<int> ticketCount = ValueNotifier(2); // 2 owned event default
  
  static final ValueNotifier<List<Map<String, dynamic>>> globalNotifications = ValueNotifier([]);
  static final ValueNotifier<Map<String, dynamic>?> latestNotification = ValueNotifier(null);
  
  static int get unreadNotificationsCount {
    return globalNotifications.value.where((n) => n["isUnread"] == true).length;
  }

  static void addNotification({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    String? time,
  }) {
    final currentList = List<Map<String, dynamic>>.from(globalNotifications.value);
    final notification = {
      "title": title,
      "description": description,
      "time": time ?? "Just now",
      "icon": icon,
      "iconColor": iconColor,
      "isUnread": true,
      "timestamp": DateTime.now(),
    };
    currentList.insert(0, notification);
    globalNotifications.value = currentList;
    
    // Trigger in-app alert
    latestNotification.value = notification;
  }

  static void markAllNotificationsAsRead() {
    final currentList = List<Map<String, dynamic>>.from(globalNotifications.value);
    for (var i = 0; i < currentList.length; i++) {
        currentList[i] = {
          ...currentList[i],
          "isUnread": false,
        };
    }
    globalNotifications.value = currentList;
  }

  static void setNotifications(List<Map<String, dynamic>> list) {
    globalNotifications.value = list;
  }

  static void clearNotifications() {
    globalNotifications.value = [];
  }

  static final ValueNotifier<Map<String, dynamic>> weatherInfo = ValueNotifier({
    "temp": "28°C",
    "condition": "Sunny",
    "icon": Icons.wb_sunny_rounded,
  });

  static final ValueNotifier<Map<String, dynamic>> shuttleInfo = ValueNotifier({
    "route": "Main Hall \u2794 Gate 1",
    "eta": "4 mins",
    "isActive": true,
  });

  static final ValueNotifier<List<Map<String, dynamic>>> securityActivities = ValueNotifier([
    {
      "title": "Unauthorized Vehicle",
      "location": "Main Campus Lot Level 2 - Student ID: IT19876543",
      "time": "2 mins ago",
      "color": Colors.redAccent,
    },
    {
      "title": "Blocked Fire Lane",
      "location": "Main Campus Lot Entrance",
      "time": "1 hr ago",
      "color": Colors.redAccent,
    },
  ]);

  static void addSecurityActivity(String title, String location, Color color) {
    final currentList = List<Map<String, dynamic>>.from(securityActivities.value);
    currentList.insert(0, {
      "title": title,
      "location": location,
      "time": "Just now",
      "color": color,
    });
    securityActivities.value = currentList;
  }
}
