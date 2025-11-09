import 'package:flutter/material.dart';

class TnvScreen extends StatefulWidget {
  const TnvScreen({super.key});

  @override
  State<TnvScreen> createState() => _TnvScreenState();
}

class _TnvScreenState extends State<TnvScreen> {
  final List<Map<String, dynamic>> _tnvList = [
    {
      'id': 1,
      'name': 'Nguyễn Thị D',
      'avatar': '',
      'rating': 4.8,
      'reviews': 125,
      'specialties': ['Y tế', 'Cứu hộ'],
      'distance': '0.5 km',
      'status': 'online',
      'completedCases': 45,
    },
    {
      'id': 2,
      'name': 'Trần Văn E',
      'avatar': '',
      'rating': 4.9,
      'reviews': 203,
      'specialties': ['An toàn', 'Hỗ trợ'],
      'distance': '1.2 km',
      'status': 'online',
      'completedCases': 67,
    },
    {
      'id': 3,
      'name': 'Lê Thị F',
      'avatar': '',
      'rating': 4.7,
      'reviews': 89,
      'specialties': ['Y tế', 'Tư vấn'],
      'distance': '2.1 km',
      'status': 'offline',
      'completedCases': 32,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Tình Nguyện Viên'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header stats
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Tổng TNV',
                      '${_tnvList.length}',
                      Icons.people,
                    ),
                    _buildStatItem(
                      'Đang online',
                      '${_tnvList.where((tnv) => tnv['status'] == 'online').length}',
                      Icons.check_circle,
                    ),
                    _buildStatItem(
                      'Sẵn sàng',
                      '${_tnvList.where((tnv) => tnv['status'] == 'online').length}',
                      Icons.flash_on,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Filter tabs
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildFilterTab('Tất cả', true),
                  const SizedBox(width: 8),
                  _buildFilterTab('Y tế', false),
                  const SizedBox(width: 8),
                  _buildFilterTab('Cứu hộ', false),
                  const SizedBox(width: 8),
                  _buildFilterTab('An toàn', false),
                  const SizedBox(width: 8),
                  _buildFilterTab('Tư vấn', false),
                ],
              ),
            ),
          ),
          // TNV List
          Expanded(
            child: _tnvList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tnvList.length,
                    itemBuilder: (context, index) {
                      final tnv = _tnvList[index];
                      return _buildTnvCard(tnv);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTab(String label, bool isSelected) {
    return InkWell(
      onTap: () {
        // TODO: Filter by category
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.redAccent : Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.redAccent : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTnvCard(Map<String, dynamic> tnv) {
    final isOnline = tnv['status'] == 'online';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/info-tnv',
            arguments: tnv,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.red.shade400,
                          Colors.red.shade700,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tnv['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isOnline ? Colors.green : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${tnv['rating']}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${tnv['reviews']} đánh giá)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: (tnv['specialties'] as List)
                          .map<Widget>((specialty) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  specialty,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Cách ${tnv['distance']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${tnv['completedCases']} ca',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Không có tình nguyện viên',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

