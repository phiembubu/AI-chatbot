import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCache();
  }

  Future<void> _loadCache() async {
    final cached = await CacheService.loadHistory();
    if (cached.isNotEmpty) {
      setState(() {
        _messages = cached;
      });
      _scrollToBottom();
    } else {
      setState(() {
        _messages.add(ChatMessage(text: "Hello! I am the SchoolHub Mobile Assistant. How can I help you today?", isUser: false));
      });
    }
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

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    // The user's manually rewritten `rag_pipeline` in main.py doesn't actually process chat_history,
    // but we pass it anyway to keep state structurally sound for standard LangChain integrations.
    try {
      final answer = await ApiService.askQuestion(text, _messages);
      setState(() {
        _messages.add(ChatMessage(text: answer, isUser: false));
        _isLoading = false;
      });
      // Save offline cache
      await CacheService.saveHistory(_messages);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: e.toString(), isUser: false));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  Future<void> _submitFeedback(String botAnswer, String rating) async {
    // Find the question that preceded this answer (crude lookup)
    int idx = _messages.indexWhere((m) => m.text == botAnswer);
    String prevQ = "Unknown Question";
    if (idx > 0 && _messages[idx-1].isUser) {
      prevQ = _messages[idx-1].text;
    }

    final success = await ApiService.submitFeedback(prevQ, botAnswer, rating);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Feedback submitted!' : 'Failed to submit feedback. Backend may be unreachable.'))
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            const CircleAvatar(
              backgroundColor: Colors.indigo,
              child: Icon(Icons.school, color: Colors.white, size: 20),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.indigo : Theme.of(context).cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 0),
                  bottomRight: Radius.circular(message.isUser ? 0 : 16),
                ),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : null,
                      fontSize: 16
                    ),
                  ),
                  if (!message.isUser)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.thumb_up_alt_outlined, size: 18, color: Colors.grey),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.only(right: 12),
                            onPressed: () => _submitFeedback(message.text, 'upvote'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.thumb_down_alt_outlined, size: 18, color: Colors.grey),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: () => _submitFeedback(message.text, 'downvote'),
                          ),
                        ],
                      ),
                    )
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (message.isUser)
            CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              child: const Icon(Icons.person, color: Colors.white),
            )
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))]
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300)
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: 5,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Ask about tuition, dorms, etc...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Colors.indigo,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            itemCount: _messages.length,
            itemBuilder: (context, index) => _buildMessage(_messages[index]),
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
        _buildTextComposer(),
      ],
    );
  }
}
