

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dddd_buddy/screens/chat/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  final String userId;
  const HomePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isConnecting = false;
  StreamSubscription? _chatSubscription;

  @override
  void initState() {
    super.initState();
    _checkForExistingChat();
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    super.dispose();
  }

  // --- Check if the user is already in an active chat ---
  void _checkForExistingChat() {
    _chatSubscription = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: widget.userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final chatDoc = snapshot.docs.first;
        final chatData = chatDoc.data();
        // Ensure createdAt is not null before proceeding
        if (chatData['createdAt'] != null) {
          final Timestamp createdAt = chatData['createdAt'];
          final expiryTime = createdAt.toDate().add(const Duration(hours: 24));

          if (DateTime.now().isBefore(expiryTime) && mounted) {
            // If chat is still active, navigate to it
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  chatId: chatDoc.id,
                  currentUserId: widget.userId,
                ),
              ),
            );
          }
        }
      }
    });
  }

  // --- Logic to find a random buddy ---
  Future<void> _connectWithBuddy() async {
    setState(() {
      _isConnecting = true;
    });

    final firestore = FirebaseFirestore.instance;

    try {
      // 1. Look for someone in the 'waitingPool'
      final waitingPoolQuery = await firestore
          .collection('waitingPool')
          .where('userId', isNotEqualTo: widget.userId)
          .limit(1)
          .get();

      if (waitingPoolQuery.docs.isNotEmpty) {
        // --- Buddy Found! ---
        final buddyDoc = waitingPoolQuery.docs.first;
        final buddyId = buddyDoc.id;

        // 2. Create a new chat room
        final chatDocRef = await firestore.collection('chats').add({
          'participants': [widget.userId, buddyId],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': 'Chat started!',
        });

        // 3. Delete the buddy from the waiting pool
        await firestore.collection('waitingPool').doc(buddyId).delete();

        if (!mounted) return;
        // 4. Navigate to the chat page
        _chatSubscription?.cancel(); // Stop listening for new chats
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChatPage(
              chatId: chatDocRef.id,
              currentUserId: widget.userId,
            ),
          ),
        );
      } else {
        // --- No Buddy Found, Add self to waiting pool ---
        await firestore.collection('waitingPool').doc(widget.userId).set({
          'userId': widget.userId,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Searching for a buddy... Please wait.")),
           );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Connection Error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('കിളി പോയ Buddy Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Also remove user from waiting pool if they log out
              await FirebaseFirestore.instance.collection('waitingPool').doc(widget.userId).delete();
              await FirebaseAuth.instance.signOut();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_alt_outlined, size: 100, color: Colors.teal),
            const SizedBox(height: 20),
            const Text(
              'കിളി പോകാൻ നിങ്ങൾ തയാറാണോ?',
              style: TextStyle(fontFamily: 'Manjari',fontSize: 22, fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 40),
            _isConnecting
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    icon: const Icon(Icons.connect_without_contact),
                    label: const Text('Connect with a Buddy', style: TextStyle(fontSize: 18)),
                    onPressed: _connectWithBuddy,
                  ),
          ],
        ),
      ),
    );
  }
}