import '../../core/money/money.dart';

Map<String, dynamic> asMap(Object? raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> asMapList(Object? raw) {
  if (raw is! List) return const [];
  return raw.map((e) => asMap(e)).toList();
}

String? asString(Object? v) => v?.toString();

bool asBool(Object? v, {bool fallback = false}) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    return s == 'true' || s == 't' || s == '1';
  }
  return fallback;
}

int asInt(Object? v, {int fallback = 0}) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

Money asMoney(Object? v) => Money.parse(v);

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.avatarKey,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String name;
  final String role;
  final String? phone;
  final String? avatarKey;
  final String? avatarUrl;

  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: asString(json['id']) ?? '',
        email: asString(json['email']) ?? '',
        name: asString(json['name']) ?? '',
        role: asString(json['role']) ?? 'USER',
        phone: asString(json['phone']),
        avatarKey: asString(json['avatarKey']),
        avatarUrl: asString(json['avatarUrl']),
      );

  UserModel copyWith({
    String? name,
    String? phone,
    String? avatarUrl,
    String? avatarKey,
  }) =>
      UserModel(
        id: id,
        email: email,
        name: name ?? this.name,
        role: role,
        phone: phone ?? this.phone,
        avatarKey: avatarKey ?? this.avatarKey,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );
}

class AuthResult {
  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final UserModel user;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        accessToken: asString(json['accessToken']) ?? '',
        refreshToken: asString(json['refreshToken']) ?? '',
        user: UserModel.fromJson(asMap(json['user'])),
      );
}

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.imageKey,
    this.imageUrl,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String slug;
  final String? imageKey;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        slug: asString(json['slug']) ?? '',
        imageKey: asString(json['imageKey']),
        imageUrl: asString(json['imageUrl']),
        sortOrder: asInt(json['sortOrder']),
        isActive: asBool(json['isActive'], fallback: true),
      );
}

class ProductModel {
  const ProductModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    this.description = '',
    this.oldPrice,
    this.imageKey,
    this.imageUrl,
    this.weight,
    this.isAvailable = true,
    this.sortOrder = 0,
    this.categoryName,
    this.categorySlug,
  });

  final String id;
  final String categoryId;
  final String name;
  final String description;
  final Money price;
  final Money? oldPrice;
  final String? imageKey;
  final String? imageUrl;
  final int? weight;
  final bool isAvailable;
  final int sortOrder;
  final String? categoryName;
  final String? categorySlug;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final cat = asMap(json['category']);
    return ProductModel(
      id: asString(json['id']) ?? '',
      categoryId: asString(json['categoryId']) ?? asString(cat['id']) ?? '',
      name: asString(json['name']) ?? '',
      description: asString(json['description']) ?? '',
      price: asMoney(json['price']),
      oldPrice: json['oldPrice'] == null ? null : asMoney(json['oldPrice']),
      imageKey: asString(json['imageKey']),
      imageUrl: asString(json['imageUrl']),
      weight: json['weight'] == null ? null : asInt(json['weight']),
      isAvailable: asBool(json['isAvailable'], fallback: true),
      sortOrder: asInt(json['sortOrder']),
      categoryName: asString(cat['name']),
      categorySlug: asString(cat['slug']),
    );
  }
}

class PromotionModel {
  const PromotionModel({
    required this.id,
    required this.title,
    required this.imageKey,
    this.description,
    this.imageUrl,
    this.isActive = true,
    this.sortOrder = 0,
  });

  final String id;
  final String title;
  final String? description;
  final String imageKey;
  final String? imageUrl;
  final bool isActive;
  final int sortOrder;

  factory PromotionModel.fromJson(Map<String, dynamic> json) => PromotionModel(
        id: asString(json['id']) ?? '',
        title: asString(json['title']) ?? '',
        description: asString(json['description']),
        imageKey: asString(json['imageKey']) ?? '',
        imageUrl: asString(json['imageUrl']),
        isActive: asBool(json['isActive'], fallback: true),
        sortOrder: asInt(json['sortOrder']),
      );
}

class AddressModel {
  const AddressModel({
    required this.id,
    required this.city,
    required this.street,
    required this.house,
    this.title,
    this.apartment,
    this.entrance,
    this.floor,
    this.comment,
    this.isDefault = false,
  });

  final String id;
  final String? title;
  final String city;
  final String street;
  final String house;
  final String? apartment;
  final String? entrance;
  final String? floor;
  final String? comment;
  final bool isDefault;

  String get line => [
        street,
        house,
        if (apartment != null && apartment!.isNotEmpty) 'кв. $apartment',
      ].where((e) => e.trim().isNotEmpty).join(', ');

  String get heading => [
        if (title != null && title!.trim().isNotEmpty) title!,
        city,
      ].where((e) => e.trim().isNotEmpty).join(', ');

  String get fullLine => [city, line].where((e) => e.trim().isNotEmpty).join(', ');

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: asString(json['id']) ?? '',
        title: asString(json['title']),
        city: asString(json['city']) ?? '',
        street: asString(json['street']) ?? '',
        house: asString(json['house']) ?? '',
        apartment: asString(json['apartment']),
        entrance: asString(json['entrance']),
        floor: asString(json['floor']),
        comment: asString(json['comment']),
        isDefault: asBool(json['isDefault']),
      );
}

class OrderItemModel {
  const OrderItemModel({
    required this.id,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    this.productId,
  });

  final String id;
  final String? productId;
  final String productName;
  final Money unitPrice;
  final int quantity;
  final Money lineTotal;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        id: asString(json['id']) ?? '',
        productId: asString(json['productId']),
        productName: asString(json['productNameSnapshot']) ??
            asString(json['productName']) ??
            '',
        unitPrice: asMoney(json['unitPrice']),
        quantity: asInt(json['quantity'], fallback: 1),
        lineTotal: asMoney(json['lineTotal']),
      );
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.publicNumber,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.phone,
    required this.createdAt,
    required this.items,
    this.comment,
    this.addressSnapshot,
  });

  final String id;
  final String publicNumber;
  final String status;
  final Money subtotal;
  final Money deliveryFee;
  final Money total;
  final String phone;
  final String? comment;
  final DateTime createdAt;
  final List<OrderItemModel> items;
  final Map<String, dynamic>? addressSnapshot;

  String get addressText {
    final snap = addressSnapshot;
    if (snap == null || snap.isEmpty) return '';
    final parts = [
      asString(snap['city']),
      asString(snap['street']),
      asString(snap['house']),
      if ((asString(snap['apartment']) ?? '').isNotEmpty)
        'кв. ${snap['apartment']}',
    ].whereType<String>().where((e) => e.trim().isNotEmpty);
    return parts.join(', ');
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: asString(json['id']) ?? '',
        publicNumber: asString(json['publicNumber']) ?? '',
        status: asString(json['status']) ?? 'NEW',
        subtotal: asMoney(json['subtotal']),
        deliveryFee: asMoney(json['deliveryFee']),
        total: asMoney(json['total']),
        phone: asString(json['phone']) ?? '',
        comment: asString(json['comment']),
        createdAt: DateTime.tryParse(asString(json['createdAt']) ?? '') ??
            DateTime.now(),
        items: asMapList(json['items']).map(OrderItemModel.fromJson).toList(),
        addressSnapshot: json['addressSnapshot'] is Map
            ? asMap(json['addressSnapshot'])
            : null,
      );
}

class SupportMessageModel {
  const SupportMessageModel({
    required this.id,
    required this.message,
    required this.status,
    required this.createdAt,
    this.subject,
  });

  final String id;
  final String? subject;
  final String message;
  final String status;
  final DateTime createdAt;

  factory SupportMessageModel.fromJson(Map<String, dynamic> json) =>
      SupportMessageModel(
        id: asString(json['id']) ?? '',
        subject: asString(json['subject']),
        message: asString(json['message']) ?? '',
        status: asString(json['status']) ?? 'NEW',
        createdAt: DateTime.tryParse(asString(json['createdAt']) ?? '') ??
            DateTime.now(),
      );
}

class Paginated<T> {
  const Paginated({required this.data, required this.page, required this.total});

  final List<T> data;
  final int page;
  final int total;

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) map,
  ) {
    final meta = asMap(json['meta']);
    return Paginated(
      data: asMapList(json['data']).map(map).toList(),
      page: asInt(meta['page'], fallback: 1),
      total: asInt(meta['total']),
    );
  }
}

class UploadResult {
  const UploadResult({required this.key, this.url});

  final String key;
  final String? url;

  factory UploadResult.fromJson(Map<String, dynamic> json) => UploadResult(
        key: asString(json['key']) ?? '',
        url: asString(json['url']),
      );
}
