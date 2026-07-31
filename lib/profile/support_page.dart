import 'package:flutter/material.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/network/api_exception.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  static const arrowColor = Color(0xFFCDCDCD);
  static const titleColor = Color(0xFF26351E);
  static const labelColor = Color(0xB2464646);
  static const orange = Color(0xFFFF5E1C);
  static const double hLogo = 62;

  final _controller = TextEditingController();
  bool _sending = false;
  String _name = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    try {
      final u = await AppServices.instance.profile.getMe();
      if (!mounted) return;
      setState(() {
        _name = u.name;
        _email = u.email;
      });
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Напишите сообщение')));
      return;
    }
    if (_sending) return;

    setState(() => _sending = true);
    try {
      await AppServices.instance.support.create(message: text);
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SuccessDialog(
          onOk: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.userMessage)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiException.userMessageFrom(e))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: AppPageContainer.form(
          child: Column(
            children: [
              SizedBox(
                height: hLogo + 26,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      left: 20,
                      top: 26,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 20,
                          color: arrowColor,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      child: Image.asset(
                        'assets/icon/logo_salmonz_small.png',
                        width: 80,
                        height: 62,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ПОДДЕРЖКА',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: titleColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_name.isNotEmpty || _email.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$_name · $_email',
                    style: const TextStyle(color: labelColor, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  key: const Key('supportMessageField'),
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: 'Ваше сообщение',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: orange),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: orange),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  key: const Key('supportSendButton'),
                  onPressed: _sending ? null : _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  child: _sending
                      ? const CircularProgressIndicator(
                          key: Key('supportSendingIndicator'),
                          color: Colors.white,
                        )
                      : const Text(
                          'ОТПРАВИТЬ',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            letterSpacing: 0.48,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({required this.onOk});
  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Внимание!'),
      content: const Text('Сообщение отправлено в поддержку'),
      actions: [TextButton(onPressed: onOk, child: const Text('ОК'))],
    );
  }
}
