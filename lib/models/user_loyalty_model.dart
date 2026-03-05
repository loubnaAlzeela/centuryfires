class UserLoyaltyModel {
  final String tier;
  final int points;
  final int orders;
  final int nextTierPoints;

  UserLoyaltyModel({
    required this.tier,
    required this.points,
    required this.orders,
    required this.nextTierPoints,
  });

  factory UserLoyaltyModel.fromMap(Map<String, dynamic> map) {
    return UserLoyaltyModel(
      tier: map['loyalty_tiers']['name'],
      points: map['points'],
      orders: map['total_orders'],
      nextTierPoints: map['loyalty_tiers']['min_points'],
    );
  }
}