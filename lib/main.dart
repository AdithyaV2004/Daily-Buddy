import 'dart:async';
import 'dart:convert'; // NEW: Added for JSON encoding/decoding
import 'package:dddd_buddy/api_key.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http; // NEW: Added for making HTTP requests
import 'firebase_options.dart';

// NEW: Add your Groq API key here.
// IMPORTANT: For a production app, use environment variables (e.g., flutter_dotenv) to keep your key secure.

// --- Main Function: Entry point of the app ---
void main() async {
  // Ensure Flutter widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DailyBuddyApp());
}

// --- App's Root Widget ---
class DailyBuddyApp extends StatelessWidget {
  const DailyBuddyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DailyBuddy',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- AuthWrapper: Decides which page to show (Login or Home) ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens to authentication state changes
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData && snapshot.data != null) {
          // If user is logged in, show HomePage
          return HomePage(userId: snapshot.data!.uid);
        }
        // If user is not logged in, show LoginPage
        return const LoginPage();
      },
    );
  }
}

// --- LoginPage: For user registration ---
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // --- User Registration Logic ---
  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 1. Sign in anonymously to get a unique user ID (uid)
        UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
        User? user = userCredential.user;

        if (user != null) {
          // 2. Save the username and creation time in Firestore
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'username': _usernameController.text.trim(),
            'uid': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Firebase Error: ${e.message}")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred: $e")),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome to DailyBuddy!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Choose a username to get started',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Enter Username',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _register,
                        child: const Text('Register', style: TextStyle(fontSize: 18)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- HomePage: Where users connect with a buddy ---
class HomePage extends StatefulWidget {
  final String userId;
  const HomePage({Key? key, required this.userId}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
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
        final Timestamp createdAt = chatData['createdAt'];
        final expiryTime = createdAt.toDate().add(const Duration(hours: 24));

        if (DateTime.now().isBefore(expiryTime)) {
          // If chat is still active, navigate to it
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ChatPage(
                chatId: chatDoc.id,
                currentUserId: widget.userId,
              ),
            ),
          );
        } else {
          // Chat has expired, can be deleted or archived
          // For simplicity, we just allow creating a new one
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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Searching for a buddy... Please wait.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection Error: $e")),
      );
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
        title: const Text('DailyBuddy Home'),
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
              'Ready for a new connection?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 40),
            _isConnecting
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    icon: const Icon(Icons.connect_without_contact),
                    label: const Text('Connect Your Buddy', style: TextStyle(fontSize: 18)),
                    onPressed: _connectWithBuddy,
                  ),
          ],
        ),
      ),
    );
  }
}

// --- ChatPage: The actual chat screen ---
class ChatPage extends StatefulWidget {
  final String chatId;
  final String currentUserId;

  const ChatPage({
    Key? key,
    required this.chatId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  String _buddyUsername = 'Buddy';
  Timestamp? _chatCreatedAt;
  // NEW: State to track if a message is being sent/processed by the AI
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _getChatDetails();
  }

  // --- Fetch details about the chat and the buddy ---
  Future<void> _getChatDetails() async {
    final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get();
    if (chatDoc.exists) {
      final participants = List<String>.from(chatDoc.data()!['participants']);
      final buddyId = participants.firstWhere((id) => id != widget.currentUserId);
      _chatCreatedAt = chatDoc.data()!['createdAt'] as Timestamp?;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(buddyId).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _buddyUsername = userDoc.data()!['username'];
        });
      }
    }
  }

  // NEW: Function to call Groq API and get the opposite message
  Future<String> _getOppositeMessage(String originalText) async {
    // If the API key is missing, return the original text immediately.
    if (groqApiKey == 'YOUR_GROQ_API_KEY_HERE') {
      print("Warning: Groq API Key is not set. Returning original message.");
      return originalText;
    }

    const apiUrl = 'https://api.groq.com/openai/v1/chat/completions';
    final headers = {
      'Authorization': 'Bearer $groqApiKey',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      "messages": [
        {
          "role": "system",
          "content": "You are an AI assistant. Your only task is to transform the user's message into its opposite meaning. Respond with only the transformed sentence, without any explanation, intro, or quotation marks. For example, if the user says 'I am happy', you must only respond with 'I am sad'."
        },
        {
          "role": "user",
          "content": originalText,
        }
      ],
      "model": "llama3-8b-8192",
    });

    try {
      final response = await http.post(Uri.parse(apiUrl), headers: headers, body: body);
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        // Extract the AI's response text
        return responseBody['choices'][0]['message']['content'].trim();
      } else {
        // If API fails, return the original text as a fallback
        print("Groq API Error: ${response.statusCode} ${response.body}");
        return originalText;
      }
    } catch (e) {
      // If any other error occurs, return the original text
      print("Error calling Groq API: $e");
      return originalText;
    }
  }


  // NEW: Modified function to handle AI transformation
  void _sendMessage() async {
    final originalMessageText = _messageController.text.trim();
    if (originalMessageText.isEmpty || _isSending) {
      return; // Don't send empty messages or if already sending
    }

    setState(() {
      _isSending = true; // Set loading state
    });
    _messageController.clear(); // Clear input field immediately

    try {
      // 1. Get the transformed message from the AI
      final transformedMessageText = await _getOppositeMessage(originalMessageText);

      // 2. Save both original and transformed messages to Firestore
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'originalText': originalMessageText,
        'transformedText': transformedMessageText, // The message for the recipient
        'senderId': widget.currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send message: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false; // Unset loading state
        });
      }
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

    if (confirmed == true) {
      // For simplicity, we delete the chat document.
      // In a real app, you might archive it instead.
      // A more robust solution would be to delete the subcollection as well.
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).delete();
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
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
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
                  return const Center(child: Text("Say hi!"));
                }
                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(10.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;
                    final isMe = messageData['senderId'] == widget.currentUserId;

                    // NEW: Decide which message text to show.
                    // If I sent the message (isMe), show the 'originalText'.
                    // If I received the message, show the 'transformedText'.
                    // Use a fallback to 'originalText' if 'transformedText' is missing for old messages.
                    final textToShow = isMe
                        ? messageData['originalText']
                        : (messageData['transformedText'] ?? messageData['originalText']);

                    return _MessageBubble(
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
          // NEW: Show a spinner while the AI is processing the message.
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

// --- MessageBubble: A styled widget for a single chat message ---
class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;

  // NEW: Updated to handle potential null text values gracefully
  const _MessageBubble({Key? key, required this.text, required this.isMe}) : super(key: key);

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
            text, // The text is now determined in the ChatPage logic
            style: TextStyle(color: isMe ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }
}