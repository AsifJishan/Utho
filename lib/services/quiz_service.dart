import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/quiz_model.dart';

class QuizService {
  Future<QuizQuestion> fetchQuizQuestion() async {
    try {
      debugPrint('Attempting to fetch question from API...');
      
      // Generate random Surah selection (1-114 are valid Surah numbers)
      final random = Random();
      final List<int> randomSurahs = [];
      
      // Generate 5 random unique Surah numbers
      while (randomSurahs.length < 5) {
        int surahNumber = random.nextInt(114) + 1; // 1-114
        if (!randomSurahs.contains(surahNumber)) {
          randomSurahs.add(surahNumber);
        }
      }
      
      // Convert to comma-separated string
      final surahSelection = randomSurahs.join(',');
      
      debugPrint('Using random Surahs: $surahSelection');
      
      // Use the correct API endpoint with random Surah selection
      final response = await http.get(
        Uri.parse('https://quran.zakiego.com/api/guessSurah?select=$surahSelection&amount=3'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'User-Agent': 'Flutter App',
        },
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Handle the correct API response structure
        if (responseData['message'] == 'success' && responseData['data'] != null) {
          final questions = responseData['data'] as List;
          if (questions.isNotEmpty) {
            // Pick a random question from the returned array
            final randomQuestion = questions[random.nextInt(questions.length)];
            return QuizQuestion.fromJson(randomQuestion);
          } else {
            throw Exception('No questions in API response');
          }
        } else {
          throw Exception('API response format error');
        }
      } else {
        throw Exception('API returned status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching quiz question: $e');
      throw Exception('Failed to fetch quiz question: $e');
    }
  }
}