import 'package:flutter/material.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/network/api_exception.dart';
import 'package:salmonz/core/responsive/app_breakpoints.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import 'package:salmonz/widgets/app_root.dart';
import 'login.dart';

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
  final nameCtr = TextEditingController();
  final emailCtr = TextEditingController();
  final passCtr = TextEditingController();
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
    final name = nameCtr.text.trim();
    final email = emailCtr.text.trim();
    final pass = passCtr.text;
    final pass2 = pass2Ctr.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty || pass2.isEmpty) {
      _showSnack('Заполни все поля');
      return;
    }
    if (pass != pass2) {
      _showSnack('Пароли не совпадают');
      return;
    }
    if (pass.length < 8) {
      _showSnack('Пароль должен быть не короче 8 символов');
      return;
    }

    setState(() => isLoading = true);
    try {
      await AppServices.instance.auth.register(
        email: email,
        password: pass,
        name: name,
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppRoot()),
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
    return Scaffold(
      backgroundColor: const Color(0xFFFF5E1C),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final controlH = AppBreakpoints.controlHeight(width);
            final scale = AppBreakpoints.typeScale(width);
            final logoW = widget.imageWidth * scale;
            final logoH = widget.imageHeight * scale;

            return Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: AppPageContainer.form(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: widget.topPadding),
                        Center(
                          child: Image.asset(
                            'assets/icon/logo_salmonz.png',
                            width: logoW,
                            height: logoH,
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
                          height: controlH,
                          scale: scale,
                        ),
                        const SizedBox(height: 24),
                        const _FieldLabel('Электронная почта'),
                        const SizedBox(height: 8),
                        _FilledInput(
                          controller: emailCtr,
                          hint: 'email@example.com',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          height: controlH,
                          scale: scale,
                        ),
                        const SizedBox(height: 24),
                        const _FieldLabel('Пароль'),
                        const SizedBox(height: 8),
                        _PasswordInput(
                          controller: passCtr,
                          hint: 'Введите пароль',
                          textInputAction: TextInputAction.next,
                          height: controlH,
                          scale: scale,
                        ),
                        const SizedBox(height: 24),
                        const _FieldLabel('Повторите пароль'),
                        const SizedBox(height: 8),
                        _PasswordInput(
                          controller: pass2Ctr,
                          hint: 'Повторите пароль',
                          textInputAction: TextInputAction.done,
                          height: controlH,
                          scale: scale,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: controlH,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40),
                              ),
                              fixedSize: Size.fromHeight(controlH),
                              padding: EdgeInsets.zero,
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator()
                                : Text(
                                    'ЗАРЕГИСТРИРОВАТЬСЯ',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12 * scale,
                                      fontWeight: FontWeight.w600,
                                      height: 1.0,
                                      letterSpacing: 0.48,
                                      color: const Color(0xFFA83100),
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
                                MaterialPageRoute(
                                  builder: (_) => const Login(),
                                ),
                              );
                            },
                            child: Text(
                              'У меня уже есть аккаунт',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                                fontSize: 14 * scale,
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

class _FilledInput extends StatelessWidget {
  const _FilledInput({
    required this.hint,
    required this.height,
    required this.scale,
    this.controller,
    this.keyboardType,
    this.textInputAction,
  });

  final String hint;
  final double height;
  final double scale;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    const hintColor = Color(0xB2FFFFFF);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14 * scale,
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
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14 * scale,
            fontWeight: FontWeight.w500,
            height: 1.0,
            color: hintColor,
          ),
        ),
      ),
    );
  }
}

class _PasswordInput extends StatefulWidget {
  const _PasswordInput({
    required this.hint,
    required this.controller,
    required this.height,
    required this.scale,
    this.textInputAction,
  });

  final String hint;
  final TextEditingController controller;
  final double height;
  final double scale;
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
      height: widget.height,
      width: double.infinity,
      child: TextField(
        controller: widget.controller,
        obscureText: _obscure,
        obscuringCharacter: '•',
        textInputAction: widget.textInputAction,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14 * widget.scale,
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
          hintText: widget.hint,
          hintStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14 * widget.scale,
            fontWeight: FontWeight.w500,
            height: 1.0,
            color: hintColor,
          ),
          suffixIconConstraints: BoxConstraints.tightFor(
            width: widget.height,
            height: widget.height,
          ),
          suffixIcon: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => setState(() => _obscure = !_obscure),
              child: Center(
                child: Icon(
                  _obscure ? Icons.visibility : Icons.visibility_off,
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
