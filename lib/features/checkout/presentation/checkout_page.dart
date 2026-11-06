import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salmonz/core/money/money.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import 'package:salmonz/core/theme/app_colors.dart';
import 'package:salmonz/core/theme/app_spacing.dart';
import 'package:salmonz/data/models/models.dart';
import 'package:salmonz/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:salmonz/profile/addresses_page.dart';
import 'package:salmonz/utils/ru_phone_formatter.dart';
import 'package:salmonz/widgets/app_button.dart';
import 'package:salmonz/widgets/app_card.dart';
import 'package:salmonz/widgets/app_error_view.dart';
import 'package:salmonz/widgets/app_header.dart';
import 'package:salmonz/widgets/app_nav_bar.dart';
import 'package:salmonz/widgets/app_network_image.dart';
import 'package:salmonz/widgets/app_notice.dart';
import 'package:salmonz/widgets/app_root.dart';
import 'package:salmonz/widgets/cart.dart';
import 'package:salmonz/widgets/price_text.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CheckoutCubit()..load(),
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  const _CheckoutView();

  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> {
  late final TextEditingController _phoneCtr;
  late final TextEditingController _commentCtr;
  var _syncingPhone = false;

  @override
  void initState() {
    super.initState();
    _phoneCtr = TextEditingController(text: '+7 ');
    _commentCtr = TextEditingController();
  }

  @override
  void dispose() {
    _phoneCtr.dispose();
    _commentCtr.dispose();
    super.dispose();
  }

  void _syncControllers(CheckoutState state) {
    if (!_syncingPhone && _phoneCtr.text != state.phone) {
      _syncingPhone = true;
      _phoneCtr.value = TextEditingValue(
        text: state.phone,
        selection: TextSelection.collapsed(offset: state.phone.length),
      );
      _syncingPhone = false;
    }
    if (_commentCtr.text != state.comment) {
      _commentCtr.value = TextEditingValue(
        text: state.comment,
        selection: TextSelection.collapsed(offset: state.comment.length),
      );
    }
  }

  Future<void> _pickAddress(CheckoutCubit cubit) async {
    final selected = await showModalBottomSheet<AddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _AddressesSheet(
          initialSelectedId: cubit.state.selectedAddress?.id,
          initialItems: cubit.state.addresses,
        ),
      ),
    );
    if (selected != null) {
      cubit.selectAddress(selected);
    } else {
      await cubit.reloadAddresses();
    }
  }

  String _freeDeliveryText(OrderQuoteModel quote) {
    final threshold = Money.fromRubles(quote.freeDeliveryThreshold);
    if (quote.deliveryFee.minorUnits == 0) {
      return 'Доставка бесплатна (от ${threshold.formatRub()})';
    }
    final rem = threshold - quote.subtotal;
    if (rem.minorUnits > 0) {
      return 'Бесплатная доставка от ${threshold.formatRub()}. Осталось ${rem.formatRub()}';
    }
    return 'Бесплатная доставка от ${threshold.formatRub()}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return BlocConsumer<CheckoutCubit, CheckoutState>(
      listenWhen: (p, c) =>
          p.placedOrder?.id != c.placedOrder?.id ||
          p.submitError != c.submitError ||
          p.phone != c.phone ||
          (p.loading && !c.loading),
      listener: (context, state) {
        _syncControllers(state);
        final order = state.placedOrder;
        if (order != null) {
          AppNotice.success(
            context,
            'Заказ оформлен · ${order.total.formatRub()}',
          );
          context.read<CheckoutCubit>().consumePlacedOrder();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const AppRoot(initialTab: AppTab.orders),
            ),
            (r) => false,
          );
          return;
        }
        if (state.submitError != null && !state.submitting) {
          AppNotice.error(context, state.submitError!);
        }
      },
      builder: (context, state) {
        final cubit = context.read<CheckoutCubit>();
        final cart = cubit.cart;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          resizeToAvoidBottomInset: true,
          appBar: const AppHeader.nested(title: 'Оформление'),
          body: SafeArea(
            child: AppPageContainer.form(
              child: state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.only(
                              top: AppSpacing.sm,
                              bottom: AppSpacing.xl + bottomInset,
                            ),
                            children: [
                              _SectionCard(
                                title: 'Адрес',
                                child: state.selectedAddress == null
                                    ? AppButton(
                                        label: 'Выбрать адрес',
                                        variant: AppButtonVariant.secondary,
                                        onPressed: () => _pickAddress(cubit),
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            state
                                                    .selectedAddress!
                                                    .heading
                                                    .isEmpty
                                                ? state.selectedAddress!.city
                                                : state
                                                      .selectedAddress!
                                                      .heading,
                                            style: theme.textTheme.titleSmall,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            state.selectedAddress!.line,
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                _pickAddress(cubit),
                                            child: const Text('Изменить'),
                                          ),
                                        ],
                                      ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _SectionCard(
                                title: 'Телефон',
                                child: TextField(
                                  key: const Key('checkoutPhone'),
                                  controller: _phoneCtr,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    RuPhoneTextInputFormatter(),
                                  ],
                                  onChanged: cubit.setPhone,
                                  decoration: const InputDecoration(
                                    hintText: '+7 (900) 000-00-00',
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _SectionCard(
                                title: 'Комментарий',
                                child: TextField(
                                  controller: _commentCtr,
                                  maxLines: null,
                                  minLines: 2,
                                  onChanged: cubit.setComment,
                                  decoration: const InputDecoration(
                                    hintText: 'Комментарий к заказу',
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _SectionCard(
                                title: 'Товары',
                                child: AnimatedBuilder(
                                  animation: cart,
                                  builder: (_, __) {
                                    final items = cart.items;
                                    return Column(
                                      children: [
                                        for (final it in items) ...[
                                          _CheckoutLine(
                                            item: it,
                                            quoteLine: cubit.quoteLineFor(
                                              it.id,
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                        ],
                                        if (state.quote != null &&
                                            state
                                                .quote!
                                                .unavailableItems
                                                .isNotEmpty)
                                          Text(
                                            'Недоступно: ${state.quote!.unavailableItems.map((e) => e.productName).join(', ')}',
                                            style: TextStyle(
                                              color: theme.colorScheme.error,
                                            ),
                                          ),
                                        if (state.quoteError != null)
                                          AppErrorView(
                                            message: state.quoteError!,
                                            onRetry: cubit.fetchQuote,
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _SectionCard(
                                title: 'Итог',
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (state.quote != null) ...[
                                      _MoneyRow(
                                        label: 'Товары',
                                        value: state.quote!.subtotal
                                            .formatRub(),
                                      ),
                                      const SizedBox(height: 6),
                                      _MoneyRow(
                                        label: 'Доставка',
                                        value:
                                            state
                                                    .quote!
                                                    .deliveryFee
                                                    .minorUnits ==
                                                0
                                            ? 'Бесплатно'
                                            : state.quote!.deliveryFee
                                                  .formatRub(),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _freeDeliveryText(state.quote!),
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      const Divider(height: AppSpacing.lg),
                                    ],
                                    Row(
                                      children: [
                                        Text(
                                          'К оплате',
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        const Spacer(),
                                        if (state.quoteLoading &&
                                            state.quote == null)
                                          Text(
                                            '≈ ${cart.totalSum.formatRub()}',
                                            style: theme.textTheme.titleMedium,
                                          )
                                        else
                                          Text(
                                            key: const Key('quoteTotal'),
                                            (state.quote?.total ??
                                                    cart.totalSum)
                                                .formatRub(),
                                            style: theme.textTheme.titleLarge,
                                          ),
                                        if (state.quoteLoading &&
                                            state.quote != null) ...[
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
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            0,
                            AppSpacing.xs,
                            0,
                            AppSpacing.sm,
                          ),
                          child: AppButton(
                            key: const Key('checkoutCreateOrder'),
                            label: 'Заказать',
                            loading: state.submitting,
                            onPressed:
                                cart.items.isEmpty || state.quoteError != null
                                ? null
                                : cubit.submit,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}

class _CheckoutLine extends StatelessWidget {
  const _CheckoutLine({required this.item, this.quoteLine});
  final CartItem item;
  final OrderQuoteLineModel? quoteLine;

  @override
  Widget build(BuildContext context) {
    final unavailable = quoteLine != null && !quoteLine!.isAvailable;
    final theme = Theme.of(context);
    return Opacity(
      opacity: unavailable ? 0.55 : 1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: AppNetworkImage(
              url: item.img.isEmpty ? null : item.img,
              kind: AppImageKind.dish,
              borderRadius: AppRadii.smAll,
              memCacheWidth: 160,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  unavailable
                      ? '${item.qty} шт · недоступно'
                      : '${item.price.formatRub()} × ${item.qty}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: unavailable ? theme.colorScheme.error : null,
                  ),
                ),
              ],
            ),
          ),
          PriceText(quoteLine?.lineTotal ?? item.subtotal),
        ],
      ),
    );
  }
}

class _AddressesSheet extends StatefulWidget {
  const _AddressesSheet({this.initialSelectedId, this.initialItems = const []});

  final String? initialSelectedId;
  final List<AddressModel> initialItems;

  @override
  State<_AddressesSheet> createState() => _AddressesSheetState();
}

class _AddressesSheetState extends State<_AddressesSheet> {
  late List<AddressModel> _items = List.of(widget.initialItems);
  late bool _loading = widget.initialItems.isEmpty;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialSelectedId;
    if (_items.isEmpty) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final cubit = context.read<CheckoutCubit>();
      await cubit.reloadAddresses();
      if (!mounted) return;
      final fresh = cubit.state.addresses;
      setState(() {
        _items = fresh;
        _loading = false;
        _selectedId ??= _items.isEmpty
            ? null
            : _items
                  .firstWhere((a) => a.isDefault, orElse: () => _items.first)
                  .id;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxH = MediaQuery.sizeOf(context).height * 0.72;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: MediaQuery.viewInsetsOf(context),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Material(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.xl),
            ),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Адрес доставки',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Text('Адресов пока нет'),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.xs),
                          itemBuilder: (_, i) {
                            final a = _items[i];
                            final selected = a.id == _selectedId;
                            return Material(
                              color: selected
                                  ? AppColors.orangeSoft
                                  : theme.colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.35),
                              borderRadius: AppRadii.mdAll,
                              child: InkWell(
                                borderRadius: AppRadii.mdAll,
                                onTap: () => Navigator.pop(context, a),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  child: Row(
                                    children: [
                                      Icon(
                                        selected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        color: AppColors.orange,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              a.heading.isEmpty
                                                  ? a.city
                                                  : a.heading,
                                              style: theme.textTheme.titleSmall,
                                            ),
                                            Text(
                                              a.line,
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: 'Управлять адресами',
                      variant: AppButtonVariant.secondary,
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddressesPage(),
                          ),
                        );
                        await _load();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
