class UserAddressModel {
  final String id;
  final String address;
  final bool isDefault;

  UserAddressModel({
    required this.id,
    required this.address,
    required this.isDefault,
  });

  factory UserAddressModel.fromMap(Map<String, dynamic> map) {
    return UserAddressModel(
      id: map['id'],
      address: map['street'] ?? '',
      isDefault: map['is_default'] ?? false,
    );
  }
}
