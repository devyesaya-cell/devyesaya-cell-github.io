import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SystemMode {
  spot,
  crumbling,
  maintenance,
}

class AuthState {
  final String operatorName;
  final String contractorName;
  final SystemMode mode;
  final bool isAuthenticated;

  const AuthState({
    this.operatorName = 'Operator EGS #08',
    this.contractorName = 'PT Pamapersada',
    this.mode = SystemMode.crumbling,
    this.isAuthenticated = true,
  });

  AuthState copyWith({
    String? operatorName,
    String? contractorName,
    SystemMode? mode,
    bool? isAuthenticated,
  }) {
    return AuthState(
      operatorName: operatorName ?? this.operatorName,
      contractorName: contractorName ?? this.contractorName,
      mode: mode ?? this.mode,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  void setMode(SystemMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setOperator(String name, String contractor) {
    state = state.copyWith(operatorName: name, contractorName: contractor);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
