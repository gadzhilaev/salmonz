import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supa = Supabase.instance.client;

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  static const bg = Color(0xFFFFFFFF);
  static const arrowColor = Color(0xFFCDCDCD);
  static const titleColor = Color(0xFF26351E);
  static const labelColor = Color(0xB2464646); // #464646B2
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
    final u = supa.auth.currentUser;
    if (u == null) return;
    final row = await supa.from('user')
        .select('name,email')
        .eq('id', u.id)
        .maybeSingle();
    setState(() {
      _name  = (row?['name']  as String?) ?? '';
      _email = (row?['email'] as String?) ?? (u.email ?? '');
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Напишите сообщение')),
      );
      return;
    }
    if (_sending) return;

    setState(() => _sending = true);
    try {
      final uid = supa.auth.currentUser?.id;
      if (uid == null) throw 'Не авторизован';

      // сохраняем в БД
      await supa.from('support_messages').insert({
        'user_id': uid,
        'name': _name,
        'email': _email,
        'message': text,
        'status': 'new',
      });

      // показываем модалку "Внимание!"
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SuccessDialog(onOk: () {
          Navigator.of(context).pop(); // закрыть диалог
          Navigator.of(context).pop(); // вернуться в профиль
        }),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка БД: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          // общий отступ экрана как в products.dart
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- APP BAR 1в1 как в products.dart ---
              SizedBox(
                height: hLogo + 26,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      left: 20,
                      top: 26,
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          splashRadius: 20,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new,
                              size: 20, color: arrowColor),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      child: Image.asset(
                        'assets/icon/logo_salmonz_small.png',
                        width: 80, height: 62, fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 24),

                    // Заголовок страницы (24 Black, 4% tracking)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'НАПИСАТЬ В ПОДДЕРЖКУ',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          height: 1.0,
                          letterSpacing: 0.8, // 4% от 24
                          color: titleColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // “Колонка” с боковыми отступами 16
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Лейбл с дополнительным +8 слева (итого 24)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Text(
                              'Введите ваше сообщение',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                height: 1.0,
                                letterSpacing: 0,
                                color: labelColor,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Текстовое поле 361x320 (по ширине — заполняем; по высоте — 320)
                          SizedBox(
                            height: 320,
                            child: TextField(
                              controller: _controller,
                              expands: true,
                              maxLines: null,
                              minLines: null,
                              textAlignVertical: TextAlignVertical.top,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                height: 1.0,
                                letterSpacing: 0,
                                color: Colors.black,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Ваше сообщение',
                                hintStyle: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  height: 1.0,
                                  letterSpacing: 0,
                                  color: Color(0xFF9D9D9D),
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(color: orange, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(color: orange, width: 1.5),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),

                    // Кнопка с внешними отступами по 12 (а не 16)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _sending ? null : _send,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'ОТПРАВИТЬ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              height: 1.0,
                              letterSpacing: 0.48, // 4% от 12
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
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
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,                 // #FFFFFF
      surfaceTintColor: Colors.transparent,          // отключаем розовый тинт
      elevation: 0,                                  // (опционально) без теневого наложения
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 280, maxWidth: 280,
          minHeight: 172, maxHeight: 172,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Внимание!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  height: 22/18,
                  letterSpacing: -0.41,
                  color: Color(0xFF282828),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ваше сообщение отправлено, ответ придет в виде письма на вашу электронную почту',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF9D9D9D),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 116,
                height: 32,
                child: ElevatedButton(
                  onPressed: onOk,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF5E1C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  child: const Text(
                    'ОК',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      height: 1.0,
                      letterSpacing: 0.4, // 4% от 10
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}