import 'package:flutter/material.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/network/api_exception.dart';
import 'package:salmonz/nav_bar/main_screen.dart';
import 'register.dart';

class Login extends StatefulWidget {
  const Login({
    super.key,
    this.topPadding = 40,
    this.imageWidth = 153,
    this.imageHeight = 118,
  });

  final double topPadding;
  final double imageWidth;
  final double imageHeight;

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final emailCtr = TextEditingController();
  final passCtr = TextEditingController();
  bool isLoading = false;
  bool _obscurePass = true;

  @override
  void dispose() {
    emailCtr.dispose();
    passCtr.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = emailCtr.text.trim();
    final pass = passCtr.text;

    if (email.isEmpty || pass.isEmpty) {
      _showSnack('Введите почту и пароль');
      return;
    }

    setState(() => isLoading = true);
    try {
      await AppServices.instance.auth.login(email: email, password: pass);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SuccessPage()),
        (route) => false,
      );
    } on ApiException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('Ошибка: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    const hintColor = Color(0xB2FFFFFF);
    return Scaffold(
      backgroundColor: const Color(0xFFFF5E1C),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
              SizedBox(height: widget.topPadding),
              Center(
                child: Image.asset(
                  'assets/icon/logo_salmonz.png',
                  width: widget.imageWidth,
                  height: widget.imageHeight,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 48),
              const _FieldLabel('Электронная почта'),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: TextField(
                  controller: emailCtr,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                    color: Colors.white,
                  ),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.fromLTRB(20, 17, 20, 17),
                    filled: true,
                    fillColor: const Color(0x29FFFFFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'email@example.com',
                    hintStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                      color: Color(0xB2FFFFFF),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 24),
              const _FieldLabel('Пароль'),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: TextField(
                  controller: passCtr,
                  obscureText: _obscurePass,
                  obscuringCharacter: '•',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                    color: Colors.white,
                  ),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.fromLTRB(20, 17, 20, 17),
                    filled: true,
                    fillColor: const Color(0x29FFFFFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Введите пароль',
                    hintStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                      color: hintColor,
                    ),
                    suffixIconConstraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    suffixIcon: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () =>
                            setState(() => _obscurePass = !_obscurePass),
                        child: Center(
                          child: Icon(
                            _obscurePass
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                            color: hintColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    fixedSize: const Size.fromHeight(56),
                    padding: EdgeInsets.zero,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'ВОЙТИ В АККАУНТ',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            height: 1.0,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.48,
                            color: Color(0xFFA83100),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RegisterPage()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    fixedSize: const Size.fromHeight(56),
                    padding: EdgeInsets.zero,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'РЕГИСТРАЦИЯ',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                      letterSpacing: 0.48,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.0,
            color: Color(0xB2FFFFFF),
          ),
        ),
      ),
    );
  }
}
