import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/app_services.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models.dart';
import '../../../../utils/ru_phone_formatter.dart';
import '../../../../widgets/cart.dart';

class CheckoutState extends Equatable {
  const CheckoutState({
    this.selectedAddress,
    this.phone = '+7 ',
    this.comment = '',
    this.quote,
    this.quoteLoading = false,
    this.quoteError,
    this.submitting = false,
    this.submitError,
    this.placedOrder,
    this.loading = true,
    this.addresses = const [],
  });

  final AddressModel? selectedAddress;
  final String phone;
  final String comment;
  final OrderQuoteModel? quote;
  final bool quoteLoading;
  final String? quoteError;
  final bool submitting;
  final String? submitError;
  final OrderModel? placedOrder;
  final bool loading;
  final List<AddressModel> addresses;

  CheckoutState copyWith({
    AddressModel? selectedAddress,
    bool clearAddress = false,
    String? phone,
    String? comment,
    OrderQuoteModel? quote,
    bool clearQuote = false,
    bool? quoteLoading,
    String? quoteError,
    bool clearQuoteError = false,
    bool? submitting,
    String? submitError,
    bool clearSubmitError = false,
    OrderModel? placedOrder,
    bool clearPlacedOrder = false,
    bool? loading,
    List<AddressModel>? addresses,
  }) {
    return CheckoutState(
      selectedAddress: clearAddress
          ? null
          : (selectedAddress ?? this.selectedAddress),
      phone: phone ?? this.phone,
      comment: comment ?? this.comment,
      quote: clearQuote ? null : (quote ?? this.quote),
      quoteLoading: quoteLoading ?? this.quoteLoading,
      quoteError: clearQuoteError ? null : (quoteError ?? this.quoteError),
      submitting: submitting ?? this.submitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      placedOrder: clearPlacedOrder ? null : (placedOrder ?? this.placedOrder),
      loading: loading ?? this.loading,
      addresses: addresses ?? this.addresses,
    );
  }

  @override
  List<Object?> get props => [
    selectedAddress?.id,
    phone,
    comment,
    quote?.total.minorUnits,
    quoteLoading,
    quoteError,
    submitting,
    submitError,
    placedOrder?.id,
    loading,
    addresses.map((a) => a.id).join(','),
  ];
}

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit({AppServices? services, Cart? cart})
    : _services = services,
      _cart = cart ?? Cart.instance,
      super(const CheckoutState()) {
    _cart.addListener(_onCartChanged);
  }

  final AppServices? _services;
  final Cart _cart;
  AppServices get _s => _services ?? AppServices.instance;

  String? _idempotencyKey;
  int _quoteGen = 0;
  Timer? _quoteDebounce;
  bool _submitLock = false;

  Cart get cart => _cart;

  void _onCartChanged() {
    if (isClosed) return;
    scheduleQuote();
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearSubmitError: true));
    try {
      final addresses = await _s.addresses.list();
      final me = await _s.profile.getMe();
      final rawPhone = me.phone?.trim();
      final phone = (rawPhone != null && rawPhone.isNotEmpty)
          ? RuPhoneFormatter.pretty(rawPhone)
          : state.phone;
      AddressModel? selected = state.selectedAddress;
      if (selected == null && addresses.isNotEmpty) {
        selected = addresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => addresses.first,
        );
      }
      emit(
        state.copyWith(
          addresses: addresses,
          selectedAddress: selected,
          phone: phone,
          loading: false,
        ),
      );
      scheduleQuote();
    } on ApiException catch (e) {
      emit(state.copyWith(loading: false, submitError: e.userMessage));
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          submitError: ApiException.userMessageFrom(e),
        ),
      );
    }
  }

  Future<void> reloadAddresses({String? preferId}) async {
    try {
      final addresses = await _s.addresses.list();
      AddressModel? selected = state.selectedAddress;
      if (preferId != null) {
        for (final a in addresses) {
          if (a.id == preferId) selected = a;
        }
      }
      selected ??= addresses.isEmpty
          ? null
          : addresses.firstWhere(
              (a) => a.isDefault,
              orElse: () => addresses.first,
            );
      emit(
        state.copyWith(
          addresses: addresses,
          selectedAddress: selected,
          clearAddress: selected == null,
        ),
      );
    } catch (_) {
      // keep previous selection
    }
  }

  void selectAddress(AddressModel address) {
    emit(state.copyWith(selectedAddress: address));
  }

  void setPhone(String phone) => emit(state.copyWith(phone: phone));

  void setComment(String comment) => emit(state.copyWith(comment: comment));

  void scheduleQuote() {
    _quoteDebounce?.cancel();
    _quoteDebounce = Timer(const Duration(milliseconds: 300), fetchQuote);
  }

  Future<void> fetchQuote() async {
    if (_cart.items.isEmpty) {
      emit(
        state.copyWith(
          clearQuote: true,
          quoteLoading: false,
          clearQuoteError: true,
        ),
      );
      return;
    }
    final gen = ++_quoteGen;
    emit(state.copyWith(quoteLoading: true, clearQuoteError: true));
    try {
      final quote = await _s.orders.quote(
        items: _cart.items
            .map((i) => (productId: i.id, quantity: i.qty))
            .toList(),
      );
      if (isClosed || gen != _quoteGen) return;
      emit(state.copyWith(quote: quote, quoteLoading: false));
    } on ApiException catch (e) {
      if (isClosed || gen != _quoteGen) return;
      emit(state.copyWith(quoteLoading: false, quoteError: e.userMessage));
    } catch (e) {
      if (isClosed || gen != _quoteGen) return;
      emit(
        state.copyWith(
          quoteLoading: false,
          quoteError: ApiException.userMessageFrom(e),
        ),
      );
    }
  }

  String? validateBeforeSubmit() {
    final phone = state.phone.trim();
    if (state.selectedAddress == null) {
      return 'Выберите адрес доставки';
    }
    if (!phone.startsWith('+7') ||
        phone.replaceAll(RegExp(r'\D'), '').length < 11) {
      return 'Введите телефон в формате +7 …';
    }
    if (_cart.items.isEmpty) return 'Корзина пуста';
    if (state.quoteError != null) {
      return 'Дождитесь успешного расчёта заказа';
    }
    final unavailable = state.quote?.unavailableItems ?? const [];
    if (unavailable.isNotEmpty) {
      return 'В корзине есть недоступные товары';
    }
    return null;
  }

  Future<void> submit() async {
    if (_submitLock || state.submitting) return;
    final validation = validateBeforeSubmit();
    if (validation != null) {
      emit(state.copyWith(submitError: validation));
      return;
    }

    _submitLock = true;
    _idempotencyKey ??= const Uuid().v4();
    emit(state.copyWith(submitting: true, clearSubmitError: true));
    try {
      final digits = state.phone.replaceAll(RegExp(r'\D'), '');
      final order = await _s.orders.create(
        addressId: state.selectedAddress!.id,
        phone: '+$digits',
        comment: state.comment.trim().isEmpty ? null : state.comment.trim(),
        items: _cart.items
            .map((i) => (productId: i.id, quantity: i.qty))
            .toList(),
        idempotencyKey: _idempotencyKey!,
      );
      _idempotencyKey = null;
      await _cart.clear();
      emit(
        state.copyWith(submitting: false, placedOrder: order, clearQuote: true),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(submitting: false, submitError: e.userMessage));
    } catch (e) {
      emit(
        state.copyWith(
          submitting: false,
          submitError: ApiException.userMessageFrom(e),
        ),
      );
    } finally {
      _submitLock = false;
    }
  }

  void consumePlacedOrder() {
    emit(state.copyWith(clearPlacedOrder: true));
  }

  OrderQuoteLineModel? quoteLineFor(String productId) {
    final quote = state.quote;
    if (quote == null) return null;
    for (final line in quote.items) {
      if (line.productId == productId) return line;
    }
    return null;
  }

  @override
  Future<void> close() {
    _quoteDebounce?.cancel();
    _cart.removeListener(_onCartChanged);
    return super.close();
  }
}
