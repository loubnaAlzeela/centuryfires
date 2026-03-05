import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/address_service.dart';
import '../../utils/l.dart';
import 'package:latlong2/latlong.dart';
import 'map_picker_screen.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final _formKey = GlobalKey<FormState>();

  final title = TextEditingController();
  final city = TextEditingController();
  final area = TextEditingController();
  final street = TextEditingController();
  final building = TextEditingController();
  final apartment = TextEditingController();
  final notes = TextEditingController();
  LatLng? _selectedLocation;

  List<Map<String, dynamic>> _addresses = [];
  Map<String, dynamic>? _address;

  bool _setAsDefault = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    title.dispose();
    city.dispose();
    area.dispose();
    street.dispose();
    building.dispose();
    apartment.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    try {
      final data = await AddressService().getAddresses();
      final currentId = _address?['id'];

      if (mounted) {
        setState(() {
          _addresses = data;

          if (data.isNotEmpty) {
            final sameAddress = data.firstWhere(
              (a) => a['id'] == currentId,
              orElse: () => data.first,
            );
            _selectAddress(sameAddress);
          } else {
            _clearForm();
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _addresses = [];
          _clearForm();
        });
        _showError(L.t('err_load_addresses'));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _selectAddress(Map<String, dynamic> address) {
    _address = address;

    title.text = address['title'] ?? '';
    city.text = address['city'] ?? '';
    area.text = address['area'] ?? '';
    street.text = address['street'] ?? '';
    building.text = address['building'] ?? '';
    apartment.text = address['apartment'] ?? '';
    notes.text = address['notes'] ?? '';

    _setAsDefault = address['is_default'] == true;
  }

  void _clearForm() {
    _address = null;
    title.clear();
    city.clear();
    area.clear();
    street.clear();
    building.clear();
    apartment.clear();
    notes.clear();
    _setAsDefault = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        title: Text(
          L.t('saved_addresses'),
          style: TextStyle(color: AppColors.text(context)),
        ),
        iconTheme: IconThemeData(color: AppColors.text(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_addresses.isNotEmpty) ...[
                      SizedBox(
                        height: 56,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _addresses.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final a = _addresses[index];
                            final selected = _address?['id'] == a['id'];

                            return GestureDetector(
                              onTap: () {
                                setState(() => _selectAddress(a));
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary(context)
                                      : AppColors.card(context),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  a['title'] ?? L.t('address'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: selected
                                        ? AppColors.textOnPrimary(context)
                                        : AppColors.text(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() => _clearForm()),
                        child: Text(L.t('add_new_address')),
                      ),
                    ),

                    _section(
                      context,
                      title: L.t('address_name'),
                      child: _field(title, L.t('eg_home'), required: true),
                    ),
                    _section(
                      context,
                      title: L.t('location'),
                      child: Column(
                        children: [
                          _field(city, L.t('city'), required: true),
                          _field(area, L.t('area'), required: true),
                        ],
                      ),
                    ),
                    _section(
                      context,
                      title: L.t('street_details'),
                      child: Column(
                        children: [
                          _field(street, L.t('street'), required: true),
                          _field(building, L.t('building')),
                          _field(apartment, L.t('apartment')),
                        ],
                      ),
                    ),
                    _section(
                      context,
                      title: L.t('notes'),
                      child: _field(
                        notes,
                        L.t('extra_directions'),
                        maxLines: 3,
                      ),
                    ),

                    CheckboxListTile(
                      value: _setAsDefault,
                      activeColor: AppColors.primary(context),
                      title: Text(L.t('set_default_address')),
                      onChanged: (bool? v) {
                        setState(() {
                          _setAsDefault = v ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.map),
                        label: Text(
                          _selectedLocation == null
                              ? "Select Location From Map"
                              : "Location Selected ✓",
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MapPickerScreen(),
                            ),
                          );

                          if (result != null) {
                            setState(() {
                              _selectedLocation = result['location'];

                              final addr = result['address'];

                              if (addr != null) {
                                street.text = addr['road'] ?? '';
                                area.text = addr['suburb'] ?? '';
                                city.text = addr['city'] ?? addr['town'] ?? '';
                              }
                            });
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary(context),
                          foregroundColor: AppColors.textOnPrimary(context),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _saving ? null : _save,
                        child: Text(
                          L.t('save_address'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    if (_address != null && _address!['id'] != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton(
                          onPressed: _confirmDelete,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            L.t('delete_address'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.text(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hint),
        validator: required
            ? (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) {
                  return L.t('required');
                }
                if (value.length > 200) {
                  return L.t('text_too_long');
                }
                return null;
              }
            : null,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;

    if (_selectedLocation == null) {
      _showError("Please select location from map");
      return;
    }

    setState(() => _saving = true);

    try {
      final data = {
        'title': title.text.trim(),
        'city': city.text.trim(),
        'area': area.text.trim(),
        'street': street.text.trim(),
        'building': building.text.trim(),
        'apartment': apartment.text.trim(),
        'notes': notes.text.trim(),
        'is_default': _setAsDefault,
        'lat': _selectedLocation!.latitude,
        'lng': _selectedLocation!.longitude,
      };

      final service = AddressService();

      if (_address == null) {
        await service.addAddress(data);
      } else {
        final id = _address!['id'];
        await service.updateAddress(id, data);
      }

      await _loadAddresses();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final id = _address?['id'];
    if (id == null) {
      _showError(L.t('invalid_address'));
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(L.t('delete_address')),
        content: Text(L.t('confirm_delete_address')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(L.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(L.t('delete')),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      try {
        await AddressService().deleteAddress(id);
        await _loadAddresses();

        if (_addresses.isEmpty) {
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(L.t('address_deleted'))));
        }
      } catch (_) {
        _showError(L.t('err_delete_address'));
      }
    }
  }

  void _showError([String? message]) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message ?? L.t('err_general'))));
  }
}
