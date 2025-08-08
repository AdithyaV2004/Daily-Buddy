

import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore, FieldValue;
import 'package:firebase_auth/firebase_auth.dart' show UserCredential, FirebaseAuth, User;
import 'package:flutter/material.dart' show StatefulWidget, Key, State, FormState, BuildContext, Widget, TextEditingController, GlobalKey, ScaffoldMessenger, Text, SnackBar, Scaffold, Center, SingleChildScrollView, EdgeInsets, SizedBox, Icon, CircularProgressIndicator, MainAxisAlignment, FontWeight, Colors, TextStyle, BorderRadius, OutlineInputBorder, Icons, InputDecoration, TextFormField, ElevatedButton, Column, Form;

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
        User? user = userCredential.user;

        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'username': _usernameController.text.trim(),
            'uid': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("An error occurred: $e")),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
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
                 'കിളി പോയ Buddy',
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