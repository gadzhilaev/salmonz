import '../utils/ru_phone_formatter.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

final supa = Supabase.instance.client;

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // цвета/константы как у тебя
  static const bg = Color(0xFFFFFFFF);
  static const arrowColor = Color(0xFFCDCDCD);
  static const titleColor = Color(0xFF26351E);
  static const labelColor = Color(0xB2464646); // #464646B2
  static const orange = Color(0xFFFF5E1C);
  static const secondary = Color(0xFF282828);
  static const double hLogo = 62;
  static const double ls24 = 0.96; // 4% от 24

  final _picker = ImagePicker();

  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _phoneMask = RuPhoneTextInputFormatter(); // простое форматирование

  String _img = '';
  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    try {
      final u = supa.auth.currentUser;
      if (u == null) throw 'Не авторизован';
      final row = await supa
          .from('user')
          .select('name, email, img, phone')
          .eq('id', u.id)
          .maybeSingle();

      _nameC.text = (row?['name'] as String?) ?? '';
      _emailC.text = (row?['email'] as String?) ?? (u.email ?? '');
      final phoneRaw = (row?['phone'] as String?) ?? '';
      _phoneC.text = RuPhoneFormatter.pretty(phoneRaw);
      _img = (row?['img'] as String?) ?? '';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeAvatar({bool camera = false}) async {
    if (_uploading) return;

    // по умолчанию галерея, при длинном тапе — камера
    final source = camera ? ImageSource.camera : ImageSource.gallery;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1080,
      imageQuality: 88,
    );
    if (picked == null) return;

    setState(() => _uploading = true);
    final snack = ScaffoldMessenger.of(context);

    try {
      final user = supa.auth.currentUser;
      if (user == null) throw 'Не авторизован';

      final ext = p.extension(picked.name).toLowerCase().replaceAll('.jpeg', '.jpg');
      final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}$ext';

      await supa.storage.from('avatars').upload(path, File(picked.path));
      final publicUrl = supa.storage.from('avatars').getPublicUrl(path);

      // сразу показываем новое фото
      setState(() => _img = publicUrl);
    } on StorageException catch (e) {
      snack.showSnackBar(SnackBar(content: Text('Storage error: ${e.message}')));
    } catch (e) {
      snack.showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    setState(() => _saving = true);
    final snack = ScaffoldMessenger.of(context);

    try {
      final uid = supa.auth.currentUser?.id;
      if (uid == null) throw 'Не авторизован';

      // нормализуем телефон для БД: +79991234567
      final phoneNorm = RuPhoneFormatter.normalize(_phoneC.text);

      await supa.from('user').update({
        'name': _nameC.text.trim(),
        'email': _emailC.text.trim(),
        'phone': phoneNorm,
        if (_img.isNotEmpty) 'img': _img,
      }).eq('id', uid);

      // модалка "успешно сохранено"
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SavedDialog(onOk: () {
          Navigator.of(context).pop(); // закрыть диалог
          Navigator.of(context).pop(true); // вернуться в профиль
        }),
      );
    } on PostgrestException catch (e) {
      snack.showSnackBar(SnackBar(content: Text('БД: ${e.message}')));
    } catch (e) {
      snack.showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- APP BAR как в products.dart ---
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
                        width: 80,
                        height: 62,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          const SizedBox(height: 24),

                          // Заголовок с отступами по 12
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'РЕД. ПРОФИЛЯ',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                                height: 1.0,
                                letterSpacing: ls24,
                                color: titleColor,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // --- Аватар 120x120 слева + кнопка-карандаш 36x36 ---
                          Align(
                              alignment:
                                  Alignment.centerLeft, // фиксируем слева
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 12), // как в макете "left: 12"
                                child: SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      ClipOval(
                                        child: Container(
                                          width: 120,
                                          height: 120,
                                          color: const Color(0xFFEFEFEF),
                                          child: (_img.isNotEmpty)
                                              ? Image.network(
                                                  _img, // 👈 текущее фото из БД
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Icon(Icons.person,
                                                          size: 56,
                                                          color: secondary),
                                                )
                                              : const Icon(Icons.person,
                                                  size: 56, color: secondary),
                                        ),
                                      ),
                                      // кнопка-карандаш 36x36 (#FF5E1C)
                                      SizedBox(
                                        width: 36,
                                        height: 36,
                                        child: ElevatedButton(
                                          onPressed:
                                              _uploading ? null : _changeAvatar,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: orange,
                                            shape: const CircleBorder(),
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: _uploading
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation(
                                                            Colors.white),
                                                  ),
                                                )
                                              : const Icon(Icons.edit_outlined,
                                                  color: Colors.white,
                                                  size: 18),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )),

                          const SizedBox(height: 20),

                          // Колонка с полями (боковые 16)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Имя
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Text(
                                    'Имя пользователя',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                      height: 1.0,
                                      color: labelColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _RoundedField(
                                  controller: _nameC,
                                  keyboardType: TextInputType.name,
                                ),

                                const SizedBox(height: 28),

                                // Email
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Text(
                                    'Электронная почта',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                      height: 1.0,
                                      color: labelColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _RoundedField(
                                  controller: _emailC,
                                  keyboardType: TextInputType.emailAddress,
                                ),

                                const SizedBox(height: 28),

                                // Телефон
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Text(
                                    'Номер телефона',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                      height: 1.0,
                                      color: labelColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _RoundedField(
                                  controller: _phoneC,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [_phoneMask],
                                ),

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),

                          // Кнопка СОХРАНИТЬ (по бокам 12)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: SizedBox(
                              height: 56,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saving ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orange,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 22),
                                ),
                                child: const Text(
                                  'СОХРАНИТЬ',
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

/// Однострочное поле: высота 48, скругление 10000, оранжевая рамка, внутренние отступы 20/16
class _RoundedField extends StatelessWidget {
  const _RoundedField({
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          fontSize: 14,
          height: 1.0,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10000),
            borderSide: const BorderSide(color: Color(0xFFFF5E1C), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10000),
            borderSide: const BorderSide(color: Color(0xFFFF5E1C), width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// Диалог «успешно сохранено»
class _SavedDialog extends StatelessWidget {
  const _SavedDialog({required this.onOk});
  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 280,
          maxWidth: 280,
          minHeight: 136,
          maxHeight: 136,
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
                  height: 22 / 18,
                  letterSpacing: -0.41,
                  color: Color(0xFF282828),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ваши данные успешно сохранены',
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
                    backgroundColor: const Color(0xFFFF5E1C),
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
                      letterSpacing: 0.4,
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

/// Примитивный форматтер телефона: +7 (XXX) XXX-XX-XX
class _PhoneFormatter extends TextInputFormatter {
  static String normalize(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    // приводим к формату России: если начинается с 8 — заменим на +7
    if (digits.isEmpty) return '';
    String d = digits;
    if (d.startsWith('8')) d = '7${d.substring(1)}';
    if (!d.startsWith('7')) d = '7$d';
    // берём максимум 11 цифр
    d = d.substring(0, d.length.clamp(0, 11));
    return '+$d';
  }

  static String pretty(String input) {
    final norm = normalize(input);
    final digits = norm.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    final b = StringBuffer('+7');
    final tail = digits.substring(1); // без кода страны
    if (tail.isNotEmpty) {
      b.write(' ');
      if (tail.length <= 3) {
        b.write('(${tail}');
      } else {
        b.write('(${tail.substring(0, 3)}) ');
        if (tail.length <= 6) {
          b.write(tail.substring(3));
        } else {
          b.write('${tail.substring(3, 6)}-');
          if (tail.length <= 8) {
            b.write(tail.substring(6));
          } else {
            b.write('${tail.substring(6, 8)}-');
            b.write(tail.substring(8));
          }
        }
      }
    }
    return b.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final prettyText = pretty(newValue.text);
    return TextEditingValue(
      text: prettyText,
      selection: TextSelection.collapsed(offset: prettyText.length),
    );
  }
}
