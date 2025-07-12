import 'package:flutter/material.dart';
import 'dart:async';
import '../viewmodels/alarm_viewmodel.dart';
import '../models/quiz_model.dart';

class QuizDialog extends StatefulWidget {
  final AlarmViewModel viewModel;

  const QuizDialog({super.key, required this.viewModel});

  @override
  State<QuizDialog> createState() => _QuizDialogState();
}

class _QuizDialogState extends State<QuizDialog> {
  QuizQuestion? _currentQuestion;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNextQuestion();
  }

  Future<void> _loadNextQuestion() async {
    if (widget.viewModel.isQuizCompleted) {
      _showSuccessDialog();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final question = await widget.viewModel.fetchQuizQuestion();
      setState(() {
        _currentQuestion = question;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog();
    }
  }

  void _handleAnswer(String selectedAnswer) {
    if (_currentQuestion == null) return;

    final isCorrect = selectedAnswer == _currentQuestion!.correctAnswer;
    widget.viewModel.handleQuizAnswer(isCorrect);

    _showAnswerFeedback(isCorrect);

    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pop(); // Close feedback dialog
        if (widget.viewModel.isQuizCompleted) {
          _showSuccessDialog();
        } else {
          _loadNextQuestion();
        }
      }
    });
  }

  void _showAnswerFeedback(bool isCorrect) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
          title: Column(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 10),
              Text(
                isCorrect ? 'Correct!' : 'Wrong Answer!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Progress: ${widget.viewModel.quizModel.correctAnswers}/${widget.viewModel.quizModel.requiredCorrectAnswers} correct',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Text(
                'Total questions: ${widget.viewModel.quizModel.totalQuestions}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green.shade800,
          title: const Column(
            children: [
              Icon(Icons.celebration, size: 64, color: Colors.white),
              SizedBox(height: 10),
              Text(
                'Congratulations!',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You got ${widget.viewModel.quizModel.correctAnswers} correct answers!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Total questions answered: ${widget.viewModel.quizModel.totalQuestions}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Alarm has been turned off!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close success dialog
                Navigator.of(context).pop(); // Close quiz dialog
                widget.viewModel.stopAlarm();
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red.shade800,
          title: const Icon(Icons.error, size: 64, color: Colors.white),
          content: const Text(
            'Failed to load quiz question from API.\nThe API might be down or changed.',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close error dialog
                Navigator.of(context).pop(); // Close quiz dialog
                widget.viewModel.stopAlarm();
              },
              child: const Text(
                'Turn Off Alarm',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close error dialog
                _loadNextQuestion();
              },
              child: const Text(
                'Try Again',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AlertDialog(
        backgroundColor: Colors.grey.shade900,
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Loading quiz question...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_currentQuestion == null) {
      return AlertDialog(
        backgroundColor: Colors.red.shade800,
        title: const Icon(Icons.error, size: 64, color: Colors.white),
        content: const Text(
          'Failed to load quiz question.',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.viewModel.stopAlarm();
            },
            child: const Text(
              'Turn Off Alarm',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    }

    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      title: Column(
        children: [
          const Icon(Icons.quiz, size: 48, color: Colors.white),
          const SizedBox(height: 10),
          const Text(
            'Quiz Progress',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Correct: ${widget.viewModel.quizModel.correctAnswers}/${widget.viewModel.quizModel.requiredCorrectAnswers}',
                style: const TextStyle(color: Colors.green, fontSize: 16),
              ),
              const SizedBox(width: 15),
              Text(
                'Total: ${widget.viewModel.quizModel.totalQuestions}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Which Surah is this verse from?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade600),
            ),
            child: Text(
              _currentQuestion!.question,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontFamily: 'serif',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ..._currentQuestion!.options.map((option) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton(
              onPressed: () => _handleAnswer(option),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                option,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }
}