import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/money/money.dart';
import 'package:salmonz/core/network/api_exception.dart';
import 'package:salmonz/core/theme/app_theme.dart';
import 'package:salmonz/data/models/models.dart';
import 'package:uuid/uuid.dart';
import '../widgets/cart.dart';
import '../profile/addresses_page.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import '../widgets/app_root.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/app_error_view.dart';

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

  /// Stable across double-taps / retry after transient errors.
  String? _idempotencyKey;

  OrderQuoteModel? _quote;
  bool _quoteLoading = false;
  String? _quoteError;
  int _quoteGen = 0;
  Timer? _quoteDebounce;

  static const orange = AppTheme.orange;
  static const double hLogo = 62;
  static const double ls24 = 0.96;
  static const double ls20 = 0.8;

  @override
  void initState() {
    super.initState();
    Cart.instance.addListener(_onCartChanged);
    _prefill();
    _scheduleQuote();
  }

  void _onCartChanged() {
    if (!mounted) return;
    setState(() {});
    _scheduleQuote();
  }

  void _scheduleQuote() {
    _quoteDebounce?.cancel();
    _quoteDebounce = Timer(const Duration(milliseconds: 300), _fetchQuote);
  }

  Future<void> _fetchQuote() async {
    final cart = Cart.instance;
    if (cart.items.isEmpty) {
      if (!mounted) return;
      setState(() {
        _quote = null;
        _quoteLoading = false;
        _quoteError = null;
      });
      return;
    }

    final gen = ++_quoteGen;
    setState(() {
      _quoteLoading = true;
      _quoteError = null;
    });

    try {
      final quote = await AppServices.instance.orders.quote(
        items: cart.items
            .map((e) => (productId: e.id, quantity: e.qty))
            .toList(),
      );
      if (!mounted || gen != _quoteGen) return;
      setState(() {
        _quote = quote;
        _quoteLoading = false;
        _quoteError = null;
      });
    } on ApiException catch (e) {
      if (!mounted || gen != _quoteGen) return;
      setState(() {
        _quoteLoading = false;
        _quoteError = e.userMessage;
      });
    } catch (e) {
      if (!mounted || gen != _quoteGen) return;
      setState(() {
        _quoteLoading = false;
        _quoteError = ApiException.userMessageFrom(e);
      });
    }
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
    _quoteDebounce?.cancel();
    Cart.instance.removeListener(_onCartChanged);
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
    if (_sending) return;

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
    if (_quoteError != null) {
      _snack('Дождитесь успешного расчёта заказа');
      return;
    }
    final unavailable = _quote?.unavailableItems ?? const [];
    if (unavailable.isNotEmpty) {
      _snack('В корзине есть недоступные товары');
      return;
    }

    // Lock only after validation so the button stays tappable on form errors.
    _sending = true;
    if (mounted) setState(() {});

    _idempotencyKey ??= const Uuid().v4();
    try {
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      final order = await AppServices.instance.orders.create(
        addressId: _selected!.id,
        phone: '+$digits',
        comment: comment.isEmpty ? null : comment,
        items: cart.items
            .map((e) => (productId: e.id, quantity: e.qty))
            .toList(),
        idempotencyKey: _idempotencyKey!,
      );

      _idempotencyKey = null;
      await Cart.instance.clear();
      if (!mounted) return;
      _snack('Заказ успешно оформлен! Итого: ${order.total.formatRub()}');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const AppRoot(initialTab: AppTab.orders),
        ),
        (r) => false,
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _sending = false);
      _snack(e.userMessage);
    } catch (e) {
      if (mounted) setState(() => _sending = false);
      _snack(ApiException.userMessageFrom(e));
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final cart = Cart.instance;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final titleColor = theme.brightness == Brightness.dark
        ? cs.onSurface
        : AppTheme.darkGreen;
    final bodyColor = theme.brightness == Brightness.dark
        ? cs.onSurface
        : AppTheme.secondaryText;
    final arrowColor = theme.brightness == Brightness.dark
        ? cs.onSurface.withValues(alpha: 0.45)
        : const Color(0xFFCDCDCD);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          splashRadius: 20,
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
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
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          const SizedBox(height: 24),
                          Text(
                            'ОФОРМЛЕНИЕ ЗАКАЗА',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              height: 1.0,
                              letterSpacing: ls24,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_selected != null) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.home_outlined,
                                  size: 24,
                                  color: orange,
                                ),
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
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18,
                                          height: 1.3,
                                          color: bodyColor,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _selected!.line,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 16,
                                          height: 1.3,
                                          color: bodyColor,
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
                            key: const Key('checkoutPhone'),
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
                          Text(
                            'ВАШ ЗАКАЗ',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              height: 1.0,
                              letterSpacing: ls20,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          AnimatedBuilder(
                            animation: cart,
                            builder: (_, __) {
                              final items = cart.items;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final it in items) ...[
                                    _OrderItemTile(
                                      item: it,
                                      quoteLine: _quoteLineFor(it.id),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  if (_quote != null &&
                                      _quote!.unavailableItems.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: cs.errorContainer.withValues(
                                          alpha: 0.35,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Недоступно: ${_quote!.unavailableItems.map((e) => e.productName).join(', ')}',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          color: cs.error,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  if (_quoteError != null) ...[
                                    AppErrorView(
                                      message: _quoteError!,
                                      onRetry: _fetchQuote,
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  if (_quoteLoading && _quote == null)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (_quote != null) ...[
                                    _MoneyRow(
                                      label: 'Товары',
                                      value: _quote!.subtotal.formatRub(),
                                      color: bodyColor,
                                    ),
                                    const SizedBox(height: 8),
                                    _MoneyRow(
                                      label: 'Доставка',
                                      value: _quote!.deliveryFee.minorUnits == 0
                                          ? 'Бесплатно'
                                          : _quote!.deliveryFee.formatRub(),
                                      color: bodyColor,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _freeDeliveryText(_quote!),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 13,
                                        color: bodyColor.withValues(
                                          alpha: 0.75,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'ИТОГО:',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 24,
                                          letterSpacing: ls24,
                                          color: titleColor,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      if (_quoteLoading && _quote == null)
                                        Text(
                                          'примерно ${cart.totalSum.formatRub()}',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                            fontSize: 20,
                                            color: bodyColor.withValues(
                                              alpha: 0.7,
                                            ),
                                          ),
                                        )
                                      else
                                        Text(
                                          key: const Key('quoteTotal'),
                                          (_quote?.total ?? cart.totalSum)
                                              .formatRub(),
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                            fontSize: 24,
                                            color: bodyColor,
                                          ),
                                        ),
                                      if (_quoteLoading && _quote != null) ...[
                                        const SizedBox(width: 8),
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (_quote == null &&
                                      !_quoteLoading &&
                                      _quoteError == null &&
                                      items.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'примерно ${cart.totalSum.formatRub()}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        color: bodyColor.withValues(
                                          alpha: 0.65,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 40),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      key: const Key('checkoutCreateOrder'),
                                      onPressed:
                                          _sending ||
                                              items.isEmpty ||
                                              _quoteError != null
                                          ? null
                                          : _placeOrder,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: orange,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            40,
                                          ),
                                        ),
                                      ),
                                      child: _sending
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
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

  OrderQuoteLineModel? _quoteLineFor(String productId) {
    final quote = _quote;
    if (quote == null) return null;
    for (final line in quote.items) {
      if (line.productId == productId) return line;
    }
    return null;
  }

  String _freeDeliveryText(OrderQuoteModel quote) {
    final threshold = Money.fromRubles(quote.freeDeliveryThreshold);
    if (quote.deliveryFee.minorUnits == 0) {
      return 'Доставка бесплатна (порог ${threshold.formatRub()})';
    }
    final rem = threshold - quote.subtotal;
    if (rem.minorUnits > 0) {
      return 'Бесплатная доставка от ${threshold.formatRub()}. Осталось ${rem.formatRub()}';
    }
    return 'Бесплатная доставка от ${threshold.formatRub()}';
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
        : const Color(0xB2464646);
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: muted,
          ),
        ),
      ),
    );
  }
}

class _OutlinedField extends StatelessWidget {
  const _OutlinedField({
    super.key,
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
    final cs = Theme.of(context).colorScheme;
    final textColor = cs.onSurface;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: textColor,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.fromLTRB(20, 17, 20, 17),
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: textColor.withValues(alpha: 0.45),
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
  const _OrderItemTile({required this.item, this.quoteLine});
  final CartItem item;
  final OrderQuoteLineModel? quoteLine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : const Color(0xFF26351E);
    final bodyColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : const Color(0xFF282828);
    final tileBg = theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHighest
        : const Color(0xFFFAFAFA);
    final unavailable = quoteLine != null && !quoteLine!.isAvailable;

    return Opacity(
      opacity: unavailable ? 0.55 : 1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 120,
              height: 80,
              color: tileBg,
              child: Image.network(
                item.img,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.restaurant_menu_outlined),
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
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    height: 1.3,
                    letterSpacing: 0.56,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  unavailable
                      ? '${item.qty} шт · недоступно'
                      : '${item.qty} шт · ${(quoteLine?.lineTotal ?? item.subtotal).formatRub()}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: unavailable
                        ? Theme.of(context).colorScheme.error
                        : bodyColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final onlyDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = onlyDigits.length > 11
        ? onlyDigits.substring(0, 11)
        : onlyDigits;
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
    final theme = Theme.of(context);
    final sheetBg = theme.brightness == Brightness.dark
        ? theme.colorScheme.surface
        : Colors.white;
    final titleColor = theme.colorScheme.onSurface;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        height: widget.desiredHeight,
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.only(
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
                    Expanded(
                      child: Text(
                        'ВЫБОР АДРЕСА',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          color: titleColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: titleColor.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_items.isEmpty)
                  const Expanded(child: Center(child: Text('Адресов пока нет')))
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
                              const Icon(
                                Icons.home_outlined,
                                size: 24,
                                color: orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.heading.isEmpty ? a.city : a.heading,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                        color: titleColor,
                                      ),
                                    ),
                                    Text(
                                      a.line,
                                      style: TextStyle(color: titleColor),
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
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddressesPage(),
                        ),
                      );
                      await _load();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
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
