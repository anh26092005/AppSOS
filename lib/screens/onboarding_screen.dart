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
      'title': 'Kết nối nhanh chóng trong mọi tình huống khẩn cấp',
      'description':
          'Ứng dụng SOS giúp bạn kết nối với tình nguyện viên xung quanh chỉ trong vài giây khi cần hỗ trợ khẩn cấp.',
    },
    {
      'image': 'assets/images/on2.png',
      'title': 'Đội ngũ tình nguyện viên tận tâm',
      'description':
          'Tình nguyện viên có nhiều chuyên môn ở nhiều lĩnh vực khác nhau, sẵn sàng hỗ trợ bạn mọi lúc mọi nơi trong thành phố.',
    },
    {
      'image': 'assets/images/on3.png',
      'title': 'An toàn và tin cậy',
      'description':
          'Hệ thống theo dõi vị trí thời gian thực, lịch sử hỗ trợ đầy đủ, đảm bảo an toàn tối đa cho người dùng.',
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
                              ? const Color(0xFF1976D2) // Blue color
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
                            ? const Color(0xFF1976D2)
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
                                  : const Color(0xFF1976D2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: _currentPage == _onboardingData.length - 1
                                ? Colors.white
                                : const Color(0xFF1976D2),
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
