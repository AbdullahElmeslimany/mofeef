import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/failure.dart';
import 'data/models/user_model.dart';
import 'data/repositories/auth_repository.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.errorMessage,
  });

  String? get userName => user?.displayName;
  String? get userEmail => user?.email;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final token = await _repository.getSavedToken();
    final savedUser = await _repository.getSavedUser();

    if (!mounted) return;
    if (savedUser != null) {
      state = state.copyWith(isAuthenticated: true, user: savedUser);
    } else if (token != null && token.isNotEmpty) {
      state = state.copyWith(isAuthenticated: true);
    }

    if (token != null && token.isNotEmpty) {
      _refreshProfile();
    }
  }

  Future<void> _refreshProfile() async {
    try {
      final profile = await _repository.getProfile();
      if (!mounted) return;
      if (profile.email.isNotEmpty && profile.id != 0) {
        state = state.copyWith(isAuthenticated: true, user: profile);
      }
    } catch (_) {}
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repository.login(email, password);
      UserModel finalUser = user;
      try {
        final profile = await _repository.getProfile();
        if (profile.email.isNotEmpty && profile.id != 0) {
          finalUser = profile;
        }
      } catch (_) {}

      if (!mounted) return true;
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: finalUser,
      );
      return true;
    } on Failure catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'تعذر تسجيل الدخول، يرجى المحاولة لاحقاً',
      );
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repository.register(data);
      UserModel finalUser = user;
      try {
        final profile = await _repository.getProfile();
        finalUser = profile;
      } catch (_) {}

      if (!mounted) return true;
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: finalUser,
      );
      return true;
    } on Failure catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    }
  }

  void updateUserState(UserModel user) {
    if (!mounted) return;
    state = state.copyWith(user: user);
    _repository.saveUser(user);
  }

  Future<void> logout() async {
    await _repository.logout();
    if (!mounted) return;
    state = const AuthState();
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.deleteAccount();
      if (!mounted) return false;
      state = const AuthState();
      return true;
    } on Failure catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'تعذر حذف الحساب، يرجى المحاولة لاحقاً',
      );
      return false;
    }
  }

  Future<String?> resendVerificationEmail(String email) async {
    try {
      return await _repository.resendVerificationEmail(email);
    } on Failure catch (e) {
      return e.message;
    } catch (_) {
      return 'تعذر إرسال رابط التحقق، يرجى المحاولة لاحقاً';
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
