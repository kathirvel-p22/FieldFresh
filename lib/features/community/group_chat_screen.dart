import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../core/constants.dart';
import '../../services/supabase_service.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  StreamSubscription? _messageSubscription;
  Map<String, dynamic>? _groupInfo;
  int _memberCount = 0;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadGroupInfo();
    _loadMessages();
    _subscribeToMessages();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = SupabaseService.currentUserId;
      if (userId == null) return;

      final memberData = await supabase
          .from('group_members')
          .select('role')
          .eq('group_id', widget.groupId)
          .eq('user_id', userId)
          .single();

      setState(() {
        _userRole = memberData['role'];
      });
    } catch (e) {
      print('Error loading user role: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadGroupInfo() async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('community_groups')
          .select('*')
          .eq('id', widget.groupId)
          .single();

      setState(() {
        _groupInfo = data;
        _memberCount = data['member_count'] ?? 0;
      });
    } catch (e) {
      print('Error loading group info: $e');
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('group_messages')
          .select('*')
          .eq('group_id', widget.groupId)
          .eq('is_deleted', false)
          .order('created_at', ascending: true)
          .limit(100);

      setState(() {
        _messages = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });

      _scrollToBottom();
    } catch (e) {
      print('Error loading messages: $e');
      setState(() => _loading = false);
    }
  }

  void _subscribeToMessages() {
    final supabase = Supabase.instance.client;
    _messageSubscription = supabase
        .from('group_messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .listen((data) {
          final filteredMessages = data
              .where((msg) => 
                  msg['group_id'] == widget.groupId && 
                  msg['is_deleted'] == false)
              .toList();
          
          setState(() {
            _messages = List<Map<String, dynamic>>.from(filteredMessages);
          });

          _scrollToBottom();
        });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      final supabase = Supabase.instance.client;
      final userId = SupabaseService.currentUserId;
      if (userId == null) return;

      final userData = await supabase
          .from('users')
          .select('name, role')
          .eq('id', userId)
          .single();

      await supabase.from('group_messages').insert({
        'group_id': widget.groupId,
        'user_id': userId,
        'user_name': userData['name'] ?? 'User',
        'user_role': userData['role'] ?? 'customer',
        'message': text,
        'message_type': 'text',
      });

      _messageController.clear();
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: AppColors.error),
                SizedBox(width: 8),
                Text('Error'),
              ],
            ),
            content: Text('Failed to send message:\n\n${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('group_messages')
          .update({'is_deleted': true})
          .eq('id', messageId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Message deleted')),
        );
      }
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  Future<void> _leaveGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final supabase = Supabase.instance.client;
      final userId = SupabaseService.currentUserId;
      if (userId == null) return;

      await supabase
          .from('group_members')
          .delete()
          .eq('group_id', widget.groupId)
          .eq('user_id', userId);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Left group successfully')),
        );
      }
    } catch (e) {
      print('Error leaving group: $e');
    }
  }

  void _showMembersList() async {
    try {
      final supabase = Supabase.instance.client;
      final membersData = await supabase
          .from('group_members')
          .select('*, users(name, role)')
          .eq('group_id', widget.groupId)
          .order('joined_at', ascending: false);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Group Members',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${membersData.length} members',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: membersData.length,
                    itemBuilder: (context, index) {
                      final member = membersData[index];
                      final user = member['users'] as Map<String, dynamic>?;
                      final userName = user?['name'] ?? 'User';
                      final userRole = user?['role'] ?? 'customer';
                      final memberRole = member['role'] ?? 'member';
                      final isAdmin = memberRole == 'admin';
                      final canRemove = _userRole == 'admin' && !isAdmin;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getRoleColor(userRole),
                          child: Text(
                            userName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(userName),
                        subtitle: Text(
                          '${_getRoleLabel(userRole)} • ${isAdmin ? "Admin" : "Member"}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: canRemove
                            ? IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: AppColors.error),
                                onPressed: () => _removeMember(member['user_id']),
                              )
                            : isAdmin
                                ? const Icon(Icons.star, color: Colors.amber)
                                : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error loading members: $e');
    }
  }

  Future<void> _removeMember(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('group_members')
          .delete()
          .eq('group_id', widget.groupId)
          .eq('user_id', userId);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Member removed')),
        );
      }
    } catch (e) {
      print('Error removing member: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.groupName, style: const TextStyle(fontSize: 16)),
            Text('$_memberCount members',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showGroupInfo(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'members') {
                _showMembersList();
              } else if (value == 'leave') {
                _leaveGroup();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'members',
                child: Row(
                  children: [
                    Icon(Icons.people, size: 20),
                    SizedBox(width: 8),
                    Text('View Members'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, size: 20, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Leave Group', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('💬', style: TextStyle(fontSize: 64)),
                            SizedBox(height: 12),
                            Text('No messages yet', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 4),
                            Text('Be the first to say hello!',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message['user_id'] == SupabaseService.currentUserId;
                          return _buildMessageBubble(message, isMe);
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final userName = message['user_name'] ?? 'User';
    final userRole = message['user_role'] ?? 'customer';
    final text = message['message'] ?? '';
    final timestamp = DateTime.tryParse(message['created_at'] ?? '');
    final messageId = message['id'];
    final canDelete = isMe || _userRole == 'admin';

    return GestureDetector(
      onLongPress: canDelete
          ? () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Message'),
                  content: const Text('Are you sure you want to delete this message?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteMessage(messageId);
                      },
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: _getRoleColor(userRole),
                child: Text(
                  userName[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: _getRoleColor(userRole).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              _getRoleLabel(userRole),
                              style: TextStyle(
                                fontSize: 8,
                                color: _getRoleColor(userRole),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        color: isMe ? Colors.white : AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (timestamp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatTime(timestamp),
                        style: const TextStyle(fontSize: 10, color: AppColors.textHint),
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

  Color _getRoleColor(String role) {
    switch (role) {
      case 'farmer':
        return AppColors.secondary;
      case 'admin':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'farmer':
        return 'FARMER';
      case 'admin':
        return 'ADMIN';
      default:
        return 'CUSTOMER';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showGroupInfo() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.groupName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_groupInfo != null) ...[
              Text(
                _groupInfo!['description'] ?? '',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.people, size: 20, color: AppColors.textHint),
                  const SizedBox(width: 8),
                  Text('$_memberCount members', style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.category, size: 20, color: AppColors.textHint),
                  const SizedBox(width: 8),
                  Text(_groupInfo!['category'] ?? '', style: const TextStyle(fontSize: 14)),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
