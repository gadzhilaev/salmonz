import 'package:flutter/material.dart';
import 'package:salmonz/data/models/models.dart';

class AdminUserDetailsPage extends StatelessWidget {
  const AdminUserDetailsPage({super.key, required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Пользователь')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            user.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(user.email),
          Text('Роль: ${user.role}'),
          if ((user.phone ?? '').isNotEmpty) Text('Телефон: ${user.phone}'),
          if ((user.avatarUrl ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Image.network(user.avatarUrl!, height: 120),
            ),
        ],
      ),
    );
  }
}
