import 'package:flutter/material.dart';
import 'package:mainproject/constants.dart';
import 'package:mainproject/models/room.dart';
import 'package:mainproject/models/user.dart';
import 'package:mainproject/services/room_service.dart';
import 'package:mainproject/services/user_service.dart';
import 'package:rxdart/rxdart.dart';

class ManageRoomsScreen extends StatefulWidget {
  const ManageRoomsScreen({super.key});

  @override
  State<ManageRoomsScreen> createState() => _ManageRoomsScreenState();
}

class _ManageRoomsScreenState extends State<ManageRoomsScreen> {
  final RoomService _roomService = RoomService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  void _loadRooms() {
    setState(() {});
  }

  Stream<Map<String, dynamic>> _dataStream() {
    return _roomService.watchAllRooms().switchMap((rooms) {
      return _userService.watchAllUsers().map((users) {
        return {'rooms': rooms, 'users': users};
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Room Management')),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _dataStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final rooms = snapshot.data?['rooms'] as List<Room>? ?? [];
          final users = snapshot.data?['users'] as List<User>? ?? [];

          if (rooms.isEmpty) {
            return const Center(child: Text('No rooms found'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final room = rooms[index];
              final moderator = users.firstWhere(
                (u) => u.id == room.creatorId || u.email == room.creatorId,
                orElse: () => User(
                  id: '',
                  email: room.creatorId,
                  name: 'Unknown Moderator',
                  role: UserRole.user,
                  createdAt: DateTime.now(),
                ),
              );
              return _buildRoomCard(room, moderator.name);
            },
          );
        },
      ),
    );
  }

  Widget _buildRoomCard(Room room, String moderatorName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              room.type == RoomType.private ? Icons.lock : Icons.public,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  room.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${room.id}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Moderated by: $moderatorName',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _confirmDelete(room),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Room room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room?'),
        content: Text(
          'Are you sure you want to delete "${room.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _roomService.deleteRoom(room.id);
        _loadRooms();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Room deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
