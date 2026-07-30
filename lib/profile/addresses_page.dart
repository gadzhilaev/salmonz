import 'package:flutter/material.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/network/api_exception.dart';
import 'package:salmonz/data/models/models.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});
  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  static const arrowColor = Color(0xFFCDCDCD);
  static const titleColor = Color(0xFF26351E);
  static const textDark = Color(0xFF282828);
  static const orange = Color(0xFFFF5E1C);
  static const double hLogo = 62;
  static const double ls24 = 0.96;

  late Future<List<AddressModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = AppServices.instance.addresses.list();
  }

  Future<void> _reload() async {
    setState(() => _future = AppServices.instance.addresses.list());
    await _future;
  }

  Future<void> _add() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const _AddressFormPage()),
    );
    if (ok == true) await _reload();
  }

  Future<void> _edit(AddressModel a) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _AddressFormPage(address: a)),
    );
    if (ok == true) await _reload();
  }

  Future<void> _delete(AddressModel a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить адрес?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await AppServices.instance.addresses.delete(a.id);
      await _reload();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
              Expanded(
                child: FutureBuilder<List<AddressModel>>(
                  future: _future,
                  builder: (context, snap) {
                    if (!snap.hasData &&
                        snap.connectionState != ConnectionState.done) {
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
                                color: textDark,
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              children: [
                                for (final a in items) ...[
                                  _AddressTile(
                                    address: a,
                                    onEdit: () => _edit(a),
                                    onDelete: () => _delete(a),
                                  ),
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
                              ),
                              child: const Text(
                                'ДОБАВИТЬ',
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
                        ),
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
    required this.onDelete,
  });

  final AddressModel address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const orange = Color(0xFFFF5E1C);
  static const textDark = Color(0xFF282828);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.home_outlined, size: 24, color: orange),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                address.heading.isEmpty ? address.city : address.heading,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                address.line,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  InkWell(
                    onTap: onEdit,
                    child: const Text(
                      'Редактировать',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: onDelete,
                    child: const Text(
                      'Удалить',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
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
  final AddressModel? address;

  @override
  State<_AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<_AddressFormPage> {
  static const arrowColor = Color(0xFFCDCDCD);
  static const titleColor = Color(0xFF26351E);
  static const orange = Color(0xFFFF5E1C);
  static const double hLogo = 62;
  static const double ls24 = 0.96;

  final _cityC = TextEditingController();
  final _streetC = TextEditingController();
  final _houseC = TextEditingController();
  final _aptC = TextEditingController();
  final _titleC = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    if (a != null) {
      _cityC.text = a.city;
      _streetC.text = a.street;
      _houseC.text = a.house;
      _aptC.text = a.apartment ?? '';
      _titleC.text = a.title ?? '';
    }
  }

  @override
  void dispose() {
    _cityC.dispose();
    _streetC.dispose();
    _houseC.dispose();
    _aptC.dispose();
    _titleC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final city = _cityC.text.trim();
    final street = _streetC.text.trim();
    final house = _houseC.text.trim();
    if (city.isEmpty || street.isEmpty || house.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите город, улицу и дом')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = AppServices.instance.addresses;
      if (widget.address == null) {
        await repo.create(
          title: _titleC.text.trim().isEmpty ? null : _titleC.text.trim(),
          city: city,
          street: street,
          house: house,
          apartment: _aptC.text.trim().isEmpty ? null : _aptC.text.trim(),
        );
      } else {
        await repo.update(
          widget.address!.id,
          title: _titleC.text.trim().isEmpty ? null : _titleC.text.trim(),
          city: city,
          street: street,
          house: house,
          apartment: _aptC.text.trim().isEmpty ? null : _aptC.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
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
              const Text(
                'АДРЕС',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: ls24,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 24),
              _field('Название (необяз.)', _titleC),
              _field('Город', _cityC),
              _field('Улица', _streetC),
              _field('Дом', _houseC),
              _field('Квартира', _aptC),
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

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: Color(0xB2464646),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: c,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10000),
                borderSide: const BorderSide(
                  color: Color(0xFFFF5E1C),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10000),
                borderSide: const BorderSide(
                  color: Color(0xFFFF5E1C),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
