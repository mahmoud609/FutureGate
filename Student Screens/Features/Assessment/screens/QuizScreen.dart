import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/Assessment.dart';
import '../models/AssessmentResult.dart';
import '../models/Question.dart';
import 'package:project/Student Screens/Features/Assessment/services/AuthService.dart';
import '../services/FirebaseService.dart';
import '../widgets/CountdownTimer.dart';
import '../widgets/QuestionWidget.dart';
import 'ResultScreen.dart';

class QuizScreen extends StatefulWidget {
  final Assessment assessment;

  const QuizScreen({
    Key? key,
    required this.assessment,
  }) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late PageController _pageController;
  late FirebaseService _firebaseService;
  late AuthService _authService;
  List<Question> _questions = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _isSubmitting = false;
  int _secondsRemaining = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuestions();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _firebaseService = Provider.of<FirebaseService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final questions = await _firebaseService.getQuestionsForAssessment(widget.assessment.id);

      for (var question in questions) {
        question.options.shuffle();
      }

      if (mounted) {
        setState(() {
          _questions = questions;
          _secondsRemaining = widget.assessment.timeInMinutes * 60;
          _isLoading = false;
        });
      }

      _startTimer();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load questions: $e')),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      } else {
        _timer.cancel();
        _submitAssessment();
      }
    });
  }

  // Helper method to create detailed answers array
  List<Map<String, dynamic>> _createAnswersArray() {
    List<Map<String, dynamic>> answers = [];

    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final isCorrect = question.selectedOption == question.answer;
      final isAnswered = question.selectedOption != null;

      answers.add({
        'questionIndex': i + 1,
        'questionId': question.id ?? 'question_${i + 1}',
        'questionText': question.questionText,
        'correctAnswer': question.answer,
        'userAnswer': question.selectedOption,
        'allOptions': question.options,
        'isCorrect': isCorrect,
        'isAnswered': isAnswered,
        'status': isAnswered
            ? (isCorrect ? 'correct' : 'wrong')
            : 'missed',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }

    return answers;
  }

  Future<void> _submitAssessment() async {
    if (_isSubmitting) return;

    if (mounted) {
      setState(() {
        _isSubmitting = true;
      });
    }

    try {
      int totalCorrect = 0;
      int totalWrong = 0;
      int totalMissed = 0;

      // Create detailed answers array
      final answersArray = _createAnswersArray();

      // Calculate totals from answers array for consistency
      for (var answer in answersArray) {
        switch (answer['status']) {
          case 'correct':
            totalCorrect++;
            break;
          case 'wrong':
            totalWrong++;
            break;
          case 'missed':
            totalMissed++;
            break;
        }
      }

      final percentage = (totalCorrect / _questions.length) * 100;
      final score = totalCorrect * 10;

      String level;
      if (percentage >= 90) {
        level = 'Expert';
      } else if (percentage >= 75) {
        level = 'Advanced';
      } else if (percentage >= 50) {
        level = 'Intermediate';
      } else {
        level = 'Beginner';
      }

      final result = AssessmentResultF(
        userId: _authService.userId,
        assessmentId: widget.assessment.id,
        assessmentName: widget.assessment.title,
        totalCorrectAnswers: totalCorrect,
        totalMissedAnswers: totalMissed,
        totalWrongAnswers: totalWrong,
        level: level,
        percentage: percentage,
        score: score,
        timestamp: DateTime.now(),
        totalQuestions: _questions.length,
      );

      // Save assessment result with detailed answers
      await _firebaseService.saveAssessmentResultWithAnswers(result, answersArray);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(result: result),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit assessment: $e')),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_isSubmitting) return false;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave Assessment?'),
        content: Text(
          'Your progress will be lost and this will count as an incomplete assessment. Are you sure you want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Leave'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.assessment.title),
          centerTitle: true,
          actions: [
            CountdownTimer(secondsRemaining: _secondsRemaining),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _questions.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return QuestionWidget(
                    question: _questions[index],
                    onOptionSelected: (option) {
                      setState(() {
                        _questions[index].selectedOption = option;
                      });
                    },
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentIndex > 0)
                      ElevatedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        ),
                        child: Text('Previous'),
                      )
                    else
                      SizedBox(width: 100),
                    Text(
                      '${_currentIndex + 1}/${_questions.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_currentIndex < _questions.length - 1)
                      ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Text('Next'),
                      )
                    else
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitAssessment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: Text('Submit'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}