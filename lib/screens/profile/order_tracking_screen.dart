import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  final _service = OrderViewService();

  final Completer<GoogleMapController> _mapCompleter = Completer();
  GoogleMapController? _mapController;

  LatLng? driverLocation;
  late LatLng customerLocation;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

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

  @override
  void dispose() {
    channel?.unsubscribe();
    _mapController?.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  Future<void> _loadDetails() async {
    setState(() => loadingDetails = true);
    final res = await _service.getOrderById(widget.order.id);
    if (!mounted) return;
    setState(() {
      fullOrder = res ?? widget.order;
      loadingDetails = false;
    });
  }

  // ─────────────────────────────────────────
  //  Realtime
  // ─────────────────────────────────────────
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
          final data = payload.newRecord;
          final latRaw = data['lat'];
          final lngRaw = data['lng'];
          if (latRaw == null || lngRaw == null) return;

          final loc = LatLng(
            (latRaw as num).toDouble(),
            (lngRaw as num).toDouble(),
          );

          if (!mounted) return;
          setState(() => driverLocation = loc);

          _mapController?.animateCamera(CameraUpdate.newLatLng(loc));

          await _fetchRoute(loc, customerLocation);
        },
      )
      ..subscribe();
  }

  // ─────────────────────────────────────────
  //  Initial driver location
  // ─────────────────────────────────────────
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

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: loc, zoom: 16)),
    );

    await _fetchRoute(loc, customerLocation);
  }

  // ─────────────────────────────────────────
  //  Route
  // ─────────────────────────────────────────
  Future<void> _fetchRoute(LatLng start, LatLng end) async {
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};'
          '${end.longitude},${end.latitude}'
          '?overview=full&geometries=geojson';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return;

      final coords = routes[0]['geometry']['coordinates'] as List;
      final points = coords
          .map(
            (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
          )
          .toList();

      if (!mounted) return;
      _buildMarkersAndPolyline(points);
    } catch (e) {
      debugPrint('_fetchRoute error: $e');
    }
  }

  // ─────────────────────────────────────────
  //  Markers + Polyline
  // ─────────────────────────────────────────
  void _buildMarkersAndPolyline(List<LatLng> routePoints) {
    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('customer'),
        position: customerLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Your location'),
      ),
    };

    if (driverLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Driver'),
        ),
      );
    }

    setState(() {
      _markers = markers;
      _polylines = routePoints.isEmpty
          ? {}
          : {
              // ظل
              Polyline(
                polylineId: const PolylineId('route_shadow'),
                points: routePoints,
                width: 8,
                color: Colors.black.withValues(alpha: 0.15),
              ),
              // الخط الأساسي
              Polyline(
                polylineId: const PolylineId('route'),
                points: routePoints,
                width: 4,
                color: Colors.deepOrange,
              ),
            };
    });
  }

  // ─────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary(context);
    final text = AppColors.text(context);
    final card = AppColors.card(context);
    final hint = AppColors.textHint(context);
    final o = fullOrder ?? widget.order;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Column(
        children: [
          // ── MAP ──────────────────────────────────
          Expanded(
            flex: 6,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: customerLocation,
                zoom: 15,
              ),
              mapType: MapType.normal,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (controller) {
                _mapCompleter.complete(controller);
                _mapController = controller;

                // بعد ما تتهيأ الخريطة، حرّك للسائق لو موجود
                if (driverLocation != null) {
                  controller.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(target: driverLocation!, zoom: 16),
                    ),
                  );
                }

                // ارسم الـ customer marker فوراً
                setState(() {
                  _markers = {
                    Marker(
                      markerId: const MarkerId('customer'),
                      position: customerLocation,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                      infoWindow: const InfoWindow(title: 'Your location'),
                    ),
                  };
                });
              },
            ),
          ),

          // ── DETAILS PANEL ─────────────────────────
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

                    // ── ITEMS ─────────────────────────────
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
                          style: const TextStyle(color: Colors.black),
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

  // ─────────────────────────────────────────
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
