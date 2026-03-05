import 'package:flutter/material.dart';
import '../services/address_service.dart';

class AddressController extends ChangeNotifier {
  AddressController._();
  static final instance = AddressController._();

  Map<String, dynamic>? _defaultAddress;

  String get displayText {
    if (_defaultAddress == null) return 'Select location';

    final city = _defaultAddress!['city'];
    final area = _defaultAddress!['area'];

    if (city != null && area != null) {
      return '$city, $area';
    }

    return city ?? area ?? 'Select location';
  }

  Future<void> loadDefaultAddress() async {
    final addresses = await AddressService().getAddresses();

    _defaultAddress =
        addresses.firstWhere(
          (a) => a['is_default'] == true,
          orElse: () => addresses.isNotEmpty ? addresses.first : {},
        );

    notifyListeners();
  }
}
