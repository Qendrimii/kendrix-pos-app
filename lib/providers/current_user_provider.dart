import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

// State Notifier
class CurrentUserNotifier extends StateNotifier<Waiter?> {
  CurrentUserNotifier() : super(null);

  void login(Waiter waiter) {
    state = waiter;
  }

  void logout() {
    state = null;
  }
}

// Provider
final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, Waiter?>((ref) {
  return CurrentUserNotifier();
});
