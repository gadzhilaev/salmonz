import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/cart.dart';
import '../profile/addresses_page.dart';
import '../nav_bar/orders.dart';

final supa = Supabase.instance.client;

// маленькая вью-модель для адреса
class _LastAddress {
  _LastAddress({required this.country, required this.city, required this.line});
  final String country;
  final String city;
  final String line;

  String get heading => [country, city].where((e) => e.trim().isNotEmpty).join(', ');
  String get fullForInput => [country, city, line].where((e) => e.trim().isNotEmpty).join(', ');
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  _LastAddress? _lastAddr;     // последний адрес из БД
  String? _lastAddrRaw;        // строка "как была в инпуте", чтобы сравнить при сохранении
  bool _loadingDefaults = true; // пока грузим дефолты
  final _addrCtr = TextEditingController();
  final _phoneCtr = TextEditingController(text: '+7 ');
  final _commentCtr = TextEditingController();
  bool _sending = false;

  // цвета/константы как в макете
  static const bg = Color(0xFFFFFFFF);
  static const arrowColor = Color(0xFFCDCDCD);
  static const titleDark = Color(0xFF26351E);
  static const orange = Color(0xFFFF5E1C);

  static const double hLogo = 62;
  static const double ls24 = 0.96; // 4% от 24
  static const double ls20 = 0.8;  // 4% от 20
  static const double ls14 = 0.56; // 4% от 14

  @override
  void initState() {
    super.initState();
    _prefillFromDb(); // 👈
  }

  Future<void> _prefillFromDb() async {
    final uid = supa.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _loadingDefaults = false);
      return;
    }

    try {
      // 1) телефон из user + формат сразу
      final userRow = await supa
          .from('user')
          .select('phone')
          .eq('id', uid)
          .maybeSingle();

      final dbPhone = (userRow?['phone'] as String?)?.trim();
      if (dbPhone != null && dbPhone.isNotEmpty) {
        _phoneCtr.text = RuPhoneTextInputFormatter.format(dbPhone);
      }

      // 2) СНАЧАЛА пробуем адрес из последнего заказа
      final lastOrder = await supa
          .from('orders')
          .select('address, created_at')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      String? addressFromOrder =
      (lastOrder?['address'] as String?)?.trim();

      if (addressFromOrder != null && addressFromOrder.isNotEmpty) {
        // распарсим строку заказа в (страна, город, линия)
        final parsed = _parseAddress(addressFromOrder);
        _lastAddr = parsed;
        _lastAddrRaw = parsed.fullForInput;
        _addrCtr.text = parsed.fullForInput; // подставляем в инпут
      } else {
        // 3) иначе — последний добавленный адрес пользователя
        final rows = await supa
            .from('addresses')
            .select('country, city, line, created_at')
            .eq('user_id', uid)
            .order('created_at', ascending: false)
            .limit(1);

        if (rows is List && rows.isNotEmpty) {
          final m = rows.first as Map<String, dynamic>;
          final addr = _LastAddress(
            country: (m['country'] ?? '') as String,
            city:    (m['city'] ?? '') as String,
            line:    (m['line'] ?? '') as String,
          );
          _lastAddr = addr;
          _lastAddrRaw = addr.fullForInput;
          _addrCtr.text = addr.fullForInput;
        }
      }
    } catch (_) {
      // тихо — не ломаем UX
    } finally {
      if (mounted) setState(() => _loadingDefaults = false);
    }
  }

  @override
  void dispose() {
    _addrCtr.dispose();
    _phoneCtr.dispose();
    _commentCtr.dispose();
    super.dispose();
  }

  Future<void> _openAddressPickerSheet() async {
    final uid = supa.auth.currentUser?.id;
    if (uid == null) return;

    final mq = MediaQuery.of(context);
    // высоту можно взять как 70% экрана или как тебе нужно
    final double desiredHeight = mq.size.height * 0.7;

    final selected = await showModalBottomSheet<_LastAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _AddressesSheet(desiredHeight: desiredHeight);
      },
    );

    if (selected != null) {
      // применяем выбранный адрес
      setState(() {
        _lastAddr = selected;
        _lastAddrRaw = selected.fullForInput;
        _addrCtr.text = selected.fullForInput;
      });
    }
  }

  Future<void> _placeOrder() async {
    final cart = Cart.instance;

    final addressInput = _addrCtr.text.trim();
    final phone   = _phoneCtr.text.trim();
    final comment = _commentCtr.text.trim();

    if (addressInput.isEmpty) { _snack('Введите адрес доставки'); return; }
    if (!phone.startsWith('+7') || phone.replaceAll(RegExp(r'\D'), '').length < 11) {
      _snack('Введите телефон в формате +7 ...'); return;
    }
    if (cart.items.isEmpty) { _snack('Корзина пуста'); return; }

    setState(() => _sending = true);
    try {
      final userId = supa.auth.currentUser?.id;

      // 1) если адрес новый — сохраним в addresses
      if (userId != null && addressInput.isNotEmpty && addressInput != (_lastAddrRaw ?? '')) {
        final parsed = _parseAddress(addressInput);
        await supa.from('addresses').insert({
          'user_id': userId,
          'country': parsed.country,
          'city'   : parsed.city,
          'line'   : parsed.line,
        });
        // обновим локальный "последний адрес"
        _lastAddr = parsed;
        _lastAddrRaw = parsed.fullForInput;
      }

      // 2) формируем заказ
      final productIds = cart.items.map((e) => e.id).toList();
      final qtyList    = cart.items.map((e) => e.qty).toList();
      final priceList  = cart.items.map((e) => e.price).toList();
      final summ       = cart.totalSum;

      await supa.from('orders').insert({
        'user_id'     : userId,
        'product_list': productIds,
        'value_list'  : qtyList,
        'price_list'  : priceList,
        'summ'        : summ,
        'address'     : addressInput, // для истории заказа можно класть как одну строку
        'phone'       : phone,
        'comment'     : comment,
      });

      await Cart.instance.clear();
      if (!mounted) return;
      _snack('Заказ успешно оформлен!');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OrdersPage()),
            (r) => false,
      );
    } on PostgrestException catch (e) {
      _snack('Ошибка БД: ${e.message}');
    } catch (e) {
      _snack('Ошибка: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  _LastAddress _parseAddress(String input) {
    final parts = input.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (parts.length >= 3) {
      final country = parts[0];
      final city    = parts[1];
      final line    = parts.sublist(2).join(', ');
      return _LastAddress(country: country, city: city, line: line);
    } else if (parts.length == 2) {
      return _LastAddress(country: parts[0], city: parts[1], line: '');
    } else if (parts.length == 1) {
      // если ввели только улицу — подставим дефолтную страну
      return _LastAddress(country: 'Россия', city: '', line: parts[0]);
    } else {
      return _LastAddress(country: 'Россия', city: '', line: '');
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final cart = Cart.instance;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // appbar как в products.dart
              SizedBox(
                height: hLogo + 26,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      left: 20, top: 26,
                      child: SizedBox(
                        width: 24, height: 24,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          splashRadius: 20,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: arrowColor),
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

              // скролл блок
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 24),

                    // ОФОРМЛЕНИЕ ЗАКАЗА
                    Text(
                      'ОФОРМЛЕНИЕ ЗАКАЗА',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        height: 1.0,
                        letterSpacing: ls24,
                        color: titleDark,
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (_lastAddr != null) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.home_outlined, size: 24, color: Color(0xFFFF5E1C)),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _lastAddr!.heading,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    height: 1.3,
                                    letterSpacing: 0,
                                    color: Color(0xFF282828),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _lastAddr!.line,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 16,
                                    height: 1.3,
                                    letterSpacing: 0,
                                    color: Color(0xFF282828),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // 👇 КНОПКА "ВЫБРАТЬ" как «Редактировать»
                                InkWell(
                                  onTap: _openAddressPickerSheet,
                                  borderRadius: BorderRadius.circular(6),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 2),
                                    child: Text(
                                      'Выбрать',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        height: 1.3,
                                        letterSpacing: 0,
                                        color: Color(0xFFFF5E1C),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Адрес
                    const _Label('Адрес доставки (улица, дом, квартира) *'),
                    const SizedBox(height: 12),
                    _OutlinedField(
                      controller: _addrCtr,
                      hint: 'Введите адрес доставки',
                      keyboardType: TextInputType.streetAddress,
                    ),

                    const SizedBox(height: 16),

                    // Телефон
                    const _Label('Номер телефона  *'),
                    const SizedBox(height: 12),
                    _OutlinedField(
                      controller: _phoneCtr,
                      hint: '+7 900 000 00 00',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        RuPhoneTextInputFormatter(),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Комментарий
                    const _Label('Комментарий к заказу'),
                    const SizedBox(height: 12),
                    _OutlinedField(
                      controller: _commentCtr,
                      hint: 'Введите комментарий',
                      maxLines: 4,
                      minHeight: 100,
                    ),

                    const SizedBox(height: 24),

                    // Ваш заказ
                    Text(
                      'ВАШ ЗАКАЗ',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        height: 1.0,
                        letterSpacing: ls20,
                        color: titleDark,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // список товаров
                    AnimatedBuilder(
                      animation: cart,
                      builder: (_, __) {
                        final items = cart.items;
                        return Column(
                          children: [
                            for (final it in items) ...[
                              _OrderItemTile(item: it),
                              const SizedBox(height: 16),
                            ],
                            const SizedBox(height: 24),
                            // ИТОГО
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'ИТОГО:',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 24,
                                    height: 1.0,
                                    letterSpacing: ls24,
                                    color: titleDark,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_fmt(cart.totalSum)} ₽',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 24,
                                    height: 1.0,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _sending ? null : _placeOrder,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orange,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                ),
                                child: _sending
                                    ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                                    : const Text(
                                  'ЗАКАЗАТЬ',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    height: 1.0,
                                    letterSpacing: 0.48, // 4%
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(double v) {
    final isInt = v == v.roundToDouble();
    return isInt ? v.toInt().toString() : v.toStringAsFixed(2).replaceAll(RegExp(r'\.0+$'), '');
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8), // 12 + 8 = 20
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 13,
            height: 1.0,
            letterSpacing: 0,
            color: Color(0xB2464646), // #464646B2
          ),
        ),
      ),
    );
  }
}
class _OutlinedField extends StatelessWidget {
  const _OutlinedField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.minHeight = 48,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 14,
          height: 1.0,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.fromLTRB(20, 17, 20, 17),
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            height: 1.0,
            color: Colors.black54,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xFFFF5E1C), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xFFFF5E1C), width: 2),
          ),
        ),
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});
  final CartItem item;

  static const titleDark = Color(0xFF26351E);
  static const gray2828 = Color(0xFF282828);
  static const tileBg = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 120, height: 80, color: tileBg,
            child: Image.network(item.img, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name.toUpperCase(),
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  height: 1.3,
                  letterSpacing: 0.56,
                  color: titleDark,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${item.amount} шт × ${item.qty}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      height: 22/14,
                      color: gray2828,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_fmt(item.subtotal)} ₽',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      height: 1.0,
                      color: Colors.black,
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

  static String _fmt(double v) {
    final isInt = v == v.roundToDouble();
    return isInt ? v.toInt().toString() : v.toStringAsFixed(2).replaceAll(RegExp(r'\.0+$'), '');
  }
}

/// Маска: +7 (XXX) XXX-XX-XX
class RuPhoneTextInputFormatter extends TextInputFormatter {
  static final _digits = RegExp(r'\d');

  /// Удобно иметь статический метод форматирования по "сырым" цифрам
  static String format(String rawDigits) {
    // оставляем только цифры
    final d = rawDigits.replaceAll(RegExp(r'\D'), '');
    // ожидаем 11 цифр, где первая — 7 (или 8 -> приведём к 7)
    String digits = d;
    if (digits.isEmpty) return '+7 ';
    if (digits.startsWith('8')) digits = '7${digits.substring(1)}';
    if (!digits.startsWith('7')) digits = '7${digits}';

    final buf = StringBuffer('+7 ');
    // пропускаем первую "7" — она уже в префиксе
    final body = digits.length > 1 ? digits.substring(1) : '';

    // (XXX)
    if (body.isNotEmpty) {
      buf.write('(');
      buf.write(body.substring(0, body.length.clamp(0, 3)));
      if (body.length >= 3) buf.write(') ');
    }

    // XXX
    if (body.length > 3) {
      buf.write(body.substring(3, body.length.clamp(3, 6)));
      if (body.length >= 6) buf.write('-');
    }

    // XX
    if (body.length > 6) {
      buf.write(body.substring(6, body.length.clamp(6, 8)));
      if (body.length >= 8) buf.write('-');
    }

    // XX
    if (body.length > 8) {
      buf.write(body.substring(8, body.length.clamp(8, 10)));
    }

    return buf.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // берём только цифры из того, что прислал пользователь
    final onlyDigits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // ограничим максимумом 11 цифр (7 + 10)
    final limited = onlyDigits.length > 11 ? onlyDigits.substring(0, 11) : onlyDigits;

    final formatted = format(limited);

    // курсор — в конец форматированной строки
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _AddressesSheet extends StatefulWidget {
  const _AddressesSheet({required this.desiredHeight});
  final double desiredHeight;

  @override
  State<_AddressesSheet> createState() => _AddressesSheetState();
}

class _AddressesSheetState extends State<_AddressesSheet> {
  List<_LastAddress> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = supa.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await supa
          .from('addresses')
          .select('country,city,line,created_at')
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      final list = (res as List).map((e) {
        final m = e as Map<String, dynamic>;
        return _LastAddress(
          country: (m['country'] ?? '') as String,
          city: (m['city'] ?? '') as String,
          line: (m['line'] ?? '') as String,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _items = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const titleColor = Color(0xFF282828);
    const orange = Color(0xFFFF5E1C);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        height: widget.desiredHeight,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0D000000),
              offset: Offset(3, -12),
              blurRadius: 20,
            )
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'ВЫБОР АДРЕСА',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          height: 23/24,
                          color: titleColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20, color: Color(0xFFD6D6D6)),
                      splashRadius: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (_loading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else if (_items.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Адресов пока нет',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF282828),
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 20),
                      itemBuilder: (_, i) {
                        final a = _items[i];
                        return InkWell(
                          onTap: () => Navigator.pop(context, a), // выбрать
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.home_outlined, size: 24, color: orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.heading,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                        height: 1.3,
                                        color: Color(0xFF282828),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      a.line,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 16,
                                        height: 1.3,
                                        color: Color(0xFF282828),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 20),

                // Можно ещё добавить кнопку "УПРАВЛЯТЬ АДРЕСАМИ" -> экран адресов
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      // откроем экран адресов; после возврата перезагрузим список
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddressesPage()),
                      );
                      await _load(); // refresh список в шите
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                      padding: const EdgeInsets.symmetric(vertical: 22),
                    ),
                    child: const Text(
                      'УПРАВЛЯТЬ АДРЕСАМИ',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}