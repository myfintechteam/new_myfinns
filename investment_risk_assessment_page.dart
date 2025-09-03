import 'package:flutter/material.dart';

class InvestmentRiskAssessmentPage extends StatefulWidget {
  const InvestmentRiskAssessmentPage({super.key});

  @override
  State<InvestmentRiskAssessmentPage> createState() =>
      _InvestmentRiskAssessmentPageState();
}

class _InvestmentRiskAssessmentPageState
    extends State<InvestmentRiskAssessmentPage> {
  int _currentQuestionIndex = 0;
  List<int?> _selectedAnswers = List.filled(8, null);
  int _totalRiskScore = 0;
  String _riskProfile = '';
  String _investmentRecommendation = '';

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What is your age group?',
      'options': [
        {'text': '18-25 years', 'score': 5},
        {'text': '26-35 years', 'score': 4},
        {'text': '36-45 years', 'score': 3},
        {'text': '46-60 years', 'score': 2},
        {'text': '60+ years', 'score': 1},
      ],
    },
    {
      'question': 'What is your monthly income?',
      'options': [
        {'text': 'Less than ₹30,000', 'score': 1},
        {'text': '₹30,000 - ₹60,000', 'score': 2},
        {'text': '₹60,000 - ₹1,00,000', 'score': 3},
        {'text': '₹1,00,000 - ₹2,00,000', 'score': 4},
        {'text': 'More than ₹2,00,000', 'score': 5},
      ],
    },
    {
      'question': 'How experienced are you with investments?',
      'options': [
        {'text': 'Beginner', 'score': 1},
        {'text': 'Basic knowledge', 'score': 2},
        {'text': 'Intermediate', 'score': 3},
        {'text': 'Advanced', 'score': 4},
        {'text': 'Expert', 'score': 5},
      ],
    },
    {
      'question': 'What is your investment time horizon?',
      'options': [
        {'text': 'Less than 1 year', 'score': 1},
        {'text': '1-3 years', 'score': 2},
        {'text': '3-5 years', 'score': 3},
        {'text': '5-10 years', 'score': 4},
        {'text': 'More than 10 years', 'score': 5},
      ],
    },
    {
      'question': 'How would you react to a 20% drop in portfolio value?',
      'options': [
        {'text': 'Panic and sell immediately', 'score': 1},
        {'text': 'Be concerned but hold', 'score': 2},
        {'text': 'Accept as normal', 'score': 3},
        {'text': 'See buying opportunity', 'score': 4},
        {'text': 'Excited to invest more', 'score': 5},
      ],
    },
    {
      'question': 'Primary investment goal?',
      'options': [
        {'text': 'Capital preservation', 'score': 1},
        {'text': 'Regular income', 'score': 2},
        {'text': 'Balanced growth and income', 'score': 3},
        {'text': 'Long-term wealth creation', 'score': 4},
        {'text': 'Maximum returns (high risk)', 'score': 5},
      ],
    },
    {
      'question': 'Do you have an emergency fund?',
      'options': [
        {'text': 'No emergency fund', 'score': 1},
        {'text': '1-3 months of expenses', 'score': 2},
        {'text': '3-6 months of expenses', 'score': 3},
        {'text': '6-12 months of expenses', 'score': 4},
        {'text': 'More than 12 months', 'score': 5},
      ],
    },
    {
      'question': 'What is your current debt situation?',
      'options': [
        {'text': 'High debt (>50% income)', 'score': 1},
        {'text': 'Moderate debt (20-50% income)', 'score': 2},
        {'text': 'Low debt (<20% income)', 'score': 3},
        {'text': 'Minimal debt (only home loan)', 'score': 4},
        {'text': 'No debt', 'score': 5},
      ],
    },
  ];

  void _nextQuestion() {
    if (_selectedAnswers[_currentQuestionIndex] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an answer to proceed.')),
      );
      return;
    }
    setState(() {
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
      } else {
        _calculateRiskProfile();
      }
    });
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _calculateRiskProfile() {
    _totalRiskScore = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] != null) {
        _totalRiskScore +=
            _questions[i]['options'][_selectedAnswers[i]!]['score'] as int;
      }
    }

    if (_totalRiskScore <= 15) {
      _riskProfile = 'Conservative';
      _investmentRecommendation =
          'Focus on capital preservation with low-risk investments like Fixed Deposits, Bonds, and Debt Funds.';
    } else if (_totalRiskScore <= 25) {
      _riskProfile = 'Moderately Conservative';
      _investmentRecommendation =
          'Balanced approach with mix of debt and equity investments.';
    } else if (_totalRiskScore <= 35) {
      _riskProfile = 'Moderate';
      _investmentRecommendation =
          'Moderate growth focus with diversified mutual funds and equities.';
    } else if (_totalRiskScore <= 40) {
      _riskProfile = 'Moderately Aggressive';
      _investmentRecommendation =
          'Higher exposure to equity, including thematic and sectoral funds.';
    } else {
      _riskProfile = 'Aggressive';
      _investmentRecommendation =
          'Focus on high-growth, higher risk investments like small-cap stocks.';
    }
    setState(() {
      _currentQuestionIndex = _questions.length; // show result
    });
  }

  void _resetAssessment() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedAnswers = List.filled(_questions.length, null);
      _totalRiskScore = 0;
      _riskProfile = '';
      _investmentRecommendation = '';
    });
  }

  Widget _buildOption(
    int questionIndex,
    int optionIndex,
    Map<String, dynamic> option,
  ) {
    return RadioListTile<int>(
      title: Text(option['text'] as String),
      value: optionIndex,
      groupValue: _selectedAnswers[questionIndex],
      onChanged: (val) {
        setState(() {
          _selectedAnswers[questionIndex] = val;
        });
      },
      activeColor: Colors.blue,
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isMobile = width < 600;
    final isWideWeb = width > 900;
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final gradientColors = brightness == Brightness.light
        ? [
            const Color(0xFFB3EFCF),
            const Color(0xFF81DFFA),
            const Color(0xFF0294D1),
          ]
        : [
            const Color(0xFF181A2F),
            const Color(0xFF234248),
            const Color(0xFF693AD1),
          ];

    return Scaffold(
      backgroundColor: gradientColors[0],
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 32,
                vertical: isMobile ? 12 : 32,
              ),
              child: Center(
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxWidth: isWideWeb ? double.infinity : 600,
                  ),
                  child: _currentQuestionIndex < _questions.length
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Breadcrumb
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    'Dashboard',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const Text(
                                  'Investment Risk Assessment',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Progress info
                            Text(
                              'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value:
                                  (_currentQuestionIndex +
                                      (_selectedAnswers[_currentQuestionIndex] !=
                                              null
                                          ? 1
                                          : 0)) /
                                  _questions.length,
                              color: Colors.blueAccent,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              minHeight: 8,
                            ),
                            const SizedBox(height: 30),

                            // Question card
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 6,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _questions[_currentQuestionIndex]['question']
                                          as String,
                                      style: theme.textTheme.headlineMedium,
                                    ),
                                    const SizedBox(height: 20),
                                    ...(_questions[_currentQuestionIndex]['options']
                                            as List<Map<String, dynamic>>)
                                        .asMap()
                                        .entries
                                        .map(
                                          (e) => _buildOption(
                                            _currentQuestionIndex,
                                            e.key,
                                            e.value,
                                          ),
                                        )
                                        .toList(),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 26),

                            // Navigation buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                OutlinedButton(
                                  onPressed: _currentQuestionIndex > 0
                                      ? _previousQuestion
                                      : null,
                                  child: const Text('Previous'),
                                ),
                                ElevatedButton(
                                  onPressed: _nextQuestion,
                                  child: Text(
                                    _currentQuestionIndex ==
                                            _questions.length - 1
                                        ? 'Get Result'
                                        : 'Next',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Text(
                              '${_selectedAnswers.where((e) => e != null).length} of ${_questions.length} answered',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 8,
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.insights,
                                            size: 28,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          _riskProfile,
                                          style: theme.textTheme.headlineMedium
                                              ?.copyWith(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Recommended Strategy',
                                      style: theme.textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      _investmentRecommendation,
                                      style: theme.textTheme.bodyLarge,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 30),
                                    ElevatedButton(
                                      onPressed: _resetAssessment,
                                      child: const Text('Retake Assessment'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
