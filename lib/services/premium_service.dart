import 'package:purchases_flutter/purchases_flutter.dart';

class PremiumService {
  static Future<bool> isUserPremium() async {
    try {
      final purchaserInfo = await Purchases.getCustomerInfo();
      return purchaserInfo.entitlements.all['premium']?.isActive ?? false;
    } catch (e) {
      print("Error al verificar premium: $e");
      return false;
    }
  }
}
