import 'package:flutter/material.dart';

void main() {
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat UI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ChatListScreen(),
    );
  }
}

// ─────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────

class Contact {
  final String name;
  final String initials;
  final Color avatarColor;

  const Contact({
    required this.name,
    required this.initials,
    required this.avatarColor,
  });
}

class Conversation {
  final Contact contact;
  final String lastMessage;
  final String timestamp;
  final List<ChatMessage> messages;

  Conversation({
    required this.contact,
    required this.lastMessage,
    required this.timestamp,
    required this.messages,
  });
}

class ChatMessage {
  final String text;
  final bool isSent;
  final String time;

  ChatMessage({required this.text, required this.isSent, required this.time});
}

// ─────────────────────────────────────────────
// Sample Data
// ─────────────────────────────────────────────

final List<Conversation> sampleConversations = [
  Conversation(
    contact: const Contact(
      name: 'Alice Johnson',
      initials: 'AJ',
      avatarColor: Colors.purple,
    ),
    lastMessage: 'See you at the meeting!',
    timestamp: '10:42 AM',
    messages: [
      ChatMessage(text: 'Hey! Are you coming to the standup?', isSent: false, time: '10:38 AM'),
      ChatMessage(text: 'Yes, I\'ll be there in 5 minutes.', isSent: true, time: '10:40 AM'),
      ChatMessage(text: 'Great, I\'ll save you a seat.', isSent: false, time: '10:41 AM'),
      ChatMessage(text: 'See you at the meeting!', isSent: true, time: '10:42 AM'),
    ],
  ),
  Conversation(
    contact: const Contact(
      name: 'Bob Martinez',
      initials: 'BM',
      avatarColor: Colors.teal,
    ),
    lastMessage: 'The report looks good!',
    timestamp: '9:15 AM',
    messages: [
      ChatMessage(text: 'Did you review the Q3 report?', isSent: true, time: '9:10 AM'),
      ChatMessage(text: 'Just finished reading it.', isSent: false, time: '9:13 AM'),
      ChatMessage(text: 'Any concerns?', isSent: true, time: '9:14 AM'),
      ChatMessage(text: 'The report looks good!', isSent: false, time: '9:15 AM'),
    ],
  ),
  Conversation(
    contact: const Contact(
      name: 'Carol Smith',
      initials: 'CS',
      avatarColor: Colors.orange,
    ),
    lastMessage: 'Can we reschedule for Friday?',
    timestamp: 'Yesterday',
    messages: [
      ChatMessage(text: 'Hi Carol, are we still on for Thursday?', isSent: true, time: '4:00 PM'),
      ChatMessage(text: 'Something came up on my end.', isSent: false, time: '4:05 PM'),
      ChatMessage(text: 'Can we reschedule for Friday?', isSent: false, time: '4:05 PM'),
    ],
  ),
  Conversation(
    contact: const Contact(
      name: 'David Lee',
      initials: 'DL',
      avatarColor: Colors.green,
    ),
    lastMessage: 'Thanks for the update!',
    timestamp: 'Mon',
    messages: [
      ChatMessage(text: 'The deployment went smoothly.', isSent: true, time: '2:00 PM'),
      ChatMessage(text: 'No downtime?', isSent: false, time: '2:02 PM'),
      ChatMessage(text: 'Zero downtime, all good.', isSent: true, time: '2:03 PM'),
      ChatMessage(text: 'Thanks for the update!', isSent: false, time: '2:04 PM'),
    ],
  ),
  Conversation(
    contact: const Contact(
      name: 'Eva Chen',
      initials: 'EC',
      avatarColor: Colors.pink,
    ),
    lastMessage: 'Let\'s grab coffee soon!',
    timestamp: 'Sun',
    messages: [
      ChatMessage(text: 'Long time no talk!', isSent: false, time: '11:00 AM'),
      ChatMessage(text: 'I know, been so busy lately.', isSent: true, time: '11:05 AM'),
      ChatMessage(text: 'Let\'s grab coffee soon!', isSent: false, time: '11:07 AM'),
    ],
  ),
];

// ─────────────────────────────────────────────
// Settings State
// ─────────────────────────────────────────────

class AppSettings {
  bool notificationsEnabled;
  String fontSize;
  String wallpaper;

  AppSettings({
    this.notificationsEnabled = true,
    this.fontSize = 'Medium',
    this.wallpaper = 'Default',
  });
}

final AppSettings globalSettings = AppSettings();

// ─────────────────────────────────────────────
// Chat List Screen
// ─────────────────────────────────────────────

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: const AppDrawer(),
      body: ListView.separated(
        itemCount: sampleConversations.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final convo = sampleConversations[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: convo.contact.avatarColor,
              child: Text(
                convo.contact.initials,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(convo.contact.name),
            subtitle: Text(
              convo.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              convo.timestamp,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailScreen(conversation: convo),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// App Drawer
// ─────────────────────────────────────────────

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Text(
              'Chat UI',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile tapped')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out')),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Chat Detail Screen
// ─────────────────────────────────────────────

class ChatDetailScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatDetailScreen({super.key, required this.conversation});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  late List<ChatMessage> _messages;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.conversation.messages);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isSent: true,
        time: 'Now',
      ));
      _controller.clear();
    });
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.inversePrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.conversation.contact.name),
            const Text(
              'Online',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _MessageBubble(message: msg);
              },
            ),
          ),
          _BottomInputBar(
            controller: _controller,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Message Bubble
// ─────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSent = message.isSent;

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isSent ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isSent ? 16 : 4),
            bottomRight: Radius.circular(isSent ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isSent ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.time,
              style: TextStyle(
                fontSize: 10,
                color: isSent
                    ? colorScheme.onPrimary.withAlpha(180)
                    : colorScheme.onSurface.withAlpha(130),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bottom Input Bar
// ─────────────────────────────────────────────

class _BottomInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _BottomInputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: onSend,
              icon: const Icon(Icons.send),
              tooltip: 'Send',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Settings Screen
// ─────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _notifications;
  late String _fontSize;
  late String _wallpaper;

  @override
  void initState() {
    super.initState();
    _notifications = globalSettings.notificationsEnabled;
    _fontSize = globalSettings.fontSize;
    _wallpaper = globalSettings.wallpaper;
  }

  void _clearAllChats() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Chats'),
        content: const Text('Are you sure you want to clear all chats? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All chats cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Enable push notifications'),
            value: _notifications,
            onChanged: (val) {
              setState(() {
                _notifications = val;
                globalSettings.notificationsEnabled = val;
              });
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.wallpaper),
            title: const Text('Chat Wallpaper'),
            subtitle: Text(_wallpaper),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wallpaper picker coming soon')),
              );
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Font Size', style: TextStyle(fontSize: 16)),
                DropdownButton<String>(
                  value: _fontSize,
                  items: const [
                    DropdownMenuItem(value: 'Small', child: Text('Small')),
                    DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'Large', child: Text('Large')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _fontSize = val;
                        globalSettings.fontSize = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: FilledButton(
              onPressed: _clearAllChats,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Clear All Chats'),
            ),
          ),
        ],
      ),
    );
  }
}
