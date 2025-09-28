import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import 'package:salmonz/nav_bar/main_screen.dart';

final supa = Supabase.instance.client;

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    this.topPadding = 40,
    this.imageWidth = 153,
    this.imageHeight = 118,
  });

  final double topPadding;
  final double imageWidth;
  final double imageHeight;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameCtr  = TextEditingController();
  final emailCtr = TextEditingController();
  final passCtr  = TextEditingController();
  final pass2Ctr = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    nameCtr.dispose();
    emailCtr.dispose();
    passCtr.dispose();
    pass2Ctr.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name  = nameCtr.text.trim();
    final email = emailCtr.text.trim();
    final pass  = passCtr.text;
    final pass2 = pass2Ctr.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty || pass2.isEmpty) {
      _showSnack('Заполни все поля'); return;
    }
    if (pass != pass2) { _showSnack('Пароли не совпадают'); return; }

    setState(() => isLoading = true);
    try {
      final res = await supa.auth.signUp(
        email: email,
        password: pass,
        data: {'name': name},
      );

      final user = res.user;
      if (user == null) {
        _showSnack('Не удалось создать пользователя');
        setState(() => isLoading = false);
        return;
      }

      await supa.from('user').insert({
        'id': user.id,
        'name': name,
        'email': email,
      });

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SuccessPage()),
            (route) => false,
      );
    } on AuthException catch (e) {
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
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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

                      const _FieldLabel('Имя'),
                      const SizedBox(height: 8),
                      _FilledInput(
                        controller: nameCtr,
                        hint: 'Иван',
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: 24),

                      const _FieldLabel('Электронная почта'),
                      const SizedBox(height: 8),
                      _FilledInput(
                        controller: emailCtr,
                        hint: 'email@example.com',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: 24),

                      const _FieldLabel('Пароль'),
                      const SizedBox(height: 8),
                      _PasswordInput(
                        controller: passCtr,
                        hint: 'Введите пароль',
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: 24),

                      const _FieldLabel('Повторите пароль'),
                      const SizedBox(height: 8),
                      _PasswordInput(
                        controller: pass2Ctr,
                        hint: 'Повторите пароль',
                        textInputAction: TextInputAction.done,
                      ),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _register,
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
                            'ЗАРЕГИСТРИРОВАТЬСЯ',
                            style: TextStyle(
                              fontFamily: 'Inter', fontSize: 12,
                              fontWeight: FontWeight.w600, height: 1.0,
                              letterSpacing: 0.48, color: Color(0xFFA83100),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                      Center(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const Login()),
                            );
                          },
                          child: const Text(
                            'У меня уже есть аккаунт',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              height: 1.7,
                              letterSpacing: 0.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Подпись над полем
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          text, // <-- используем параметр
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

/// Обычный инпут (как раньше)
class _FilledInput extends StatelessWidget {
  const _FilledInput({
    super.key,
    required this.hint,
    this.controller,
    this.keyboardType,
    this.textInputAction,
  });

  final String hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    const hintColor = Color(0xB2FFFFFF);

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        style: const TextStyle(
          fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500,
          height: 1.0, color: Colors.white,
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
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500,
            height: 1.0, color: hintColor,
          ),
        ),
      ),
    );
  }
}

/// Парольный инпут с кнопкой показать/скрыть
class _PasswordInput extends StatefulWidget {
  const _PasswordInput({
    super.key,
    required this.hint,
    required this.controller,
    this.textInputAction,
  });

  final String hint;
  final TextEditingController controller;
  final TextInputAction? textInputAction;

  @override
  State<_PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<_PasswordInput> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    const hintColor = Color(0xB2FFFFFF);

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: TextField(
        controller: widget.controller,
        obscureText: _obscure,
        obscuringCharacter: '•',
        textInputAction: widget.textInputAction,
        style: const TextStyle(
          fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500,
          height: 1.0, color: Colors.white,
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
          hintText: widget.hint,
          hintStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500,
            height: 1.0, color: hintColor,
          ),

          // кнопка на всю высоту поля
          suffixIconConstraints: const BoxConstraints.tightFor(
            width: 48, height: 48,
          ),
          suffixIcon: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => setState(() => _obscure = !_obscure),
              child: Center(
                child: Icon(
                  _obscure ? Icons.visibility : Icons.visibility_off, // 👈 вот тут разница
                  size: 20,
                  color: hintColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}