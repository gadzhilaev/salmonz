import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/network/api_exception.dart';
import '../utils/ru_phone_formatter.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const bg = Color(0xFFFFFFFF);
  static const arrowColor = Color(0xFFCDCDCD);
  static const titleColor = Color(0xFF26351E);
  static const orange = Color(0xFFFF5E1C);
  static const double hLogo = 62;
  static const double ls24 = 0.96;

  final _picker = ImagePicker();
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();

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
      final u = await AppServices.instance.profile.getMe();
      _nameC.text = u.name;
      _emailC.text = u.email;
      _phoneC.text = RuPhoneFormatter.pretty(u.phone ?? '');
      _img = u.avatarUrl ?? '';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeAvatar({bool camera = false}) async {
    if (_uploading) return;
    final source = camera ? ImageSource.camera : ImageSource.gallery;
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1080,
      imageQuality: 88,
    );
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final user = await AppServices.instance.profile.uploadAvatar(
        filePath: picked.path,
        filename: p.basename(picked.path),
      );
      setState(() => _img = user.avatarUrl ?? '');
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final phoneNorm = RuPhoneFormatter.normalize(_phoneC.text);
      await AppServices.instance.profile.updateMe(
        name: _nameC.text.trim(),
        phone: phoneNorm,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ListView(
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
                              icon: const Icon(Icons.arrow_back_ios_new,
                                  size: 20, color: arrowColor),
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
                    const Text(
                      'РЕДАКТИРОВАТЬ',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: ls24,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: GestureDetector(
                        onTap: () => _changeAvatar(),
                        onLongPress: () => _changeAvatar(camera: true),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            ClipOval(
                              child: Container(
                                width: 120,
                                height: 120,
                                color: const Color(0xFFEFEFEF),
                                child: _uploading
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : (_img.isNotEmpty
                                        ? Image.network(_img,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.person,
                                                    size: 56))
                                        : const Icon(Icons.person, size: 56)),
                              ),
                            ),
                            const CircleAvatar(
                              radius: 16,
                              backgroundColor: orange,
                              child: Icon(Icons.camera_alt,
                                  size: 16, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _field('Имя', _nameC),
                    _field('Email', _emailC, enabled: false),
                    _field(
                      'Телефон',
                      _phoneC,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [RuPhoneTextInputFormatter()],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        child: const Text(
                          'СОХРАНИТЬ',
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
                  ],
                ),
              ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController c, {
    bool enabled = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 8),
          TextField(
            controller: c,
            enabled: enabled,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: orange),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: orange, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
