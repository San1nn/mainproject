import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:mainproject/constants.dart';
import 'package:mainproject/models/user.dart';
import 'package:mainproject/models/room.dart';
import 'package:mainproject/services/user_service.dart';
import 'package:mainproject/services/room_service.dart';
import 'package:mainproject/widgets/user_avatar.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final UserService _userService = UserService();
  final RoomService _roomService = RoomService();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    // No longer using _dataFuture, using Streams instead
    setState(() {});
  }

  Stream<Map<String, dynamic>> _dataStream() {
    return _userService.watchAllUsers().switchMap((users) {
      return _roomService.watchAllRooms().map((rooms) {
        return {'users': users, 'rooms': rooms};
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('User Management')),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _dataStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final users = snapshot.data?['users'] as List<User>? ?? [];
          final rooms = snapshot.data?['rooms'] as List<Room>? ?? [];

          if (users.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = users[index];
              final moderatedCount = rooms
                  .where(
                    (r) => r.creatorId == user.id || r.creatorId == user.email,
                  )
                  .length;
              return _buildUserCard(user, moderatedCount);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(User user, int moderatedCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          UserAvatar(
            seed: user.id,
            fallbackInitial: user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            radius: 24,
            isModerator: user.role == UserRole.admin || user.role == UserRole.moderator,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user.role).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _getRoleColor(
                            user.role,
                          ).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        user.role.toString().split('.').last.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getRoleColor(user.role),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• $moderatedCount groups moderated',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Remove User',
            onPressed: () => _confirmDelete(user),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove User?'),
        content: Text(
          'Are you sure you want to remove ${user.name}? This will delete their account data from the database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _userService.deleteUser(user.id);
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User removed successfully')),
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

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.redAccent;
      case UserRole.moderator:
        return Colors.purpleAccent;
      case UserRole.user:
        return Colors.blueAccent;
    }
  }
}
