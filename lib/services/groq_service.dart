

import 'dart:convert';

import 'package:dddd_buddy/config/api_key.dart' show groqApiKey;
import 'package:http/http.dart' as http;

class GroqService {
  static const String _apiUrl = 'https://api.groq.com/openai/v1/chat/completions';

  Future<String> getOppositeMessage(String originalText) async {
    if (groqApiKey == 'YOUR_GROQ_API_KEY_HERE') {
      print("Warning: Groq API Key is not set. Returning original message.");
      return originalText;
    }

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
        {"role": "user", "content": originalText}
      ],
      "model": "llama3-8b-8192",
    });

    try {
      final response = await http.post(Uri.parse(_apiUrl), headers: headers, body: body);
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return responseBody['choices'][0]['message']['content'].trim();
      } else {
        print("Groq API Error: ${response.statusCode} ${response.body}");
        return originalText; // Fallback to original text
      }
    } catch (e) {
      print("Error calling Groq API: $e");
      return originalText; // Fallback to original text
    }
  }
}