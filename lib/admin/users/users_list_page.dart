import 'package:flutter/material.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/network/api_exception.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import 'package:salmonz/data/models/models.dart';
import 'package:salmonz/widgets/app_error_view.dart';
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

  Future<void> _reload() async {
    setState(() {
      _future = AppServices.instance.admin.listUsers(limit: 100);
    });
    try {
      await _future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Пользователи')),
      body: AppPageContainer(
        child: FutureBuilder<List<UserModel>>(
          future: _future,
          builder: (context, snap) {
            if (snap.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.5,
                    child: AppErrorView(
                      message: ApiException.userMessageFrom(snap.error!),
                      onRetry: _reload,
                    ),
                  ),
                ],
              );
            }
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
      ),
    );
  }
}
