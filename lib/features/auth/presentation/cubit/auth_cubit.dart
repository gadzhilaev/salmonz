import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_services.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final UserModel user;
  @override
  List<Object?> get props => [user.id, user.email, user.role];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthFailure extends AuthState {
  const AuthFailure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({AppServices? services})
    : _services = services,
      super(const AuthInitial());

  final AppServices? _services;
  AppServices get _s => _services ?? AppServices.instance;

  Future<void> restore() async {
    emit(const AuthLoading());
    try {
      final user = await _s.auth.restoreSession();
      if (user == null) {
        emit(const AuthUnauthenticated());
      } else {
        emit(AuthAuthenticated(user));
      }
    } on ApiException catch (e) {
      // Missing / expired session is expected — not a toast-worthy failure.
      if (e.isNetwork) {
        emit(AuthFailure(e.userMessage));
      }
      emit(const AuthUnauthenticated());
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(const AuthLoading());
    try {
      final result = await _s.auth.login(email: email, password: password);
      emit(AuthAuthenticated(result.user));
    } on ApiException catch (e) {
      emit(AuthFailure(e.userMessage));
    } catch (_) {
      emit(const AuthFailure(ApiException.genericMessage));
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    emit(const AuthLoading());
    try {
      final result = await _s.auth.register(
        email: email,
        password: password,
        name: name,
      );
      emit(AuthAuthenticated(result.user));
    } on ApiException catch (e) {
      emit(AuthFailure(e.userMessage));
    } catch (_) {
      emit(const AuthFailure(ApiException.genericMessage));
    }
  }

  Future<void> logout() async {
    try {
      await _s.auth.logout();
    } catch (_) {
      // still clear local session
    }
    emit(const AuthUnauthenticated());
  }

  /// Sync from SplashGate after a single restoreSession() — no network.
  void emitAuthenticated(UserModel user) => emit(AuthAuthenticated(user));

  void emitUnauthenticated() => emit(const AuthUnauthenticated());
}
