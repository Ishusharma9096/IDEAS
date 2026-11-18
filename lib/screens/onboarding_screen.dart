import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goabusconnect/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.directions_bus_rounded,
      'eyebrow': 'EXPLORE GOA',
      'title': 'Every bus.\nOne destination.',
      'description':
          'Discover bus routes and services across Goa, all in one place.',
      'color': const Color(0xFF087E8B),
    },
    {
      'icon': Icons.location_searching_rounded,
      'eyebrow': 'TRAVEL WITH CONFIDENCE',
      'title': 'Know before\nyou go.',
      'description': 'Check live GPS updates, verified reports and scheduled bus information.',
      'color': const Color(0xFF168A82),
    },
    {
      'icon': Icons.route_rounded,
      'eyebrow': 'SMARTER JOURNEYS',
      'title': 'Your journey,\nmade simpler.',
      'description': 'Plan routes, compare travel options and discover exciting local deals.',
      'color': const Color(0xFF086B78),
    },
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    context.go('/home');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 12, 25, 20),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.directions_bus_rounded,
                    color: AppTheme.primary,
                    size: 25,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'GoaBusConnect',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: size.width * 0.70,
                          height: size.width * 0.70,
                          constraints: const BoxConstraints(
                            maxWidth: 285,
                            maxHeight: 285,
                          ),
                          decoration: BoxDecoration(
                            color: (page['color'] as Color).withValues(
                              alpha: 0.09,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 175,
                              height: 175,
                              decoration: BoxDecoration(
                                color: page['color'] as Color,
                                borderRadius: BorderRadius.circular(45),
                                boxShadow: [
                                  BoxShadow(
                                    color: (page['color'] as Color).withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: Icon(
                                page['icon'] as IconData,
                                size: 85,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        Text(
                          page['eyebrow'] as String,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),

                        const SizedBox(height: 15),

                        Text(
                          page['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.navy,
                            fontSize: 34,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),

                        const SizedBox(height: 17),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            page['description'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 7,
                    width: _currentPage == index ? 27 : 7,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppTheme.primary
                          : const Color(0xFFD5E1E5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 57,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'ONE PLATFORM. ALL BUSES. BETTER JOURNEYS.',
                style: TextStyle(
                  color: Colors.blueGrey.shade300,
                  fontSize: 9,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
