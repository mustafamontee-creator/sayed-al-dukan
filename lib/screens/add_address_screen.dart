import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../services/repo.dart';
import '../ui/widgets.dart';

/// OpenStreetMap picker. The customer must tap to place a pin;
/// location permission is requested only after tapping "my location".
class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});
  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  static final LatLng _cairo = LatLng(30.0444, 31.2357);
  final MapController _map = MapController();
  LatLng _pos = LatLng(30.0444, 31.2357);
  bool _picked = false, _default = false, _busy = false;
  final _landmark = TextEditingController();
  final _text = TextEditingController();

  @override
  void dispose() {
    _map.dispose();
    _landmark.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever ||
          !await Geolocator.isLocationServiceEnabled()) {
        _snack(context.t('locationDenied'));
        return;
      }
      final p = await Geolocator.getCurrentPosition();
      final ll = LatLng(p.latitude, p.longitude);
      setState(() {
        _pos = ll;
        _picked = true;
      });
      _map.move(ll, 17);
    } catch (_) {
      _snack(context.t('locationDenied'));
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _save() async {
    if (!_picked) return _snack(context.t('pinRequired'));
    if (_landmark.text.trim().isEmpty) return _snack(context.t('landmark'));
    setState(() => _busy = true);
    try {
      final repo = context.read<Repo>();
      final first = (await repo.addresses()).isEmpty;
      await repo.addAddress(
        text: _text.text.trim(),
        lat: _pos.latitude,
        lng: _pos.longitude,
        landmark: _landmark.text.trim(),
        makeDefault: _default || first,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        _snack(friendlyError(context, e));
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('addAddress'))),
      body: Column(children: [
        Expanded(
          flex: 5,
          child: Stack(children: [
            FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: _cairo,
                initialZoom: 12,
                onTap: (_, point) => setState(() {
                  _pos = point;
                  _picked = true;
                }),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sayedaldukan.sayed_al_dukan',
                ),
                if (_picked)
                  MarkerLayer(markers: [
                    Marker(
                      point: _pos,
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.location_pin,
                        color: AppColors.black,
                        size: 42,
                      ),
                    ),
                  ]),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      '© OpenStreetMap contributors',
                      onTap: () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              right: 12,
              top: 12,
              child: FloatingActionButton.extended(
                heroTag: 'loc',
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                elevation: 0,
                onPressed: _locate,
                icon: const Icon(Icons.my_location),
                label: Text(context.t('myLocation')),
              ),
            ),
          ]),
        ),
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              TextField(
                controller: _landmark,
                decoration: InputDecoration(labelText: context.t('landmark')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _text,
                decoration: InputDecoration(labelText: context.t('addressText')),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.black,
                checkColor: AppColors.white,
                side: const BorderSide(color: AppColors.black, width: 2),
                value: _default,
                onChanged: (v) => setState(() => _default = v ?? false),
                title: Text(context.t('defaultAddress')),
              ),
              ElevatedButton(
                onPressed: _busy ? null : _save,
                child: Text(context.t('saveAddress')),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
