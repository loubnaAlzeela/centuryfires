import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_colors.dart';
import '../../models/order_view_model.dart';
import '../../services/order_view_service.dart';
import '../../utils/l.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderViewModel order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final supabase = Supabase.instance.client;
  final MapController _mapController = MapController();
  final OrderViewService _service = OrderViewService();

  LatLng? driverLocation;
  late LatLng customerLocation;

  List<LatLng> routePoints = [];
  RealtimeChannel? channel;

  bool loadingDetails = true;
  OrderViewModel? fullOrder;

  @override
  void initState() {
    super.initState();

    customerLocation = LatLng(widget.order.lat ?? 0, widget.order.lng ?? 0);

    _loadDetails();
    _listenDriverLocation();
    _loadInitialDriverLocation();
  }

  Future<void> _loadDetails() async {
    setState(() => loadingDetails = true);
    final res = await _service.getOrderById(widget.order.id);
    if (!mounted) return;
    setState(() {
      fullOrder = res ?? widget.order;
      loadingDetails = false;
    });
  }

  @override
  void dispose() {
    channel?.unsubscribe();
    super.dispose();
  }

  void _listenDriverLocation() {
    channel = supabase.channel('driver_tracking_${widget.order.id}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'driver_locations',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'order_id',
          value: widget.order.id,
        ),
        callback: (payload) async {
          //          print('TRACK EVENT: ${payload.eventType} => ${payload.newRecord}');
          print('REALTIME PAYLOAD: ${payload.newRecord}');
          final data = payload.newRecord;

          final latRaw = data['lat'];
          final lngRaw = data['lng'];

          if (latRaw == null || lngRaw == null) return;

          final lat = (latRaw as num).toDouble();
          final lng = (lngRaw as num).toDouble();

          final newDriverLocation = LatLng(lat, lng);

          if (!mounted) return;
          setState(() => driverLocation = newDriverLocation);

          _mapController.move(newDriverLocation, 16);
          await _fetchRoute(newDriverLocation, customerLocation);
        },
      )
      ..subscribe();
  }

  Future<void> _loadInitialDriverLocation() async {
    final res = await supabase
        .from('driver_locations')
        .select('lat,lng')
        .eq('order_id', widget.order.id)
        .maybeSingle();

    if (res == null) return;

    final latRaw = res['lat'];
    final lngRaw = res['lng'];

    if (latRaw == null || lngRaw == null) return;

    final loc = LatLng((latRaw as num).toDouble(), (lngRaw as num).toDouble());

    if (!mounted) return;

    setState(() => driverLocation = loc);

    _mapController.move(loc, 16);
    await _fetchRoute(loc, customerLocation);
  }

  Future<void> _fetchRoute(LatLng start, LatLng end) async {
    final url =
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return;

    final data = jsonDecode(response.body);
    final coords = data['routes'][0]['geometry']['coordinates'] as List;

    if (!mounted) return;
    setState(() {
      routePoints = coords.map((c) => LatLng(c[1], c[0])).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary(context);
    final text = AppColors.text(context);
    final card = AppColors.card(context);
    final hint = AppColors.textHint(context);

    final o = fullOrder ?? widget.order;
    // final items = o.orderItems;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Column(
        children: [
          // ================= MAP =================
          Expanded(
            flex: 6,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: customerLocation,
                initialZoom: 15,
                maxZoom: 19,
                minZoom: 5,
              ),
              children: [
                // 🗺️ MapTiler (الحل النهائي)
                TileLayer(
                  urlTemplate:
                      'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=1j7K6ihnUiwsRHOf7LLA',
                  userAgentPackageName: 'com.centuryfries.app',
                ),

                // 🛣️ Route Line
                if (routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        strokeWidth: 8,
                        color: AppColors.text(context).withValues(alpha: 0.25),
                      ),
                      Polyline(
                        points: routePoints,
                        strokeWidth: 4,
                        color: Colors.deepOrange,
                      ),
                    ],
                  ),

                // 📍 Markers
                MarkerLayer(
                  markers: [
                    Marker(
                      point: customerLocation,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.home,
                        color: Colors.red,
                        size: 38,
                      ),
                    ),
                    if (driverLocation != null)
                      Marker(
                        point: driverLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.delivery_dining,
                          color: Colors.blueAccent,
                          size: 38,
                        ),
                      ),
                  ],
                ),

                // 📜 Attribution (مطلوب)
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),

          // ================= DETAILS PANEL =================
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: card,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${L.t('order')} #${o.orderNumber ?? ''}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: text,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      L.t(o.status).toUpperCase(),
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Icon(Icons.location_on, color: primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${o.area ?? ''} - ${o.street ?? ''}',
                            style: TextStyle(color: hint),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ================= ITEMS =================
                    if (o.orderItems.isNotEmpty) ...[
                      Text(
                        L.t('items'),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: text,
                        ),
                      ),
                      const SizedBox(height: 10),

                      ...o.orderItems.map((item) {
                        final qty = item['quantity'] ?? 0;
                        final name = item['meal_name_en'] ?? '';
                        final price = (item['total_price'] ?? 0).toString();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$qty x $name',
                                  style: TextStyle(color: text),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                price,
                                style: TextStyle(
                                  color: text,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 20),

                    Divider(
                      color: AppColors.textHint(context).withValues(alpha: 0.3),
                    ),

                    const SizedBox(height: 12),

                    _priceRow(context, L.t('subtotal'), o.subtotal),
                    _priceRow(context, L.t('discount'), o.discount),
                    _priceRow(context, L.t('total'), o.total, bold: true),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          L.t('close'),
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    BuildContext context,
    String label,
    double value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.text(context),
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              color: bold
                  ? AppColors.primary(context)
                  : AppColors.text(context),
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
