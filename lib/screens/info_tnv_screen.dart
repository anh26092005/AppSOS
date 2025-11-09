import 'package:flutter/material.dart';

class InfoTnvScreen extends StatelessWidget {
  final Map<String, dynamic>? tnvData;

  const InfoTnvScreen({super.key, this.tnvData});

  @override
  Widget build(BuildContext context) {
    // Default data if not provided
    final tnv = tnvData ?? {
      'id': 1,
      'name': 'Nguyễn Thị D',
      'avatar': '',
      'rating': 4.8,
      'reviews': 125,
      'specialties': ['Y tế', 'Cứu hộ'],
      'distance': '0.5 km',
      'status': 'online',
      'completedCases': 45,
      'phone': '0123456789',
      'email': 'tnv@example.com',
      'experience': '5 năm',
      'description':
          'Tình nguyện viên có nhiều kinh nghiệm trong lĩnh vực y tế và cứu hộ. Sẵn sàng hỗ trợ 24/7.',
      'certifications': [
        'Chứng chỉ Y tế',
        'Chứng chỉ Cứu hộ',
        'Chứng chỉ Sơ cấp cứu',
      ],
    };

    final isOnline = tnv['status'] == 'online';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            floating: false,
            pinned: true,
            backgroundColor: Colors.redAccent,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                tnv['name'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.red.shade400,
                      Colors.red.shade700,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 70,
                                  color: Colors.redAccent,
                                ),
                              ),
                              if (isOnline)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star,
                                size: 20,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${tnv['rating']}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${tnv['reviews']} đánh giá)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          'Ca hoàn thành',
                          '${tnv['completedCases']}',
                          Icons.check_circle_outline,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade300,
                        ),
                        _buildStatColumn(
                          'Kinh nghiệm',
                          tnv['experience'],
                          Icons.timelapse,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade300,
                        ),
                        _buildStatColumn(
                          'Khoảng cách',
                          tnv['distance'],
                          Icons.location_on,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Specialties
                  const Text(
                    'Chuyên môn',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (tnv['specialties'] as List)
                        .map<Widget>((specialty) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.redAccent,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                specialty,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  // Description
                  const Text(
                    'Giới thiệu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      tnv['description'] ?? 'Không có mô tả',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Certifications
                  const Text(
                    'Chứng chỉ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(tnv['certifications'] as List? ?? []).map((cert) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.verified,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                cert,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 24),
                  // Contact Info
                  const Text(
                    'Thông tin liên hệ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildContactRow(
                          Icons.phone,
                          'Số điện thoại',
                          tnv['phone'] ?? 'N/A',
                          onTap: () {
                            // TODO: Make phone call
                          },
                        ),
                        const Divider(height: 24),
                        _buildContactRow(
                          Icons.email,
                          'Email',
                          tnv['email'] ?? 'N/A',
                          onTap: () {
                            // TODO: Send email
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Action Buttons
                  if (isOnline)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Contact TNV
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã gửi yêu cầu đến ${tnv['name']}'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Liên Hệ Ngay',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (!isOnline)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO: Send message
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Gửi Tin Nhắn',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.redAccent, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.redAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
        ],
      ),
    );
  }
}

