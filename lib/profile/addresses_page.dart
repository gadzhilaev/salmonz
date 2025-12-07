import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supa = Supabase.instance.client;

/// Модель адреса
class UserAddress {
  final int id;
  final String country;
  final String city;
  final String line;

  const UserAddress({
    required this.id,
    required this.country,
    required this.city,
    required this.line,
  });

  factory UserAddress.fromMap(Map<String, dynamic> m) => UserAddress(
    id: (m['id'] as num).toInt(),
    country: (m['country'] ?? '') as String,
    city: (m['city'] ?? '') as String,
    line: (m['line'] ?? '') as String,
  );
}

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});
  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  static const bg = Color(0xFFFFFFFF);
  static const arrowColor = Color(0xFFCDCDCD);
  static const titleColor = Color(0xFF26351E);
  static const textDark = Color(0xFF282828);
  static const orange = Color(0xFFFF5E1C);
  static const double hLogo = 62;
  static const double ls24 = 0.96;

  Stream<List<UserAddress>> _stream() {
    final uid = supa.auth.currentUser?.id;
    if (uid == null) {
      return const Stream<List<UserAddress>>.empty();
    }
    return supa
        .from('addresses')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('id', ascending: true)
        .map((rows) => rows
        .map((e) => UserAddress.fromMap(e))
        .toList());
  }

  Future<void> _add() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const _AddressFormPage()),
    );
    // Ничего не делаем: StreamBuilder сам получит обновления realtime.
  }

  Future<void> _edit(UserAddress a) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _AddressFormPage(address: a)),
    );
    // Тоже ничего не нужно — список обновит Stream.
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
              // app bar как в products.dart
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

              const SizedBox(height: 24),

              Expanded(
                child: StreamBuilder<List<UserAddress>>(
                  stream: _stream(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = snap.data ?? [];

                    return ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'АДРЕСА',
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

                        if (items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Адресов пока нет',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                                color: textDark,
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              children: [
                                for (int i = 0; i < items.length; i++) ...[
                                  _AddressTile(
                                    address: items[i],
                                    onEdit: () => _edit(items[i]),
                                  ),
                                  if (i != items.length - 1)
                                    const SizedBox(height: 20),
                                ],
                              ],
                            ),
                          ),

                        const SizedBox(height: 40),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _add,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 22,
                                ),
                              ),
                              child: const Text(
                                'ДОБАВИТЬ',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  height: 1.0,
                                  letterSpacing: 0.48,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.onEdit,
  });

  final UserAddress address;
  final VoidCallback onEdit;

  static const orange = Color(0xFFFF5E1C);
  static const textDark = Color(0xFF282828);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: Icon(Icons.home_outlined, size: 24, color: orange),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${address.country}, ${address.city}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  height: 1.3,
                  letterSpacing: 0,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                address.line,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  height: 1.3,
                  letterSpacing: 0,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    'Редактировать',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      height: 1.3,
                      letterSpacing: 0,
                      color: orange,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddressFormPage extends StatefulWidget {
  const _AddressFormPage({this.address});
  final UserAddress? address;

  @override
  State<_AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<_AddressFormPage> {
  static const bg = Color(0xFFFFFFFF);
  static const arrowColor = Color(0xFFCDCDCD);
  static const titleColor = Color(0xFF26351E);
  static const orange = Color(0xFFFF5E1C);
  static const double hLogo = 62;
  static const double ls24 = 0.96;

  final _countryC = TextEditingController();
  final _cityC = TextEditingController();
  final _lineC = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _countryC.text = widget.address!.country;
      _cityC.text = widget.address!.city;
      _lineC.text = widget.address!.line;
    }
  }

  @override
  void dispose() {
    _countryC.dispose();
    _cityC.dispose();
    _lineC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final uid = supa.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Не авторизован')));
      }
      setState(() => _saving = false);
      return;
    }

    try {
      if (widget.address == null) {
        await supa
            .from('addresses')
            .insert({
          'user_id': uid,
          'country': _countryC.text.trim(),
          'city': _cityC.text.trim(),
          'line': _lineC.text.trim(),
        })
            .select()
            .single();
      } else {
        await supa
            .from('addresses')
            .update({
          'country': _countryC.text.trim(),
          'city': _cityC.text.trim(),
          'line': _lineC.text.trim(),
        })
            .eq('id', widget.address!.id)
            .eq('user_id', uid)
            .select()
            .single();
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // APP BAR как в products.dart
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
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: arrowColor,
                          ),
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

              const SizedBox(height: 24),

              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'АДРЕС',
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
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Label('Страна'),
                    SizedBox(height: 8),
                  ],
                ),
              ),
              _RoundedField(controller: _countryC),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Label('Город'),
                    SizedBox(height: 8),
                  ],
                ),
              ),
              _RoundedField(controller: _cityC),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Label('Адрес'),
                    SizedBox(height: 8),
                  ],
                ),
              ),
              _RoundedField(controller: _lineC, maxLines: 3),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 22),
                    ),
                    child: const Text(
                      'СОХРАНИТЬ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.0,
                        letterSpacing: 0.48,
                        color: Colors.white,
                      ),
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
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        fontSize: 13,
        height: 1.0,
        color: Color(0xB2464646),
      ),
    );
  }
}

class _RoundedField extends StatelessWidget {
  const _RoundedField({
    required this.controller,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: maxLines == 1 ? 48 : null,
        child: TextField(
          controller: controller,
          maxLines: maxLines,
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
              borderSide:
              const BorderSide(color: Color(0xFFFF5E1C), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10000),
              borderSide:
              const BorderSide(color: Color(0xFFFF5E1C), width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}