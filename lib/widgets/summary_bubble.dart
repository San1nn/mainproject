import 'package:flutter/material.dart';
import 'package:mainproject/constants.dart';
import 'package:mainproject/services/chat_summarization_service.dart';

/// A beautiful, expandable AI summary card that appears below long messages.
class SummaryBubble extends StatefulWidget {
  final String messageId;
  final String messageContent;

  const SummaryBubble({
    required this.messageId,
    required this.messageContent,
    super.key,
  });

  @override
  State<SummaryBubble> createState() => _SummaryBubbleState();
}

class _SummaryBubbleState extends State<SummaryBubble>
    with SingleTickerProviderStateMixin {
  final _summarizationService = ChatSummarizationService();

  bool _isExpanded = false;
  bool _isLoading = false;
  String? _summary;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _generateSummary() async {
    if (_summary != null) {
      // Already generated, just toggle visibility
      setState(() => _isExpanded = !_isExpanded);
      return;
    }

    setState(() {
      _isExpanded = true;
      _isLoading = true;
    });
    _shimmerController.repeat();

    final result = await _summarizationService.summarizeMessage(
      widget.messageId,
      widget.messageContent,
    );

    if (mounted) {
      _shimmerController.stop();
      setState(() {
        _summary = result;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── "Summarize" / "Hide Summary" pill button ──
        GestureDetector(
          onTap: _generateSummary,
          child: Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accentGrape.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accentGrape.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.auto_awesome_rounded,
                  size: 14,
                  color: AppColors.accentGrape,
                ),
                const SizedBox(width: 5),
                Text(
                  _isExpanded ? 'Hide Summary' : 'AI Summary',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentGrape,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Expandable summary card ──
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _isLoading ? _buildLoadingCard() : _buildSummaryCard(),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }

  // ── Loading Shimmer Card ──
  Widget _buildLoadingCard() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.surfaceVariant.withValues(alpha: 0.4),
                AppColors.accentGrape.withValues(
                  alpha: 0.05 + _shimmerController.value * 0.08,
                ),
                AppColors.surfaceVariant.withValues(alpha: 0.4),
              ],
              stops: [0.0, _shimmerController.value, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.accentGrape.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accentGrape.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Generating summary...',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Summary Content Card ──
  Widget _buildSummaryCard() {
    if (_summary == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentGrape.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.accentGrape.withValues(alpha: 0.2),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGrape.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.accentGrape.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 12,
                  color: AppColors.accentGrape,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'AI Summary',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentGrape,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentGrape.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Gemini',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentGrape,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Divider
          Container(
            height: 0.5,
            color: AppColors.accentGrape.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 10),
          // Summary text
          Text(
            _summary!,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: AppColors.textPrimary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

/// A floating action button that summarizes the entire chat in a room.
class ChatSummaryFAB extends StatefulWidget {
  final String roomId;
  final List<Map<String, String>> messages;

  const ChatSummaryFAB({
    required this.roomId,
    required this.messages,
    super.key,
  });

  @override
  State<ChatSummaryFAB> createState() => _ChatSummaryFABState();
}

class _ChatSummaryFABState extends State<ChatSummaryFAB> {
  final _summarizationService = ChatSummarizationService();
  bool _isLoading = false;

  Future<void> _showChatSummary() async {
    setState(() => _isLoading = true);

    final summary = await _summarizationService.summarizeChat(
      widget.roomId,
      widget.messages,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildSummarySheet(summary),
    );
  }

  Widget _buildSummarySheet(String summary) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.accentGrape.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGrape.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
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
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentGrape.withValues(alpha: 0.2),
                        AppColors.primary.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: AppColors.accentGrape,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Rundown',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Powered by Gemini AI',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.accentGrape,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 0.5,
            color: AppColors.border.withValues(alpha: 0.5),
          ),
          // Summary content
          Flexible(
            child: Scrollbar(
              thumbVisibility: true,
              radius: const Radius.circular(10),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Text(
                  summary,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.7,
                    color: AppColors.textPrimary.withValues(alpha: 0.9),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.length < 3) return const SizedBox.shrink();

    return Positioned(
      right: 16,
      bottom: 80,
      child: GestureDetector(
        onTap: _isLoading ? null : _showChatSummary,
        child: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accentGrape, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGrape.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 22,
                ),
        ),
      ),
    );
  }
}
