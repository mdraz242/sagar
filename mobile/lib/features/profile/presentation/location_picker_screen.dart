import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/india_location_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/vypar_ui.dart';
import '../../auth/application/auth_provider.dart';

class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  late final TextEditingController _addressController;
  late final TextEditingController _areaController;
  late final TextEditingController _pincodeController;
  bool _loadingLocation = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider);
    _addressController = TextEditingController(
      text: user?.address == 'Address pending' ? '' : user?.address ?? '',
    );
    _areaController = TextEditingController(
      text: user?.area == 'Area pending' ? '' : user?.area ?? '',
    );
    _pincodeController = TextEditingController(text: user?.pincode ?? '');
  }

  @override
  void dispose() {
    _addressController.dispose();
    _areaController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      showHeader: false,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _goBack(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.blue),
                  ),
                  const Expanded(
                    child: Text(
                      'Select Location',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
                children: [
                  VyparCard(
                    color: AppColors.surfaceCream.withValues(alpha: .55),
                    child: const Row(
                      children: [
                        Icon(Icons.local_shipping_outlined,
                            color: AppColors.primaryAlt),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Choose your delivery location to show accurate stock and 2-hour delivery availability.',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  VyparButton.ghost(
                    label: _loadingLocation
                        ? 'Detecting location...'
                        : 'Use current location',
                    icon: Icons.my_location,
                    onPressed: _loadingLocation ? null : _useCurrentLocation,
                  ),
                  const SizedBox(height: 18),
                  const _InputLabel('Address / Landmark'),
                  TextField(
                    controller: _addressController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Ward, road, shop landmark',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _InputLabel('Area / City'),
                            TextField(
                              controller: _areaController,
                              decoration: const InputDecoration(
                                hintText: 'City, town or village',
                                prefixIcon: Icon(Icons.map_outlined),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _InputLabel('Pincode'),
                            TextField(
                              controller: _pincodeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '854340',
                                prefixIcon: Icon(Icons.pin_outlined),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _InputLabel('Saved Locations'),
                  const SizedBox(height: 8),
                  _SavedLocationTile(
                    title: 'Home',
                    subtitle: 'Use your shop or delivery area',
                    onTap: () => _fill('Main Road', 'Your area', ''),
                  ),
                  _SavedLocationTile(
                    title: 'Shop',
                    subtitle: 'Use a nearby market area',
                    onTap: () => _fill('Market Road', 'Your area', ''),
                  ),
                  const SizedBox(height: 18),
                  VyparButton.primary(
                    label: 'Save Location',
                    icon: Icons.check,
                    onPressed: () {
                      showVyparToast(
                        context,
                        'Location selected for this session.',
                      );
                      _goBack(context);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => context.go('/profile/addresses'),
                    child: const Text('Manage saved addresses'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _loadingLocation = true);
    try {
      final address = await const IndiaLocationService().currentAddress();
      _addressController.text = address.line1;
      _areaController.text =
          address.city.isNotEmpty ? address.city : address.area;
      _pincodeController.text = address.pincode;
    } catch (error) {
      if (mounted) showVyparToast(context, apiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  void _fill(String address, String area, String pincode) {
    _addressController.text = address;
    _areaController.text = area;
    _pincodeController.text = pincode;
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }
}

class _SavedLocationTile extends StatelessWidget {
  const _SavedLocationTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return VyparCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.location_city_outlined, color: AppColors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.blue,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
