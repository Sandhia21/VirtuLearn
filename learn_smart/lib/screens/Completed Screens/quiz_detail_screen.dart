import 'dart:async';
import 'package:flutter/material.dart';
import 'package:learn_smart/models/quiz.dart';

class QuizDetailScreen extends StatefulWidget {
  final Quiz quiz; // The quiz object passed from the previous screen
  final int moduleId; // The moduleId of the quiz
  final bool isStudentEnrolled;

  QuizDetailScreen({
    required this.quiz,
    required this.moduleId,
    required this.isStudentEnrolled,
  });

  @override
  _QuizDetailScreenState createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  int _currentQuestionIndex = 0;
  Map<int, String> _selectedAnswers = {};
  Timer? _timer;
  int _remainingTime = 0;
  bool _isQuizCompleted = false;
  bool _hasQuizStarted = false;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.quiz.quizDuration * 60; // Duration in seconds
  }

  void _startQuiz() {
    _hasQuizStarted = true;
    _startTimer();
    setState(() {});
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(minutes: 15), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _completeQuiz();
        }
      });
    });
  }

  void _completeQuiz() {
    _timer?.cancel();
    setState(() {
      _isQuizCompleted = true;
    });
  }

  void _onAnswerSelected(String option) {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = option;
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        actions: widget.isStudentEnrolled
            ? [
                if (!_hasQuizStarted)
                  IconButton(
                    icon: Icon(Icons.play_arrow),
                    onPressed: _startQuiz,
                  )
              ]
            : null,
      ),
      body: _hasQuizStarted
          ? _isQuizCompleted
              ? _buildResultScreen()
              : _buildQuizScreen()
          : _buildQuizDetails(),
    );
  }

  Widget _buildQuizDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.quiz.title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(widget.quiz.description),
          SizedBox(height: 16),
          Text("Quiz Type: ${widget.quiz.quizType}"),
          SizedBox(height: 16),
          Text("Duration: ${widget.quiz.quizDuration} minutes"),
          SizedBox(height: 16),
          if (widget.isStudentEnrolled)
            ElevatedButton(
              onPressed: _startQuiz,
              child: Text("Start Quiz"),
            ),
          if (!widget.isStudentEnrolled)
            Text(
              "You must be enrolled in this course to attempt the quiz.",
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }

  Widget _buildQuizScreen() {
    final currentQuestion = widget.quiz.questions[_currentQuestionIndex];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
            backgroundColor: Colors.teal[100],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
          ),
          SizedBox(height: 20),
          Text(
            "Time Remaining: ${_formatTime(_remainingTime)}",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 30),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                currentQuestion.questionText,
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(height: 20),
          _buildOptions(currentQuestion),
          Spacer(),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildOptions(Question question) {
    return Column(
      children: [
        _buildAnswerOption('a', question.optionA),
        _buildAnswerOption('b', question.optionB),
        _buildAnswerOption('c', question.optionC),
        _buildAnswerOption('d', question.optionD),
      ],
    );
  }

  Widget _buildAnswerOption(String optionLetter, String? optionText) {
    final isSelected = _selectedAnswers[_currentQuestionIndex] == optionLetter;

    return Card(
      elevation: 4,
      color: isSelected ? Colors.teal[100] : Colors.white,
      child: ListTile(
        title: Text(optionText ?? 'No Option'),
        onTap: () => _onAnswerSelected(optionLetter),
      ),
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        minimumSize: Size(double.infinity, 50),
      ),
      child: Text(
        _currentQuestionIndex == widget.quiz.questions.length - 1
            ? 'Submit Quiz'
            : 'Next',
        style: TextStyle(color: Colors.white),
      ),
      onPressed: () {
        setState(() {
          if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
            _currentQuestionIndex++;
          } else {
            _completeQuiz();
          }
        });
      },
    );
  }

  Widget _buildResultScreen() {
    int correctAnswers = 0;

    widget.quiz.questions.asMap().forEach((index, question) {
      if (_selectedAnswers[index] == _getCorrectAnswer(question)) {
        correctAnswers++;
      }
    });

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Quiz Completed!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              "You answered $correctAnswers out of ${widget.quiz.questions.length} correctly!",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Back to Module"),
            ),
          ],
        ),
      ),
    );
  }

  String _getCorrectAnswer(Question question) {
    return question.correctAnswer!;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
