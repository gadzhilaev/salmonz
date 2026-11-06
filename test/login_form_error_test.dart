import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salmonz/core/config/app_config.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/network/api_exception.dart';
import 'package:salmonz/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salmonz/features/auth/presentation/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailingAuthCubit extends AuthCubit {
  _FailingAuthCubit(this._error) : super();

  final ApiException _error;

  @override
  Future<void> login({required String email, required String password}) async {
    emit(const AuthLoading());
    emit(AuthFailure(_error.userMessage));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppServices.reset();
    AppServices.init(config: AppConfig.fromEnvironment());
  });

  tearDown(() {
    AppServices.reset();
  });

  testWidgets('wrong password shows inline form error, not SnackBar', (
    tester,
  ) async {
    final cubit = _FailingAuthCubit(
      const ApiException(
        message: ApiException.invalidCredentialsMessage,
        statusCode: 401,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthCubit>.value(value: cubit, child: const Login()),
      ),
    );

    await tester.enterText(find.byKey(const Key('loginEmail')), 't@test.ru');
    await tester.enterText(find.byKey(const Key('loginPassword')), 'bad');
    await tester.tap(find.byKey(const Key('loginSubmit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('loginFormError')), findsOneWidget);
    expect(find.text(ApiException.invalidCredentialsMessage), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    // Email preserved
    expect(find.text('t@test.ru'), findsOneWidget);

    await cubit.close();
  });

  testWidgets('network error shows retry on login form', (tester) async {
    final cubit = _FailingAuthCubit(
      const ApiException(
        message: ApiException.connectionMessage,
        isNetworkError: true,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthCubit>.value(value: cubit, child: const Login()),
      ),
    );

    await tester.enterText(find.byKey(const Key('loginEmail')), 't@test.ru');
    await tester.enterText(find.byKey(const Key('loginPassword')), '12345678');
    await tester.tap(find.byKey(const Key('loginSubmit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(ApiException.connectionMessage), findsOneWidget);
    expect(find.byKey(const Key('loginRetry')), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await cubit.close();
  });

  testWidgets('empty fields show inline validation without SnackBar', (
    tester,
  ) async {
    final cubit = AuthCubit();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthCubit>.value(value: cubit, child: const Login()),
      ),
    );

    await tester.tap(find.byKey(const Key('loginSubmit')));
    await tester.pump();

    expect(find.text('Введите почту и пароль'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    await cubit.close();
  });
}
