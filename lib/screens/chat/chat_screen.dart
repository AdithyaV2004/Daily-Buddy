

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp, FirebaseFirestore, FieldValue, QuerySnapshot;
import 'package:dddd_buddy/screens/chat/widgets/message_bubble.dart';
import 'package:dddd_buddy/screens/home/home_screen.dart';
import 'package:dddd_buddy/services/groq_service.dart' show GroqService;
import 'package:flutter/material.dart' show AlertDialog, AppBar, BuildContext, Center, CircularProgressIndicator, Colors, Column, ConnectionState, Container, CrossAxisAlignment, EdgeInsets, Expanded, FontWeight, Icon, IconButton, Icons, InputDecoration, Key, ListView, MaterialPageRoute, Navigator, Padding, Row, Scaffold, ScaffoldMessenger, SizedBox, SnackBar, State, StatefulWidget, StreamBuilder, Text, TextButton, TextCapitalization, TextEditingController, TextField, TextStyle, Widget, showDialog;

class ChatPage extends StatefulWidget {
  final String chatId;
  final String currentUserId;

  const ChatPage({
    Key? key,
    required this.chatId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _groqService = GroqService(); // Create an instance of the service
  String _buddyUsername = 'My Buddy';
  Timestamp? _chatCreatedAt;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _getChatDetails();
  }

  Future<void> _getChatDetails() async {
    // ... This method remains unchanged ...
  }

  void _sendMessage() async {
    final originalMessageText = _messageController.text.trim();
    if (originalMessageText.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      // Use the service to get the transformed message
      final transformedMessageText = await _groqService.getOppositeMessage(originalMessageText);

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'originalText': originalMessageText,
        'transformedText': transformedMessageText,
        'senderId': widget.currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to send message: $e")));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // --- Disconnect and delete the chat ---
  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect?'),
        content: const Text('This will end the chat for both of you. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Disconnect')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Deletes the chat document from Firestore
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).delete();
      
      // Navigates the user back to the HomePage
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomePage(userId: widget.currentUserId)),
        (route) => false,
      );
    }
  }
  
  @override
 Widget build(BuildContext context) {
   // Calculate remaining time
   Duration? remainingTime;
   if (_chatCreatedAt != null) {
     final expiryTime = _chatCreatedAt!.toDate().add(const Duration(hours: 24));
     remainingTime = expiryTime.difference(DateTime.now());
     if (remainingTime.isNegative) {
       remainingTime = Duration.zero;
     }
   }

   return Scaffold(
     appBar: AppBar(
       title: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text(_buddyUsername, style: const TextStyle(fontSize: 18)),
           if (remainingTime != null)
             Text(
               '${remainingTime.inHours}h ${remainingTime.inMinutes.remainder(60)}m left',
               style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal,color: Colors.black),
             ),
         ],
       ),
       actions: [
         IconButton(
           icon: const Icon(Icons.link_off),
           onPressed: _disconnect,
           tooltip: 'Disconnect',
         ),
       ],
     ),
     body: Column(
       children: [
         // --- Messages Area ---
         Expanded(
           child: StreamBuilder<QuerySnapshot>(
             stream: FirebaseFirestore.instance
                 .collection('chats')
                 .doc(widget.chatId)
                 .collection('messages')
                 .orderBy('timestamp', descending: true)
                 .snapshots(),
             builder: (context, snapshot) {
               if (snapshot.connectionState == ConnectionState.waiting) {
                 return const Center(child: CircularProgressIndicator());
               }
               if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                 return const Center(child: Text("Hi പറയുക!",style: TextStyle(fontFamily: 'Manjari',),));
               }
               final messages = snapshot.data!.docs;

               return ListView.builder(
                 reverse: true,
                 padding: const EdgeInsets.all(10.0),
                 itemCount: messages.length,
                 itemBuilder: (context, index) {
                   final messageData = messages[index].data() as Map<String, dynamic>;
                   final isMe = messageData['senderId'] == widget.currentUserId;

                   final textToShow = isMe
                       ? messageData['originalText']
                       : (messageData['transformedText'] ?? messageData['originalText']);

                   // Note: We use the public `MessageBubble` class now
                   return MessageBubble(
                     text: textToShow,
                     isMe: isMe,
                   );
                 },
               );
             },
           ),
         ),
         // --- Message Input Area ---
         _buildMessageComposer(),
       ],
     ),
   );
 }

 // --- Widget for the text input field and send button ---
 Widget _buildMessageComposer() {
   return Container(
     padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
     color: Colors.grey[200],
     child: Row(
       children: [
         Expanded(
           child: TextField(
             controller: _messageController,
             decoration: const InputDecoration.collapsed(
               hintText: 'Send a message...',
             ),
             textCapitalization: TextCapitalization.sentences,
           ),
         ),
         _isSending
             ? const Padding(
                 padding: EdgeInsets.symmetric(horizontal: 12.0),
                 child: SizedBox(
                   width: 24,
                   height: 24,
                   child: CircularProgressIndicator(strokeWidth: 2.0),
                 ),
               )
             : IconButton(
                 icon: const Icon(Icons.send, color: Colors.teal),
                 onPressed: _sendMessage,
               ),
       ],
     ),
   );
 }
}