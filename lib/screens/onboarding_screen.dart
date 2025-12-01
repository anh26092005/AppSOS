import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'image': 'assets/images/on1.png',
      'title': 'Trường Đại học Giao thông vận tải TP. Hồ Chí Minh',
      'description':
          'Đào tạo nguồn nhân lực cho lĩnh vực giao thông vận tải như hàng hải, hàng không, đường bộ, đường thuỷ nội địa, đường sắt.',
    },
    {
      'image': 'assets/images/on2.png',
      'title': 'Trường Đại học Giao thông vận tải TP. Hồ Chí Minh',
      'description':
          'Trực thuộc Bộ Xây dựng là trường đại học đa ngành thuộc lĩnh vực giao thông vận tải lớn nhất phía Nam Việt Nam',
    },
    {
      'image': 'assets/images/on3.png',
      'title': 'Một ứng dụng duy nhất cho sinh viên và giảng viên',
      'description':
          'UTH là ứng dụng giáo dục cung cấp thông tin kịp thời, mọi lúc mọi nơi, giúp tăng cường tương tác giữa sinh viên, giảng viên, phụ huynh và nhà trường.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) => _buildPage(
                  image: _onboardingData[index]['image']!,
                  title: _onboardingData[index]['title']!,
                  description: _onboardingData[index]['description']!,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot Indicator
                  Row(
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF00563B) // UTH Green
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Next/Start Button
                  GestureDetector(
                    onTap: () async {
                      if (_currentPage == _onboardingData.length - 1) {
                        await _finishOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _currentPage == _onboardingData.length - 1
                            ? const Color(0xFF00563B)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _currentPage == _onboardingData.length - 1
                                ? 'Trang chủ'
                                : 'Tiếp tục',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _currentPage == _onboardingData.length - 1
                                  ? Colors.white
                                  : const Color(0xFF00563B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: _currentPage == _onboardingData.length - 1
                                ? Colors.white
                                : const Color(0xFF00563B),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String image,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              image,
              height: MediaQuery.of(context).size.height * 0.5,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            title,
            textAlign: TextAlign.left,
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3436),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            description,
            textAlign: TextAlign.left,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              color: const Color(0xFF636E72),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finishOnboarding() async {
    await ApiService.setSeenOnboarding();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }
}
