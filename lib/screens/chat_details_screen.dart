import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../providers/auth_provider.dart';
import '../services/chat_service.dart';
import '../services/item_service.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/item_model.dart';

class ChatDetailsScreen extends StatefulWidget {
  final String chatId;

  const ChatDetailsScreen({super.key, required this.chatId});

  @override
  State<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ItemService _itemService = ItemService();
  final ScrollController _scrollController = ScrollController();

  ChatModel? _chat;
  List<ItemModel> _chatItems = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isCompletingSwap = false;

  @override
  void initState() {
    super.initState();
    _loadChatDetails();
    _setupMessageListener();
  }

  Future<ChatModel?> _loadChatDetails() async {
    try {
      final chat = await _chatService.getChatById(widget.chatId);
      if (chat != null) {
        setState(() => _chat = chat);
        await _loadChatItems(chat);
      }
      return chat; // <-- ADD THIS
    } catch (e) {
      // same as before
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    return null;
  }

  Future<void> _loadChatItems(ChatModel chat) async {
    try {
      final offerDoc = await FirebaseFirestore.instance
          .collection('offers')
          .doc(chat.offerId)
          .get();

      if (offerDoc.exists) {
        final offerData = offerDoc.data()!;
        final targetItemId = offerData['targetItemId'] as String?;
        final offeredItemId = offerData['offeredItemId'] as String?;

        final items = await Future.wait([
          if (targetItemId != null) _itemService.getItemById(targetItemId),
          if (offeredItemId != null) _itemService.getItemById(offeredItemId),
        ]);

        if (mounted) {
          setState(() {
            _chatItems = items.whereType<ItemModel>().toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading chat items: $e');
    }
  }

  void _setupMessageListener() {
    _chatService.getMessages(widget.chatId).listen((_) {
      if (_scrollController.hasClients && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isSending = true);

    try {
      await _chatService.sendMessage(
        chatId: widget.chatId,
        senderId: userId,
        content: _messageController.text.trim(),
      );
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
  Future<void> _markSwapAsCompleted() async {
    if (_chat == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;

    if (userId == null) return;

    setState(() {
      _isCompletingSwap = true;
    });

    try {
      await _chatService.markSwapAsCompleted(widget.chatId, userId);

      // Reload chat to get updated status
      final updatedChat = await _loadChatDetails();

      // Check if both users have completed and show rating dialog
      if (updatedChat != null && _chatService.isSwapCompleted(updatedChat)) {
        final hasRated = await _chatService.hasUserRated(widget.chatId, userId);
        if (!hasRated) {
          _showRatingDialog();
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Swap marked as completed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark swap as completed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isCompletingSwap = false;
      });
    }
  }

  void _showRatingDialog() {
    double rating = 0;
    final TextEditingController reviewController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Rate Your Swap'),
        content: SingleChildScrollView( // ✅ wrap content
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'How was your swap experience?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 40,
                itemBuilder: (context, index) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (value) {
                  rating = value;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                decoration: const InputDecoration(
                  hintText: 'Optional: Share your experience...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (rating > 0) {
                Navigator.of(context).pop();
                await _submitRating(rating, reviewController.text.trim());
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRating(double rating, String reviewText) async {
    if (_chat == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;

    if (userId == null) return;

    try {
      final otherUserId = _chatService.getOtherParticipantId(_chat!, userId);

      await _chatService.submitRating(
        fromUserId: userId,
        toUserId: otherUserId,
        chatId: widget.chatId,
        rating: rating,
        reviewText: reviewText.isNotEmpty ? reviewText : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your rating!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_chat == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Chat not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: _showChatInfo,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_chatItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _buildItemsPreview(),
              ),
            Expanded(
              child: _buildMessagesList(),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsPreview() {
    return SizedBox(
      height: 60, // 🔧 define a fixed height
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.swap_horiz, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _chatItems.map((item) => item.title).join(' ↔ '),
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildMessagesList() {
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.uid;

    return StreamBuilder<List<MessageModel>>(
      stream: _chatService.getMessages(widget.chatId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!;
        if (messages.isEmpty) {
          return const Center(child: Text('No messages yet'));
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          itemCount: messages.length,
          reverse: true,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final isMyMessage = msg.senderId == currentUserId;

            if (msg.messageType == 'system') {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              );
            }

            return _MessageBubble(
              message: msg,
              isMyMessage: isMyMessage,
            );
          },

        );
      },
    );
  }


  Widget _buildMessageInput() {
    final shouldShowMarkCompleted = _chat != null &&
        _chat!.status != 'completed' &&
        !_chatService.hasUserCompletedSwap(
          _chat!,
          Provider.of<AuthProvider>(context, listen: false).currentUser?.uid ?? '',
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_chat != null && _chat!.status == 'completed')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Swap completed successfully!',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (shouldShowMarkCompleted)
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: ElevatedButton.icon(
              onPressed: _isCompletingSwap ? null : _markSwapAsCompleted,
              icon: _isCompletingSwap
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.check_circle),
              label: Text(_isCompletingSwap ? 'Marking...' : 'Mark Swap as Completed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }


  void _showChatInfo() {
    Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Chat Info'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Created:', _formatDate(_chat!.createdAt)),
            const SizedBox(height: 8),
            _infoRow('Last Activity:', _formatDate(_chat!.lastMessageAt)),
            const SizedBox(height: 8),
            Text('Status: ${_chat!.status == 'completed' ? 'Completed' : 'Active'}'),
            if (_chat!.status == 'completed') ...[
              const SizedBox(height: 8),
              Text(
                'Completed by: ${_chat!.completedByUserA ? 'User A' : ''}${_chat!.completedByUserA && _chat!.completedByUserB ? ' & ' : ''}${_chat!.completedByUserB ? 'User B' : ''}',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
              ),
            ] else ...[
              const SizedBox(height: 8),
              const Text(
                'Completion Status:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('User A: ${_chat!.completedByUserA ? 'Completed' : 'Pending'}'),
              Text('User B: ${_chat!.completedByUserB ? 'Completed' : 'Pending'}'),
            ],
            if (_chatItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Items in this swap:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._chatItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• ${item.title}', style: const TextStyle(color: Colors.black87)),
              )),
            ],
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.close),
            label: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMyMessage;

  const _MessageBubble({
    required this.message,
    required this.isMyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isMyMessage
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMyMessage ? 16 : 0),
              bottomRight: Radius.circular(isMyMessage ? 0 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: TextStyle(
                  fontSize: 15,
                  color: isMyMessage ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: isMyMessage ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}