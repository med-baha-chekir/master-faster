// Uses Google Gemini API via backend
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/response_card.dart';

class LLMService {
  Future<List<ResponseCard>> generateResponseCards(String transcript) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null) throw Exception('API key not found');

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
      );
      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text":
                    "Based on this phone call transcript, generate exactly 3 short response options (max 5 words each) that a non-verbal user can tap to reply. Return ONLY a valid JSON array of strings, no explanation, no markdown. Transcript: $transcript",
              },
            ],
          },
        ],
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        // Remove Markdown code block if present
        String cleanText = text.trim();
        if (cleanText.startsWith('```json')) {
          cleanText = cleanText.substring(7);
        } else if (cleanText.startsWith('```')) {
          cleanText = cleanText.substring(3);
        }
        if (cleanText.endsWith('```')) {
          cleanText = cleanText.substring(0, cleanText.length - 3);
        }

        final list = List<String>.from(jsonDecode(cleanText));
        // Return only string list wrapped in ResponseCard
        return list.map((s) => ResponseCard(label: s, fullText: s)).toList();
      } else {
        throw Exception('Failed to generate cards: ${response.statusCode}');
      }
    } catch (e) {
      return [
        ResponseCard(label: "Yes", fullText: "Yes"),
        ResponseCard(label: "No", fullText: "No"),
        ResponseCard(label: "Repeat please", fullText: "Repeat please"),
      ];
    }
  }

  Future<String> generateCallSummary(String transcript) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null) throw Exception('API key not found');

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
      );
      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text":
                    "Summarize this phone call in 2-3 sentences. List any confirmed actions on a new line starting with Action:. Be concise and clear. Transcript: $transcript",
              },
            ],
          },
        ],
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] as String;
      } else {
        throw Exception('Failed to generate summary');
      }
    } catch (e) {
      return "Call completed.";
    }
  }
}
