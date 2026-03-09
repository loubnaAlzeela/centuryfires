import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavedCardsService {
  static const String _key = 'user_saved_cards';

  static Future<List<Map<String, dynamic>>> getSavedCards() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cardsJson = prefs.getString(_key);
    if (cardsJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(cardsJson);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCard(Map<String, dynamic> cardData) async {
    final cards = await getSavedCards();

    // Check if card with same number already exists
    final bool exists = cards.any((c) => c['number'] == cardData['number']);
    if (!exists) {
      cards.add(cardData);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(cards));
    }
  }

  static Future<void> removeCard(String cardNumber) async {
    final cards = await getSavedCards();
    cards.removeWhere((c) => c['number'] == cardNumber);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(cards));
  }
}
