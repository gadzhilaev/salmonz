import 'package:flutter/material.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/data/models/models.dart';
import 'admin_user_details_page.dart';

class UsersListPage extends StatefulWidget {
  const UsersListPage({super.key});
  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  late Future<List<UserModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = AppServices.instance.admin.listUsers(limit: 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Пользователи')),
      body: FutureBuilder<List<UserModel>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snap.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (_, i) {
              final u = users[i];
              return ListTile(
                title: Text(u.name.isEmpty ? u.email : u.name),
                subtitle: Text('${u.email} · ${u.role}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminUserDetailsPage(user: u),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
