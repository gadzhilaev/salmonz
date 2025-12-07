import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supa = Supabase.instance.client;

class AdminOrderDetailsPage extends StatefulWidget {
  const AdminOrderDetailsPage({super.key, required this.orderId});
  final int orderId;

  @override
  State<AdminOrderDetailsPage> createState() => _AdminOrderDetailsPageState();
}

class _AdminOrderDetailsPageState extends State<AdminOrderDetailsPage> {
  late Future<_Vm> _future;

  // стили (совпадают с остальными админ-экранами)
  static const bg = Color(0xFFFFFFFF);
  static const arrowColor = Color(0xFFCDCDCD);
  static const titleDark = Color(0xFF26351E);

  static const double hLogo = 62;
  static const double ls24  = 0.96; // 4% от 24
  static const double ls20  = 0.8;  // 4% от 20

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Vm> _load() async {
    // сам заказ (+ user_id)
    final row = await supa
        .from('orders')
        .select(
        'id, user_id, created_at, product_list, value_list, price_list, '
            'summ, address, phone, comment'
    )
        .eq('id', widget.orderId)
        .maybeSingle();

    if (row == null) throw Exception('Заказ не найден');

    final userId     = row['user_id'] as String?;
    final createdAt  = DateTime.parse(row['created_at'] as String);
    final productIds = (row['product_list'] as List).map((e) => (e as num).toInt()).toList();
    final qtyList    = (row['value_list']   as List).map((e) => (e as num).toInt()).toList();
    final priceList  = (row['price_list']   as List).map((e) => (e as num).toDouble()).toList();
    final total      = (row['summ'] as num).toDouble();
    final address    = (row['address'] ?? '') as String;
    final phone      = (row['phone']   ?? '') as String;
    final comment    = (row['comment'] ?? '') as String;

    // продукты
    final prows = await supa
        .from('products')
        .select('id, name, img, amount')
        .inFilter('id', productIds);

    final byId = <int, _Prod>{};
    for (final p in (prows as List)) {
      byId[(p['id'] as num).toInt()] = _Prod(
        id: (p['id'] as num).toInt(),
        name: (p['name'] ?? '') as String,
        img:  (p['img']  ?? '') as String,
        amount: (p['amount'] as num?)?.toInt() ?? 1,
      );
    }
    final items = <_OrderItem>[];
    for (int i = 0; i < productIds.length; i++) {
      final prod = byId[productIds[i]];
      if (prod == null) continue;
      final qty   = i < qtyList.length    ? qtyList[i]    : 1;
      final price = i < priceList.length  ? priceList[i]  : 0.0;
      items.add(_OrderItem(prod: prod, qty: qty, price: price));
    }

    // пользователь
    _User? user;
    if (userId != null) {
      final u = await supa
          .from('user')
          .select('id,name,email,img,birthdate')
          .eq('id', userId)
          .maybeSingle();
      if (u != null) {
        DateTime? bd;
        final raw = u['birthdate'];
        if (raw is String && raw.isNotEmpty) bd = DateTime.tryParse(raw);
        user = _User(
          id: u['id'] as String,
          name: (u['name'] ?? '') as String,
          email: (u['email'] ?? '') as String,
          img: (u['img'] ?? '') as String,
          birthdate: bd,
        );
      }
    }

    return _Vm(
      id: widget.orderId,
      createdAt: createdAt,
      items: items,
      total: total,
      address: address,
      phone: _formatPhone(phone),
      comment: comment,
      user: user,
    );
  }

  static String _two(int n) => n < 10 ? '0$n' : '$n';
  static String _fmtDate(DateTime dt) {
    final d = dt.toLocal();
    return '${_two(d.day)}.${_two(d.month)}.${d.year} ${_two(d.hour)}:${_two(d.minute)}';
  }

  static String _formatPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return raw;
    var d = digits;
    if (d.startsWith('8')) d = '7${d.substring(1)}';
    if (!d.startsWith('7')) d = '7$d';
    final b = StringBuffer('+7 ');
    final body = d.substring(1);
    if (body.isNotEmpty) b..write('(')..write(body.substring(0, body.length.clamp(0, 3)));
    if (body.length >= 3) b.write(') ');
    if (body.length > 3)  b.write(body.substring(3, body.length.clamp(3, 6)));
    if (body.length >= 6) b.write('-');
    if (body.length > 6)  b.write(body.substring(6, body.length.clamp(6, 8)));
    if (body.length >= 8) b.write('-');
    if (body.length > 8)  b.write(body.substring(8, body.length.clamp(8, 10)));
    return b.toString();
  }

  static String _price(double v) =>
      (v == v.roundToDouble()) ? v.toInt().toString() : v.toStringAsFixed(2).replaceAll(RegExp(r'\.0+$'), '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              // APPBAR как в админке
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
                      child: Image.asset('assets/icon/logo_salmonz_small.png',
                          width: 80, height: 62, fit: BoxFit.contain),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: FutureBuilder<_Vm>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Ошибка: ${snap.error}'));
                    }
                    final vm = snap.data!;

                    return ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          'ЗАКАЗ #${vm.id}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            height: 1.0,
                            letterSpacing: ls24,
                            color: titleDark,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // позиции
                        for (final it in vm.items) ...[
                          _OrderItemTile(prod: it.prod, qty: it.qty, price: it.price),
                          const SizedBox(height: 16),
                        ],

                        const SizedBox(height: 24),

                        // ИТОГО
                        Row(
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
                              '${_price(vm.total)} ₽',
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

                        // ДОСТАВКА
                        const Text(
                          'ДОСТАВКА',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            height: 1.0,
                            letterSpacing: ls20,
                            color: titleDark,
                          ),
                        ),
                        const SizedBox(height: 16),

                        const _SmallLabel('Адрес доставки'),
                        const SizedBox(height: 12),
                        Text(vm.address, style: const TextStyle(
                          fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 18, height: 1.0,
                        )),

                        const SizedBox(height: 20),

                        const _SmallLabel('Номер телефона'),
                        const SizedBox(height: 12),
                        Text(vm.phone, style: const TextStyle(
                          fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 18, height: 1.0,
                        )),

                        const SizedBox(height: 20),

                        const _SmallLabel('Комментарий'),
                        const SizedBox(height: 12),
                        Text(vm.comment.isEmpty ? '—' : vm.comment, style: const TextStyle(
                          fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 18, height: 1.0,
                        )),

                        // НОВОЕ: Дата заказа
                        const SizedBox(height: 20),
                        const _SmallLabel('Дата заказа'),
                        const SizedBox(height: 12),
                        Text(_fmtDate(vm.createdAt), style: const TextStyle(
                          fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 18, height: 1.0,
                        )),

                        // НОВОЕ: Пользователь
                        const SizedBox(height: 40),
                        const Text(
                          'ПОЛЬЗОВАТЕЛЬ',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w900, // Black
                            fontSize: 20,
                            height: 1.0,
                            letterSpacing: ls20, // 4%
                            color: titleDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (vm.user != null)
                          _UserTile(user: vm.user!)
                        else
                          const Text('Нет данных о пользователе',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
                        const SizedBox(height: 24),
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

/* ---- виджеты ---- */

class _SmallLabel extends StatelessWidget {
  const _SmallLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(
      fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 13, height: 1.0, color: Color(0xFF7E7E7E),
    ));
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.prod, required this.qty, required this.price});
  final _Prod prod; final int qty; final double price;

  static const titleDark = Color(0xFF26351E);
  static const gray2828 = Color(0xFF282828);
  static const tileBg   = Color(0xFFFAFAFA);

  static String _price(double v) =>
      (v == v.roundToDouble()) ? v.toInt().toString() : v.toStringAsFixed(2).replaceAll(RegExp(r'\.0+$'), '');

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 120, height: 80, color: tileBg,
            child: Image.network(prod.img, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(prod.name.toUpperCase(),
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter', fontWeight: FontWeight.w900, fontSize: 14,
                  height: 1.3, letterSpacing: 0.56, color: titleDark,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('${prod.amount} шт × $qty', style: const TextStyle(
                    fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 14, height: 22/14, color: gray2828,
                  )),
                  const SizedBox(width: 16),
                  Text('${_price(price * qty)} ₽', style: const TextStyle(
                    fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 16, height: 1.0, color: Colors.black,
                  )),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// мини-карточка пользователя — размеры и стиль как в users_list_page.dart
class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});
  final _User user;

  static const textDark = Color(0xFF282828);
  static const textGray = Color(0xFF717171);
  static const avatarBg = Color(0xFFEEEEEE);

  @override
  Widget build(BuildContext context) {
    String bd = 'не указана';
    if (user.birthdate != null) {
      String two(int n) => n < 10 ? '0$n' : '$n';
      final d = user.birthdate!;
      bd = '${two(d.day)}.${two(d.month)}.${d.year}';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 80, height: 80, color: avatarBg,
            child: (user.img.isNotEmpty)
                ? Image.network(user.img, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.person))
                : const Icon(Icons.person),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (user.name.isEmpty ? 'БЕЗ ИМЕНИ' : user.name.toUpperCase()),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.0,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.mail_outline, size: 12, color: textGray),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        user.email.isEmpty ? '—' : user.email,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                          height: 17/10,
                          color: textGray,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 12, color: textGray),
                    const SizedBox(width: 4),
                    Text(
                      bd,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                        height: 17/10,
                        color: textGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/* ---- модели ---- */
class _User {
  _User({required this.id, required this.name, required this.email, required this.img, required this.birthdate});
  final String id; final String name; final String email; final String img; final DateTime? birthdate;
}
class _Prod { _Prod({required this.id, required this.name, required this.img, required this.amount});
final int id; final String name; final String img; final int amount; }
class _OrderItem { _OrderItem({required this.prod, required this.qty, required this.price});
final _Prod prod; final int qty; final double price; }
class _Vm {
  _Vm({
    required this.id,
    required this.createdAt,
    required this.items,
    required this.total,
    required this.address,
    required this.phone,
    required this.comment,
    required this.user,
  });
  final int id; final DateTime createdAt; final List<_OrderItem> items; final double total;
  final String address; final String phone; final String comment; final _User? user;
}