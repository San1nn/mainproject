import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mainproject/constants.dart';
import 'package:mainproject/models/room.dart';
import 'package:mainproject/services/auth_service.dart';
import 'package:mainproject/services/room_service.dart';
import 'package:mainproject/widgets/user_avatar.dart';
import 'package:mainproject/services/firebase_message_service.dart';
import 'package:mainproject/services/chat_summarization_service.dart';
import 'package:mainproject/services/content_moderation_service.dart';
import 'package:mainproject/services/voice_service.dart';
import 'package:mainproject/models/message.dart';
import 'package:mainproject/models/user.dart' as models;
import 'package:mainproject/widgets/voice_message_bubble.dart';
import 'package:mainproject/widgets/summary_bubble.dart';
import 'package:mainproject/services/file_service.dart';
import 'package:url_launcher/url_launcher.dart';

class RoomDetailScreen extends StatefulWidget {
  final Room room;

  const RoomDetailScreen({required this.room, super.key});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _roomService = RoomService();
  final _messageService = FirebaseMessageService();
  final _authService = AuthService();
  final _voiceService = VoiceService();
  final _summarizationService = ChatSummarizationService();
  final _moderationService = ContentModerationService();
  final _fileService = FileService();
  late Room _currentRoom;
  bool _isUploadingFile = false;

  // Voice recording state
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  late AnimationController _micPulseController;
  bool _isSendingVoice = false;

  @override
  void initState() {
    super.initState();
    _currentRoom = widget.room;
    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _recordingTimer?.cancel();
    _micPulseController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  // ─── Text Message ───────────────────────────────────────────────────
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;
    if (!_currentRoom.isMember(currentUser.id) &&
        !_currentRoom.isMember(currentUser.email) &&
        !_currentRoom.isCreator(currentUser.email))
      return;

    // Check for foul language / inappropriate content (Passive Moderation)
    final moderation = await _moderationService.checkContent(messageText);
    final bool isFlagged = !moderation.isApproved;

    if (isFlagged) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.red.withOpacity(0.3), width: 1),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                SizedBox(width: 12),
                Text('Warning', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              'Message cannot be sent as it contains inappropriate language.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK', style: TextStyle(color: AppColors.primaryLight, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
      return; // Stop the execution, don't clear the input or send the message
    }

    _messageController.clear();

    try {
      await _submitTextMessage(messageText, currentUser);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
      }
    }
  }

  Future<void> _submitTextMessage(String text, models.User currentUser) async {
    // Check for foul language / inappropriate content (Passive Moderation)
    final moderation = await _moderationService.checkContent(text);
    final bool isFlagged = !moderation.isApproved;

    await _messageService.sendMessage(
      roomId: _currentRoom.id,
      senderId: currentUser.id,
      senderName: currentUser.name,
      senderPhotoUrl: currentUser.photoUrl,
      content: text,
      type: MessageType.text,
      isFlagged: isFlagged,
      flagReason: isFlagged ? moderation.reason : null,
    );
  }

  Future<void> _pickAndUploadFile() async {
    debugPrint('DEBUG: _pickAndUploadFile triggered');
    if (_isUploadingFile) {
      debugPrint('DEBUG: Already uploading, ignoring');
      return;
    }

    try {
      debugPrint('DEBUG: Calling _fileService.pickFile()...');
      final file = await _fileService.pickFile();
      if (file == null) {
        debugPrint('DEBUG: No file selected (null)');
        return;
      }
      debugPrint('DEBUG: File picked: ${file.name}');

      setState(() => _isUploadingFile = true);

      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      // Determine if it's an image
      final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(file.extension?.toLowerCase());
      final type = isImage ? MessageType.image : MessageType.file;

      final url = await _fileService.uploadFile(
        filePath: file.path,
        fileBytes: file.bytes,
        fileName: file.name,
        roomId: _currentRoom.id,
        folder: isImage ? 'chat_images' : 'chat_documents',
      );

      await _messageService.sendMessage(
        roomId: _currentRoom.id,
        senderId: currentUser.id,
        senderName: currentUser.name,
        senderPhotoUrl: currentUser.photoUrl,
        content: isImage ? '🖼️ Image' : '📁 ${file.name}',
        type: type,
        metadata: {
          'fileUrl': url,
          'fileName': file.name,
          'fileSize': file.size,
          'extension': file.extension,
        },
      );
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingFile = false);
      }
    }
  }

  // ─── Voice Recording ────────────────────────────────────────────────
  Future<void> _startRecording() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;
    if (!_currentRoom.isMember(currentUser.id) &&
        !_currentRoom.isMember(currentUser.email) &&
        !_currentRoom.isCreator(currentUser.email))
      return;

    try {
      final hasPermission = await _voiceService.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Microphone permission is required for voice messages',
              ),
            ),
          );
        }
        return;
      }

      await _voiceService.startRecording();

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      _micPulseController.repeat(reverse: true);

      // Start timer to track recording duration
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingDuration += const Duration(seconds: 1);
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting recording: $e')));
      }
    }
  }

  Future<void> _stopAndSendRecording() async {
    if (!_isRecording || _isSendingVoice) return;

    _recordingTimer?.cancel();
    _micPulseController.stop();
    _micPulseController.value = 0;

    setState(() {
      _isRecording = false;
      _isSendingVoice = true;
    });

    try {
      final result = await _voiceService.stopRecording();
      if (result == null) {
        setState(() => _isSendingVoice = false);
        return;
      }

      // Don't send very short recordings (< 1 second)
      if (result.duration.inMilliseconds < 800) {
        setState(() => _isSendingVoice = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Recording too short')));
        }
        return;
      }

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        setState(() => _isSendingVoice = false);
        return;
      }

      // Upload to Firebase Storage
      final downloadUrl = await _voiceService.uploadVoiceMessage(
        filePath: result.filePath,
        roomId: _currentRoom.id,
        senderId: currentUser.id,
      );

      // Send as voice message
      await _messageService.sendMessage(
        roomId: _currentRoom.id,
        senderId: currentUser.id,
        senderName: currentUser.name,
        senderPhotoUrl: currentUser.photoUrl,
        content: '🎤 Voice message',
        type: MessageType.voice,
        metadata: {
          'audioUrl': downloadUrl,
          'durationMs': result.duration.inMilliseconds,
          'fileSize': result.fileSize,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending voice message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingVoice = false;
          _recordingDuration = Duration.zero;
        });
      }
    }
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    _micPulseController.stop();
    _micPulseController.value = 0;

    await _voiceService.cancelRecording();

    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
  }

  String _formatRecordingTime(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ─── Room Actions ───────────────────────────────────────────────────
  Future<void> _leaveRoom() async {
    try {
      await _roomService.leaveRoom(
        _currentRoom.id,
        _authService.currentUser?.email ?? '',
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Left ${_currentRoom.name}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error leaving room: $e')));
      }
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: GestureDetector(
          onTap: _showRoomInfo,
          child: Column(
            children: [
              Text(
                _currentRoom.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              StreamBuilder<Room?>(
                stream: _roomService.watchRoom(_currentRoom.id),
                builder: (context, snapshot) {
                  final room = snapshot.data ?? _currentRoom;
                  return Text(
                    '${room.memberCount} members',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.normal,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.primaryLight),
            onPressed: _showRoomInfo,
          ),
        ],
      ),
      body: StreamBuilder<Room?>(
        stream: _roomService.watchRoom(_currentRoom.id),
        builder: (context, roomSnapshot) {
          if (roomSnapshot.hasData && roomSnapshot.data != null) {
            _currentRoom = roomSnapshot.data!;
          }

          return StreamBuilder<List<Message>>(
            stream: _messageService.watchRoomMessages(_currentRoom.id),
            builder: (context, snapshot) {
              final messages = snapshot.data ?? [];

              // Prepare text messages for the chat-level summary FAB
              final textMessages = messages
                  .where((m) => m.type == MessageType.text)
                  .map(
                    (m) => {'senderName': m.senderName, 'content': m.content},
                  )
                  .toList();

              return Stack(
                children: [
                  Column(
                    children: [
                      // Messages List
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }

                            return ListView.builder(
                              reverse: true,
                              padding: const EdgeInsets.all(16),
                              itemCount: messages.length + 1,
                              itemBuilder: (context, index) {
                                if (index == messages.length) {
                                  return _buildChatHeader();
                                }

                                final message = messages[index];
                                bool showDateDivider = false;

                                if (index == messages.length - 1) {
                                  showDateDivider = true;
                                } else {
                                  final prevMessage = messages[index + 1];
                                  final currentDay = DateTime(
                                    message.timestamp.year,
                                    message.timestamp.month,
                                    message.timestamp.day,
                                  );
                                  final prevDay = DateTime(
                                    prevMessage.timestamp.year,
                                    prevMessage.timestamp.month,
                                    prevMessage.timestamp.day,
                                  );
                                  if (currentDay != prevDay) {
                                    showDateDivider = true;
                                  }
                                }

                                if (showDateDivider) {
                                  return Column(
                                    children: [
                                      _buildDateDivider(message.timestamp, messages),
                                      _buildMessageBubble(message),
                                    ],
                                  );
                                }

                                return _buildMessageBubble(message);
                              },
                            );
                          },
                        ),
                      ),
                      // Only show input bar if user is a member or creator
                      _currentRoom.isMember(
                                _authService.currentUser?.id ?? '',
                              ) ||
                              _currentRoom.isMember(
                                _authService.currentUser?.email ?? '',
                              ) ||
                              _currentRoom.isCreator(
                                _authService.currentUser?.email ?? '',
                              )
                          ? (_isRecording
                                ? _buildRecordingBar()
                                : _buildMessageInput())
                          : _buildNonMemberBanner(),
                    ],
                  ),
                  // Chat-level summary FAB
                  if (textMessages.length >= 3)
                    ChatSummaryFAB(
                      roomId: _currentRoom.id,
                      messages: textMessages,
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ─── Chat Header ────────────────────────────────────────────────────
  Widget _buildChatHeader() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            _currentRoom.type == RoomType.public ? Icons.public : Icons.lock,
            size: 32,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _currentRoom.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _currentRoom.description,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: _showRoomInfo,
          child: Column(
            children: [
              Text(
                '${_currentRoom.memberCount} members',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(height: 16),
              // Horizontal Member Preview with Names
              SizedBox(
                height: 70, // Increased height for names
                child: FutureBuilder<List<dynamic>>(
                  future: Future.wait(
                    _currentRoom.memberIds
                        .take(5)
                        .map((id) => _authService.getUserById(id)),
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final members = snapshot.data ?? [];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...members.asMap().entries.map((entry) {
                          final user = entry.value;
                          if (user == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              children: [
                                UserAvatar(
                                  seed: user?.id ?? user?.email ?? 'User',
                                  fallbackInitial: user.name[0].toUpperCase(),
                                  radius: 18,
                                  isModerator: _currentRoom.creatorId == user?.id || _currentRoom.creatorId == user?.email,
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 44,
                                  child: Text(
                                    user.name.split(' ')[0],
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (_currentRoom.memberCount > 5)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.surfaceVariant,
                              child: Text(
                                '+${_currentRoom.memberCount - 5}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 20),
      ],
    );
  }

  // ─── Normal Message Input ───────────────────────────────────────────
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: _isUploadingFile 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.add_circle_outline, color: AppColors.textSecondary),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _pickAndUploadFile();
                      },
                      splashRadius: 24,
                      tooltip: 'Attach File',
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: AppColors.textTertiary),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.emoji_emotions_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Send or Mic button — switches based on text input using ValueListenableBuilder
          // to avoid rebuilding the whole screen on every keystroke
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _messageController,
            builder: (context, value, _) {
              final isNotEmpty = value.text.trim().isNotEmpty;
              return isNotEmpty ? _buildSendButton() : _buildMicButton();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNonMemberBanner() {
    final isPending = _currentRoom.hasPendingRequest(
      _authService.currentUser?.id ?? '',
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPending
                    ? Icons.hourglass_top_rounded
                    : Icons.lock_outline_rounded,
                size: 18,
                color: Colors.amber.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isPending ? 'Request Pending' : 'Not a Member',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.amber.shade400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPending
                        ? 'Waiting for admin approval to join this room.'
                        : 'You need to be a member to send messages.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        onPressed: _sendMessage,
      ),
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: _startRecording,
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
      ),
    );
  }

  // ─── Recording Bar ──────────────────────────────────────────────────
  Widget _buildRecordingBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel button
          GestureDetector(
            onTap: _cancelRecording,
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.withValues(alpha: 0.8),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Recording indicator
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  // Pulsing red dot
                  AnimatedBuilder(
                    animation: _micPulseController,
                    builder: (context, child) {
                      return Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(
                            alpha: 0.5 + _micPulseController.value * 0.5,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(
                                alpha: _micPulseController.value * 0.4,
                              ),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Recording',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatRecordingTime(_recordingDuration),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      color: const Color(0xFF10B981).withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Send recording button
          GestureDetector(
            onTap: _isSendingVoice ? null : _stopAndSendRecording,
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                gradient: _isSendingVoice
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: _isSendingVoice
                    ? const Color(0xFF10B981).withValues(alpha: 0.3)
                    : null,
                borderRadius: BorderRadius.circular(24),
                boxShadow: _isSendingVoice
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: _isSendingVoice
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Room Info Dialog ───────────────────────────────────────────────
  // ─── Room Info Dialog ───────────────────────────────────────────────
  void _showRoomInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        _currentRoom.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _currentRoom.type == RoomType.public
                              ? 'Public Space'
                              : 'Private Group',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Created',
                          _currentRoom.createdAt.toString().split(' ')[0],
                          Icons.calendar_today_rounded,
                        ),
                        _buildStatItem(
                          'Members',
                          _currentRoom.memberCount.toString(),
                          Icons.people_outline_rounded,
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Moderator Section
                    const Text(
                      'Moderator',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder(
                      future: _authService.getUserById(_currentRoom.creatorId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildUserTileLoading();
                        }
                        final user = snapshot.data;
                        if (user == null) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.surfaceVariant,
                                  child: Icon(
                                    Icons.person,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Moderator profile not found',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return _buildUserTile(user);
                      },
                    ),

                    const SizedBox(height: 32),

                    // Members List Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Members List',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        FutureBuilder<List<dynamic>>(
                          future: Future.wait(
                            _currentRoom.memberIds
                                .take(3)
                                .map((id) => _authService.getUserById(id)),
                          ),
                          builder: (context, snapshot) {
                            final names =
                                snapshot.data
                                    ?.where((u) => u != null)
                                    .map((u) {
                                      if (u is models.User)
                                        return u.name.split(' ')[0];
                                      if (u is Map)
                                        return u['name']?.toString().split(
                                              ' ',
                                            )[0] ??
                                            'User';
                                      return 'User';
                                    })
                                    .join(', ') ??
                                '...';
                            return Expanded(
                              child: Text(
                                '$names and ${_currentRoom.memberCount - (snapshot.data?.length ?? 0)} others',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<dynamic>>(
                      future: Future.wait(
                        _currentRoom.memberIds.map(
                          (id) => _authService.getUserById(id),
                        ),
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Column(
                            children: List.generate(
                              _currentRoom.memberCount > 5
                                  ? 5
                                  : _currentRoom.memberCount,
                              (_) => _buildUserTileLoading(),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Error loading members',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }

                        final members = snapshot.data ?? [];
                        if (members.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'No members found',
                                style: TextStyle(color: AppColors.textTertiary),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: members.map((user) {
                            return _buildUserTile(user);
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 40),

                    // Description
                    const Text(
                      'About this Group',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentRoom.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Leave Group Button
                    Center(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        label: const Text(
                          'Leave Group',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Close info sheet
                          _showLeaveConfirmation();
                        },
                      ),
                    ),
                    const SizedBox(height: 80), // Extra space for scrolling
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.textTertiary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
      ],
    );
  }

  Widget _buildUserTile(dynamic user) {
    if (user == null) return const SizedBox.shrink();

    final String name = user is models.User
        ? user.name
        : (user is Map ? (user['name']?.toString() ?? 'User') : 'User');
    final String id = user is models.User
        ? user.id
        : (user is Map ? (user['id']?.toString() ?? '') : '');
    final bool isModerator = id == _currentRoom.creatorId;

    final currentUser = _authService.currentUser;
    final bool isCurrentUserRoomModerator =
        _currentRoom.creatorId == currentUser?.id ||
        _currentRoom.creatorId == currentUser?.email;
    final bool isCurrentUserAppModerator = currentUser?.role == models.UserRole.admin || currentUser?.role == models.UserRole.moderator;
    final bool canRemove =
        (isCurrentUserRoomModerator || isCurrentUserAppModerator) &&
        id != currentUser?.id &&
        id != currentUser?.email &&
        !isModerator;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isModerator
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.border.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            UserAvatar(
              seed: name.isNotEmpty ? name : id,
              fallbackInitial: name.isNotEmpty ? name[0].toUpperCase() : '?',
              radius: 20,
              isModerator: isModerator,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    isModerator ? 'Moderator' : 'Active Member',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (isModerator)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
            if (canRemove)
              IconButton(
                icon: const Icon(Icons.person_remove_rounded, color: AppColors.error, size: 20),
                onPressed: () {
                  Navigator.pop(context); // Close room info sheet
                  _showRemoveUserConfirmation(id, name);
                },
                tooltip: 'Remove User',
              ),
          ],
        ),
      ),
    );
  }

  void _showRemoveUserConfirmation(String userId, String userName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.person_remove_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: 10),
            const Text('Remove User', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to remove $userName from the group?',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _roomService.leaveRoom(_currentRoom.id, userId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$userName was removed from the group'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to remove user: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTileLoading() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Room?'),
        content: Text('Are you sure you want to leave ${_currentRoom.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _leaveRoom();
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ─── Message Bubble ─────────────────────────────────────────────────
  Widget _buildMessageBubble(Message message) {
    final bool isMe = message.senderId == _authService.currentUser?.id;
    final timestamp = message.timestamp;
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!isMe) ...[
                UserAvatar(
                  seed: message.senderId,
                  fallbackInitial: message.senderName[0].toUpperCase(),
                  radius: 14,
                ),
                const SizedBox(width: 8),
              ],
              Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      message.senderName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onLongPress: () => _showMessageOptions(message, isMe),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          padding: message.type == MessageType.voice
                              ? EdgeInsets.zero
                              : const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                          decoration: BoxDecoration(
                            gradient: isMe
                                ? const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primaryDark,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isMe ? null : AppColors.surface,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(isMe ? 20 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isMe ? 0.2 : 0.1,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: isMe
                                ? null
                                : Border.all(color: AppColors.border, width: 1),
                          ),
                          child: message.type == MessageType.voice
                              ? _buildVoiceContent(message, isMe)
                              : message.type == MessageType.image
                                  ? _buildImageContent(message)
                                  : message.type == MessageType.file
                                      ? _buildFileContent(message, isMe)
                                      : Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              message.content,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isMe
                                                    ? Colors.white
                                                    : AppColors.textPrimary,
                                              ),
                                            ),
                                            // Show AI summarize option for long messages (skip system/warning msgs)
                                            if (message.type != MessageType.system &&
                                                _summarizationService.canSummarize(
                                                  message.content,
                                                ))
                                              SummaryBubble(
                                                messageId: message.id,
                                                messageContent: message.content,
                                              ),
                                          ],
                                        ),
                        ),
                        // Flag indicator for moderator (creator)
                        if (message.isFlagged)
                          Positioned(
                            top: -12,
                            right: isMe ? null : -12,
                            left: isMe ? -12 : null,
                            child: _buildFlagIndicator(message),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a flag indicator for flagged messages
  Widget _buildFlagIndicator(Message message) {
    final bool isModerator =
        _currentRoom.creatorId == _authService.currentUser?.id;

    if (!isModerator) {
      // Members see a very subtle grey dot/flag or nothing
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.flag_rounded,
          size: 10,
          color: AppColors.textTertiary,
        ),
      );
    }

    // Moderator sees a clear red warning flag
    return Tooltip(
      message: 'Moderation required: ${message.flagReason ?? "Inappropriate"}',
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Flagged: ${message.flagReason}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.priority_high_rounded,
            size: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ─── Message Long-Press Options ─────────────────────────────────────
  void _showMessageOptions(Message message, bool isMe) {
    HapticFeedback.mediumImpact();

    final isTextMessage = message.type == MessageType.text;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            // Message preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : AppColors.accentGrape,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMe ? 'You' : message.senderName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isMe
                                ? AppColors.primary
                                : AppColors.accentGrape,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isTextMessage
                              ? (message.content.length > 60
                                    ? '${message.content.substring(0, 60)}...'
                                    : message.content)
                              : '🎤 Voice message',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.border.withValues(alpha: 0.3), height: 1),
            // Copy Message
            if (isTextMessage)
              _buildOptionTile(
                icon: Icons.copy_rounded,
                label: 'Copy Message',
                iconColor: AppColors.primaryLight,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.content));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Text('Message copied to clipboard'),
                        ],
                      ),
                      backgroundColor: AppColors.secondary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            // Copy Sender Name
            _buildOptionTile(
              icon: Icons.person_outline_rounded,
              label: 'Copy Sender Name',
              iconColor: AppColors.accentGrape,
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.senderName));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Text('Name copied to clipboard'),
                      ],
                    ),
                    backgroundColor: AppColors.secondary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            // Report Message (Only for messages from others)
            if (!isMe)
              _buildOptionTile(
                icon: Icons.report_problem_rounded,
                label: 'Report Message',
                iconColor: AppColors.error,
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await _messageService.reportMessage(
                      message.id,
                      _authService.currentUser!.id,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Message reported to moderator',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to report message'),
                        ),
                      );
                    }
                  }
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      minLeadingWidth: 0,
    );
  }

  /// Renders voice message content inside the bubble
  Widget _buildVoiceContent(Message message, bool isMe) {
    final metadata = message.metadata;
    final audioUrl = metadata?['audioUrl'] as String? ?? '';
    final durationMs = metadata?['durationMs'] as int? ?? 0;
    final duration = Duration(milliseconds: durationMs);

    if (audioUrl.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic_off_rounded,
              size: 16,
              color: isMe
                  ? Colors.white.withValues(alpha: 0.6)
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Voice message unavailable',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: isMe
                    ? Colors.white.withValues(alpha: 0.6)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return VoiceMessageBubble(
      audioUrl: audioUrl,
      duration: duration,
      isMe: isMe,
    );
  }

  Widget _buildImageContent(Message message) {
    final imageUrl = message.metadata?['fileUrl'] as String? ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.parse(imageUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        child: Image.network(
          imageUrl,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              width: 200,
              color: AppColors.surfaceVariant.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildFileContent(Message message, bool isMe) {
    final fileUrl = message.metadata?['fileUrl'] as String? ?? '';
    final name = message.metadata?['fileName'] as String? ?? 'File';
    final size = message.metadata?['fileSize'] as int? ?? 0;
    
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(fileUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isMe ? Colors.white.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.description, color: isMe ? Colors.white : AppColors.primary),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${(size / (1024 * 1024)).toStringAsFixed(2)} MB',
                    style: TextStyle(
                      color: (isMe ? Colors.white : AppColors.textSecondary).withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.download_rounded, size: 18, color: isMe ? Colors.white.withValues(alpha: 0.8) : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDivider(DateTime date, List<Message> allMessages) {
    String dateStr;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) {
      dateStr = 'Today';
    } else if (msgDate == yesterday) {
      dateStr = 'Yesterday';
    } else {
      dateStr = DateFormat('MMMM d, y').format(date);
    }

    // Check if we have enough messages for a day summary
    final dayMessages = allMessages.where((m) {
      final d = m.timestamp;
      return d.year == date.year &&
          d.month == date.month &&
          d.day == date.day &&
          m.type == MessageType.text;
    }).toList();

    final bool canSummarizeDay = dayMessages.length >= 3;

    return Center(
      child: GestureDetector(
        onTap: canSummarizeDay
            ? () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) => ChatSummaryFAB(
                    roomId: _currentRoom.id,
                    messages: dayMessages
                        .map((m) => {
                              'senderName': m.senderName,
                              'content': m.content,
                            })
                        .toList(),
                  ),
                );
              }
            : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: canSummarizeDay
                  ? AppColors.accentGrape.withValues(alpha: 0.4)
                  : AppColors.border.withValues(alpha: 0.3),
              width: canSummarizeDay ? 1.5 : 1,
            ),
            boxShadow: canSummarizeDay
                ? [
                    BoxShadow(
                      color: AppColors.accentGrape.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: -2,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canSummarizeDay) ...[
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: AppColors.accentGrape,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: canSummarizeDay
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              if (canSummarizeDay) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
