import 'package:flutter/foundation.dart';

class SubscriptionRefreshNotifier extends ChangeNotifier {
  void markUpdated() {
    notifyListeners();
  }
}
