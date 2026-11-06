import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salmonz/core/network/api_exception.dart';
import 'package:salmonz/core/responsive/app_breakpoints.dart';
import 'package:salmonz/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salmonz/widgets/app_notice.dart';
import 'package:salmonz/widgets/app_root.dart';
import 'register_page.dart';

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
  String? _formError;
  bool _formErrorIsNetwork = false;

  @override
  void initState() {
    super.initState();
    // Stale toasts from a previous session must not stick on the login screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppNotice.clear(context);
    });
  }

  @override
  void dispose() {
    emailCtr.dispose();
    passCtr.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (isLoading) return;
    final email = emailCtr.text.trim();
    final pass = passCtr.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() {
        _formError = 'Введите почту и пароль';
        _formErrorIsNetwork = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      _formError = null;
      _formErrorIsNetwork = false;
    });
    AppNotice.clear(context);

    try {
      final cubit = context.read<AuthCubit>();
      await cubit.login(email: email, password: pass);
      final state = cubit.state;
      if (!mounted) return;
      if (state is AuthFailure) {
        setState(() {
          _formError = state.message;
          _formErrorIsNetwork =
              state.message == ApiException.connectionMessage ||
              state.message == ApiException.timeoutMessage;
        });
        return;
      }
      if (state is! AuthAuthenticated) {
        setState(() {
          _formError = 'Не удалось войти';
          _formErrorIsNetwork = false;
        });
        return;
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppRoot()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _formError = e.userMessage;
        _formErrorIsNetwork = e.isNetwork;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _formError = ApiException.userMessageFrom(e);
        _formErrorIsNetwork = false;
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const hintColor = Color(0xB2FFFFFF);
    return Scaffold(
      backgroundColor: const Color(0xFFE8683A),
      // Keep viewInsets so we can detect the keyboard and pad the form.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final controlH = AppBreakpoints.controlHeight(width);
            final scale = AppBreakpoints.typeScale(width);
            final logoW = widget.imageWidth * scale;
            final logoH = widget.imageHeight * scale;
            final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
            final keyboardOpen = bottomInset > 0;
            final visibleHeight = constraints.maxHeight - bottomInset;

            // translucent: first tap reaches TextField; empty-area tap unfocuses.
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: SingleChildScrollView(
                // Scroll only while the keyboard covers part of the screen.
                physics: keyboardOpen
                    ? const ClampingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.manual,
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: visibleHeight),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppBreakpoints.pagePadding(width),
                          vertical: 24,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppBreakpoints.formMaxWidth,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/icon/logo_salmonz.png',
                                width: logoW,
                                height: logoH,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 48),
                              const _FieldLabel('Электронная почта'),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: controlH,
                                width: double.infinity,
                                child: Semantics(
                                  identifier: 'loginEmail',
                                  textField: true,
                                  child: TextField(
                                    key: const Key('loginEmail'),
                                    controller: emailCtr,
                                    onChanged: (_) {
                                      if (_formError != null) {
                                        setState(() => _formError = null);
                                      }
                                    },
                                    onTapOutside: (_) => FocusManager
                                        .instance
                                        .primaryFocus
                                        ?.unfocus(),
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14 * scale,
                                      fontWeight: FontWeight.w500,
                                      height: 1.0,
                                      color: Colors.white,
                                    ),
                                    cursorColor: Colors.white,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.fromLTRB(
                                        20,
                                        17,
                                        20,
                                        17,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0x29FFFFFF),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                        borderSide: BorderSide.none,
                                      ),
                                      hintText: 'email@example.com',
                                      hintStyle: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14 * scale,
                                        fontWeight: FontWeight.w500,
                                        height: 1.0,
                                        color: hintColor,
                                      ),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const _FieldLabel('Пароль'),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: controlH,
                                width: double.infinity,
                                child: Semantics(
                                  identifier: 'loginPassword',
                                  textField: true,
                                  child: TextField(
                                    key: const Key('loginPassword'),
                                    controller: passCtr,
                                    obscureText: _obscurePass,
                                    obscuringCharacter: '•',
                                    onChanged: (_) {
                                      if (_formError != null) {
                                        setState(() => _formError = null);
                                      }
                                    },
                                    onTapOutside: (_) => FocusManager
                                        .instance
                                        .primaryFocus
                                        ?.unfocus(),
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14 * scale,
                                      fontWeight: FontWeight.w500,
                                      height: 1.0,
                                      color: Colors.white,
                                    ),
                                    cursorColor: Colors.white,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.fromLTRB(
                                        20,
                                        17,
                                        20,
                                        17,
                                      ),
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
                                      suffixIconConstraints:
                                          BoxConstraints.tightFor(
                                            width: controlH,
                                            height: controlH,
                                          ),
                                      suffixIcon: Material(
                                        type: MaterialType.transparency,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          onTap: () => setState(
                                            () => _obscurePass = !_obscurePass,
                                          ),
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
                              ),
                              if (_formError != null) ...[
                                const SizedBox(height: 16),
                                _LoginFormError(
                                  message: _formError!,
                                  showRetry: _formErrorIsNetwork,
                                  onRetry: _formErrorIsNetwork ? _login : null,
                                ),
                              ],
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: controlH,
                                child: Semantics(
                                  identifier: 'loginSubmit',
                                  button: true,
                                  child: ElevatedButton(
                                    key: const Key('loginSubmit'),
                                    onPressed: isLoading ? null : _login,
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
                                            'ВОЙТИ В АККАУНТ',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12 * scale,
                                              height: 1.0,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.48,
                                              color: const Color(0xFFA83100),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: controlH,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const RegisterPage(),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                    fixedSize: Size.fromHeight(controlH),
                                    padding: EdgeInsets.zero,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(
                                    'РЕГИСТРАЦИЯ',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12 * scale,
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
                      ),
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

class _LoginFormError extends StatelessWidget {
  const _LoginFormError({
    required this.message,
    required this.showRetry,
    this.onRetry,
  });

  final String message;
  final bool showRetry;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x33FFFFFF),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                key: const Key('loginFormError'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                  color: Colors.white,
                ),
              ),
            ),
            if (showRetry && onRetry != null)
              TextButton(
                key: const Key('loginRetry'),
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Повторить',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
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
