import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  static const String entitlementID = 'pro';

  static Future<bool> isUserPremium() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[entitlementID]?.isActive ?? false;
    } catch (e) {
      return false;
    }
  }
}