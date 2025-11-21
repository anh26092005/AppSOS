import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final cached = await ApiService.getCachedUser();
    if (mounted && cached != null) {
      setState(() {
        _user = cached;
      });
    }
    await _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = await ApiService.fetchProfile();
      if (!mounted) return;
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _stringValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  String _displayName() {
    final fullName = _stringValue(_user?['fullName']).trim();
    if (fullName.isNotEmpty) return fullName;

    final name = _stringValue(_user?['name']).trim();
    if (name.isNotEmpty) return name;

    final email = _stringValue(_user?['email']).trim();
    if (email.isNotEmpty) return email;

    final phone = _stringValue(_user?['phone']).trim();
    if (phone.isNotEmpty) return phone;

    return 'User';
  }

  String _displayInitial() {
    final name = _displayName();
    if (name.isEmpty) return '?';
    return name.substring(0, 1).toUpperCase();
  }

  Widget _buildLoading() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 200),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
        const SizedBox(height: 16),
        const Text(
          'Khong the tai thong tin tai khoan',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_error != null)
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton(
            onPressed: _refreshProfile,
            child: const Text('Thu lai'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: _isLoading && _user == null
            ? _buildLoading()
            : (_error != null && _user == null ? _buildError() : _buildContent()),
      ),
    );
  }

  Widget _buildContent() {
    final name = _displayName();
    final email = _stringValue(_user?['email']).trim();
    final phone = _stringValue(_user?['phone']).trim();
    final role = _stringValue(_user?['role']).trim();
    final userId = _stringValue(_user?['_id'] ?? _user?['id']).trim();

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 16),
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.blueAccent,
                child: Text(
                  _displayInitial(),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          email.isNotEmpty ? email : 'Email chua cap nhat',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
        if (phone.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            phone,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Personal Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Full Name'),
          subtitle: Text(name),
          trailing: const Icon(Icons.edit, size: 20),
          onTap: () {
            // TODO: Edit name
          },
        ),
        ListTile(
          leading: const Icon(Icons.email_outlined),
          title: const Text('Email'),
          subtitle: Text(email.isNotEmpty ? email : 'Email chua cap nhat'),
          trailing: const Icon(Icons.edit, size: 20),
          onTap: () {
            // TODO: Edit email
          },
        ),
        ListTile(
          leading: const Icon(Icons.phone_outlined),
          title: const Text('Phone Number'),
          subtitle: Text(phone.isNotEmpty ? phone : 'Phone chua cap nhat'),
          trailing: const Icon(Icons.edit, size: 20),
          onTap: () {
            // TODO: Edit phone
          },
        ),
        if (role.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('Role'),
            subtitle: Text(role),
          ),
        if (userId.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('User ID'),
            subtitle: Text(userId),
          ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Security',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Change Password'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // TODO: Change password
          },
        ),
        ListTile(
          leading: const Icon(Icons.security),
          title: const Text('Two-Factor Authentication'),
          trailing: Switch(
            value: false,
            onChanged: (value) {
              // TODO: Toggle 2FA
            },
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            'Khong the cap nhat moi: $_error',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ],
        if (_isLoading) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('Dang dong bo thong tin...'),
            ],
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}
