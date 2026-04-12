import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../utils/l.dart';
import '../../services/saved_cards_service.dart';

class CardInputScreen extends StatefulWidget {
  const CardInputScreen({super.key});

  @override
  State<CardInputScreen> createState() => _CardInputScreenState();
}

class _CardInputScreenState extends State<CardInputScreen> {
  final _nameCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _monthCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _cvcCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showForm = false;
  List<Map<String, dynamic>> _savedCards = [];
  bool _isLoadingCards = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards = await SavedCardsService.getSavedCards();
    setState(() {
      _savedCards = cards;
      if (cards.isEmpty) {
        _showForm = true; // Show form immediately if no saved cards
      }
      _isLoadingCards = false;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    _cvcCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final cardData = {
      'name': _nameCtrl.text.trim(),
      'number': _numberCtrl.text.trim().replaceAll(' ', ''),
      'month': _monthCtrl.text.trim(),
      'year': _yearCtrl.text.trim(),
      'cvc': _cvcCtrl.text.trim(),
    };

    // حفظ البطاقة لاستخدامها مستقبلاً
    await SavedCardsService.saveCard(cardData);

    Navigator.pop(context, cardData);
  }

  void _useSavedCard(Map<String, dynamic> card) {
    Navigator.pop(context, card);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCards) {
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary(context)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(_showForm ? L.t('enter_card_details') : L.t('saved_cards')),
        backgroundColor: AppColors.card(context),
        leading: _showForm && _savedCards.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _showForm = false),
              )
            : null,
      ),
      body: _showForm ? _buildForm() : _buildSavedCardsList(),
    );
  }

  Widget _buildSavedCardsList() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ..._savedCards.map((card) {
          final number = card['number'] as String? ?? '';
          final maskedNum = number.length > 4
              ? '**** **** **** ${number.substring(number.length - 4)}'
              : '**** **** **** $number';

          return Card(
            color: AppColors.card(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Icon(
                Icons.credit_card,
                color: AppColors.primary(context),
                size: 32,
              ),
              title: Text(
                maskedNum,
                style: TextStyle(
                  color: AppColors.text(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                card['name'] ?? '',
                style: TextStyle(color: AppColors.textGrey(context)),
              ),
              onTap: () => _useSavedCard(card),
              trailing: IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: AppColors.error(context),
                ),
                onPressed: () async {
                  await SavedCardsService.removeCard(number);
                  _loadCards();
                },
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.card(context),
              foregroundColor: AppColors.primary(context),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.primary(context)),
              ),
            ),
            icon: const Icon(Icons.add),
            label: Text(
              L.t('add_new_card'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: () => setState(() => _showForm = true),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Card holder name
            _field(
              label: L.t('card_holder_name'),
              controller: _nameCtrl,
              hint: 'John Doe',
              inputType: TextInputType.name,
              validator: (v) =>
                  v!.trim().isEmpty ? L.t('field_required') : null,
            ),

            // Card number
            _field(
              label: L.t('card_number'),
              controller: _numberCtrl,
              hint: '1234 5678 9012 3456',
              inputType: TextInputType.number,
              maxLength: 19,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CardNumberFormatter(),
              ],
              validator: (v) {
                final n = v!.replaceAll(' ', '');
                if (n.length < 16) return L.t('invalid_card_number');
                return null;
              },
            ),

            // Expiry row
            Row(
              children: [
                Expanded(
                  child: _field(
                    label: L.t('month'),
                    controller: _monthCtrl,
                    hint: 'MM',
                    inputType: TextInputType.number,
                    maxLength: 2,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      final m = int.tryParse(v ?? '');
                      if (m == null || m < 1 || m > 12) {
                        return L.t('invalid_month');
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    label: L.t('year'),
                    controller: _yearCtrl,
                    hint: 'YY',
                    inputType: TextInputType.number,
                    maxLength: 2,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.length != 2) {
                        return L.t('invalid_year');
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    label: 'CVC',
                    controller: _cvcCtrl,
                    hint: '123',
                    inputType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.length < 3) {
                        return L.t('invalid_cvc');
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary(context),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _submit,
                child: Text(
                  L.t('confirm_payment'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 14, color: AppColors.textGrey(context)),
                const SizedBox(width: 6),
                Text(
                  L.t('secured_by_edfapay'),
                  style: TextStyle(
                    color: AppColors.textGrey(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? inputType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textGrey(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: inputType,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            validator: validator,
            style: TextStyle(color: AppColors.text(context)),
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
              hintStyle: TextStyle(color: AppColors.textHint(context)),
              filled: true,
              fillColor: AppColors.card(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.textGrey(context).withOpacity(0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.textGrey(context).withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primary(context),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card number formatter: 1234 5678 9012 3456 ──
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}
