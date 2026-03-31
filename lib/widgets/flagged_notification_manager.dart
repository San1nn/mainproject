import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mainproject/constants.dart';
import 'package:mainproject/models/message.dart';
import 'package:mainproject/services/auth_service.dart';
import 'package:mainproject/services/room_service.dart';
import 'package:mainproject/services/firebase_message_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FlaggedNotificationManager extends StatefulWidget {
  final Widget child;

  const FlaggedNotificationManager({super.key, required this.child});

  @override
  State<FlaggedNotificationManager> createState() =>
      _FlaggedNotificationManagerState();
}

class _FlaggedNotificationManagerState
    extends State<FlaggedNotificationManager> {
  final _roomService = RoomService();
  final _messageService = FirebaseMessageService();
  final _authService = AuthService();

  StreamSubscription? _flaggedSubscription;
  Set<String> _notifiedMessageIds = {};
  List<String> _myRoomIds = [];

  @override
  void initState() {
    super.initState();
    _setupModeratorListener();
  }

  @override
  void dispose() {
    _flaggedSubscription?.cancel();
    super.dispose();
  }

  Future<void> _setupModeratorListener() async {
    final user = _authService.currentUser;
    if (user == null) return;

    // 1. Get rooms where user is creator/moderator
    // We can use watchAllRooms and filter, or a specific query if available
    _roomService.watchAllRooms().listen((rooms) {
      final myRooms = rooms
          .where(
            (r) =>
                r.creatorId == user.id ||
                r.creatorId == 'hardcoded_admin_id' &&
                    user.email == 'admin@gmail.com',
          )
          .map((r) => r.id)
          .toList();

      if (myRooms.join(',') != _myRoomIds.join(',')) {
        setState(() {
          _myRoomIds = myRooms;
        });
        _restartMessageListener();
      }
    });
  }

  void _restartMessageListener() {
    _flaggedSubscription?.cancel();
    if (_myRoomIds.isEmpty) return;

    _flaggedSubscription = _messageService.watchFlaggedMessages(_myRoomIds).listen((
      messages,
    ) async {
      // Check preference once per batch preferably, but for simplicity:
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notifications_enabled') ?? true;
      if (!enabled) return;

      for (final message in messages) {
        // Only notify for new messages that weren't sent by the moderator themselves
        if (!_notifiedMessageIds.contains(message.id) &&
            message.senderId != _authService.currentUser?.id) {
          _showFlaggedNotification(message);
          _notifiedMessageIds.add(message.id);
        }
      }
    });
  }

  void _showFlaggedNotification(Message message) {
    if (!mounted) return;

    // Get room name for better context
    _roomService.getRoomById(message.roomId).then((room) {
      if (!mounted || room == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: AppColors.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Content Violation Alert',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${message.senderName} sent a flagged message in ${room.name}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    Navigator.of(
                      context,
                    ).pushNamed('/room-detail', arguments: room);
                  },
                  child: const Text('VIEW'),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
