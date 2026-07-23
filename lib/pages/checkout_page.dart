import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/network/api_exception.dart';
import 'package:salmonz/data/models/models.dart';
import 'package:uuid/uuid.dart';
import '../widgets/cart.dart';
import '../profile/addresses_page.dart';
import '../nav_bar/orders.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  AddressModel? _selected;
  final _phoneCtr = TextEditingController(text: '+7 ');
  final _commentCtr = TextEditingController();
  bool _sending = false;
  bool _loading = true;

  static const bg = Color(0xFFFFFFFF);
  static const arrowColor = Color(0xFFCDCDCD);
  static const titleDark = Color(0xFF26351E);
  static const orange = Color(0xFFFF5E1C);
  static const double hLogo = 62;
  static const double ls24 = 0.96;
  static const double ls20 = 0.8;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    try {
      final profile = await AppServices.instance.profile.getMe();
      final phone = profile.phone?.trim();
      if (phone != null && phone.isNotEmpty) {
        _phoneCtr.text = RuPhoneTextInputFormatter.format(phone);
      }
      final addrs = await AppServices.instance.addresses.list();
      if (addrs.isNotEmpty) {
        _selected = addrs.firstWhere(
          (a) => a.isDefault,
          orElse: () => addrs.first,
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _phoneCtr.dispose();
    _commentCtr.dispose();
    super.dispose();
  }

  Future<void> _pickAddress() async {
    final selected = await showModalBottomSheet<AddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressesSheet(
        desiredHeight: MediaQuery.of(context).size.height * 0.7,
      ),
    );
    if (selected != null) setState(() => _selected = selected);
  }

  Future<void> _placeOrder() async {
    final cart = Cart.instance;
    final phone = _phoneCtr.text.trim();
    final comment = _commentCtr.text.trim();

    if (_selected == null) {
      _snack('Выберите адрес доставки');
      return;
    }
    if (!phone.startsWith('+7') ||
        phone.replaceAll(RegExp(r'\D'), '').length < 11) {
      _snack('Введите телефон в формате +7 ...');
      return;
    }
    if (cart.items.isEmpty) {
      _snack('Корзина пуста');
      return;
    }

    setState(() => _sending = true);
    try {
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      await AppServices.instance.orders.create(
        addressId: _selected!.id,
        phone: '+$digits',
        comment: comment.isEmpty ? null : comment,
        items: cart.items
            .map((e) => (productId: e.id, quantity: e.qty))
            .toList(),
        idempotencyKey: const Uuid().v4(),
      );

      await Cart.instance.clear();
      if (!mounted) return;
      _snack('Заказ успешно оформлен!');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OrdersPage()),
        (r) => false,
      );
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Ошибка: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
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
                          const Text(
                            'ОФОРМЛЕНИЕ ЗАКАЗА',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              height: 1.0,
                              letterSpacing: ls24,
                              color: titleDark,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_selected != null) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.home_outlined,
                                    size: 24, color: orange),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selected!.heading.isEmpty
                                            ? _selected!.city
                                            : _selected!.heading,
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
                                        _selected!.line,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 16,
                                          height: 1.3,
                                          color: Color(0xFF282828),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: _pickAddress,
                                        child: const Text(
                                          'Выбрать',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                            color: orange,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            TextButton(
                              onPressed: _pickAddress,
                              child: const Text('Выбрать адрес доставки'),
                            ),
                          ],
                          const SizedBox(height: 24),
                          const _Label('Номер телефона  *'),
                          const SizedBox(height: 12),
                          _OutlinedField(
                            controller: _phoneCtr,
                            hint: '+7 900 000 00 00',
                            keyboardType: TextInputType.phone,
                            inputFormatters: [RuPhoneTextInputFormatter()],
                          ),
                          const SizedBox(height: 10),
                          const _Label('Комментарий к заказу'),
                          const SizedBox(height: 12),
                          _OutlinedField(
                            controller: _commentCtr,
                            hint: 'Введите комментарий',
                            maxLines: 4,
                            minHeight: 100,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'ВАШ ЗАКАЗ',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              height: 1.0,
                              letterSpacing: ls20,
                              color: titleDark,
                            ),
                          ),
                          const SizedBox(height: 24),
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
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'ИТОГО:',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 24,
                                          letterSpacing: ls24,
                                          color: titleDark,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        cart.totalSum.formatRub(),
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 24,
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
                                          borderRadius:
                                              BorderRadius.circular(40),
                                        ),
                                      ),
                                      child: _sending
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'ЗАКАЗАТЬ',
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
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Color(0xB2464646),
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
          color: Colors.black,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.fromLTRB(20, 17, 20, 17),
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 14,
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

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 120,
            height: 80,
            color: const Color(0xFFFAFAFA),
            child: Image.network(
              item.img,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  height: 1.3,
                  letterSpacing: 0.56,
                  color: Color(0xFF26351E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${item.qty} шт · ${item.subtotal.formatRub()}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xFF282828),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RuPhoneTextInputFormatter extends TextInputFormatter {
  static String format(String rawDigits) {
    final d = rawDigits.replaceAll(RegExp(r'\D'), '');
    String digits = d;
    if (digits.isEmpty) return '+7 ';
    if (digits.startsWith('8')) digits = '7${digits.substring(1)}';
    if (!digits.startsWith('7')) digits = '7$digits';

    final buf = StringBuffer('+7 ');
    final body = digits.length > 1 ? digits.substring(1) : '';

    if (body.isNotEmpty) {
      buf.write('(');
      buf.write(body.substring(0, body.length.clamp(0, 3)));
      if (body.length >= 3) buf.write(') ');
    }
    if (body.length > 3) {
      buf.write(body.substring(3, body.length.clamp(3, 6)));
      if (body.length >= 6) buf.write('-');
    }
    if (body.length > 6) {
      buf.write(body.substring(6, body.length.clamp(6, 8)));
      if (body.length >= 8) buf.write('-');
    }
    if (body.length > 8) {
      buf.write(body.substring(8, body.length.clamp(8, 10)));
    }
    return buf.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final onlyDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited =
        onlyDigits.length > 11 ? onlyDigits.substring(0, 11) : onlyDigits;
    final formatted = format(limited);
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
  List<AddressModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await AppServices.instance.addresses.list();
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
                          color: Color(0xFF282828),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close,
                          size: 20, color: Color(0xFFD6D6D6)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const Expanded(
                      child: Center(child: CircularProgressIndicator()))
                else if (_items.isEmpty)
                  const Expanded(
                    child: Center(child: Text('Адресов пока нет')),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 20),
                      itemBuilder: (_, i) {
                        final a = _items[i];
                        return InkWell(
                          onTap: () => Navigator.pop(context, a),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.home_outlined,
                                  size: 24, color: orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.heading.isEmpty ? a.city : a.heading,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(a.line),
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
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddressesPage()),
                      );
                      await _load();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40)),
                    ),
                    child: const Text(
                      'УПРАВЛЯТЬ АДРЕСАМИ',
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
      ),
    );
  }
}
