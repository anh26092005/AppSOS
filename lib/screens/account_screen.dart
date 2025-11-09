import 'package:flutter/material.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          Center(
            child: Stack(
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.person, size: 60, color: Colors.white),
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
          const Text(
            'User Name',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'user@example.com',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
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
            subtitle: const Text('John Doe'),
            trailing: const Icon(Icons.edit, size: 20),
            onTap: () {
              // TODO: Edit name
            },
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: const Text('user@example.com'),
            trailing: const Icon(Icons.edit, size: 20),
            onTap: () {
              // TODO: Edit email
            },
          ),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: const Text('Phone Number'),
            subtitle: const Text('+1 234 567 8900'),
            trailing: const Icon(Icons.edit, size: 20),
            onTap: () {
              // TODO: Edit phone
            },
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Emergency Contacts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.contacts),
            title: const Text('Manage Emergency Contacts'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Manage contacts
            },
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
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: const Text(
                    'Are you sure you want to delete your account? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Delete account
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

