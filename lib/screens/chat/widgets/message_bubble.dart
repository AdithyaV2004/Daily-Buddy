

import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;

  const MessageBubble({Key? key, required this.text, required this.isMe}) : super(key: key);

  @override
 Widget build(BuildContext context) {
   return Row(
     mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
     children: [
       Container(
         decoration: BoxDecoration(
           color: isMe ? Colors.teal[300] : Colors.grey[300],
           borderRadius: BorderRadius.only(
             topLeft: const Radius.circular(12),
             topRight: const Radius.circular(12),
             bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
             bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
           ),
         ),
         constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
         padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
         margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
         child: Text(
           text,
           style: TextStyle(color: isMe ? Colors.white : Colors.black87),
         ),
       ),
     ],
   );
 }
}