part of 'profile_subpages.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final addresses = ref.watch(profileAddressesProvider);
    return _SubPageShell(
      title: 'My Addresses',
      action: TextButton(
        onPressed: () => context.go('/profile/addresses/new'),
        child: const Text('+ Add New'),
      ),
      child: addresses.when(
        loading: () => const VyparSkeletonList(itemCount: 3),
        error: (error, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 112),
          children: [
            VyparEmptyState(
              icon: Icons.location_off_outlined,
              title: 'Could not load addresses',
              subtitle: apiErrorMessage(error),
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(profileAddressesProvider),
            ),
          ],
        ),
        data: (items) {
          final shown = items.isNotEmpty
              ? items
              : [
                  Address(
                    id: 'profile',
                    name: user?.name ?? 'VyparHub Retailer',
                    phone: user?.phone ?? '',
                    line1: user?.address ?? 'Address pending',
                    area: user?.area ?? 'Area pending',
                    city: user?.area ?? 'your area',
                    state: 'Bihar',
                    pincode: user?.pincode.isNotEmpty == true
                        ? user!.pincode
                        : '854340',
                    isDefault: true,
                  ),
                ];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
            children: [
              const _SectionLabel('Saved Addresses'),
              const SizedBox(height: 10),
              for (final address in shown)
                _AddressCard.fromAddress(
                  address,
                  onEdit: () => context.go('/profile/addresses/edit'),
                  onDelete: address.id == 'profile'
                      ? null
                      : () async {
                          await ref.read(addressApiProvider).delete(address.id);
                          ref.invalidate(profileAddressesProvider);
                        },
                  onSetDefault: address.id == 'profile' || address.isDefault
                      ? null
                      : () async {
                          await ref
                              .read(addressApiProvider)
                              .setDefault(address.id);
                          ref.invalidate(profileAddressesProvider);
                        },
                ),
            ],
          );
        },
      ),
    );
  }
}

class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, required this.edit});

  final bool edit;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController pincodeController;
  late final TextEditingController line1Controller;
  late final TextEditingController landmarkController;
  late final TextEditingController cityController;
  late final TextEditingController stateController;
  bool isDefault = true;
  bool saving = false;
  String addressType = 'Home';
  String? error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider);
    nameController = TextEditingController(text: user?.name ?? '');
    phoneController = TextEditingController(text: user?.phone ?? '');
    pincodeController = TextEditingController(text: user?.pincode ?? '');
    line1Controller = TextEditingController(text: user?.address ?? '');
    landmarkController = TextEditingController();
    cityController = TextEditingController(text: user?.area ?? '');
    stateController = TextEditingController(text: 'Bihar');
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    pincodeController.dispose();
    line1Controller.dispose();
    landmarkController.dispose();
    cityController.dispose();
    stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SubPageShell(
      title: widget.edit ? 'Edit Address' : 'Add New Address',
      action: widget.edit
          ? TextButton(
              onPressed: saving ? null : _saveAddress,
              child: const Text('Save'),
            )
          : null,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        children: [
          const _SectionLabel('Address Type'),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final type in const ['Home', 'Work', 'Other']) ...[
                Expanded(
                  child: _ChoicePill(
                    type,
                    selected: addressType == type,
                    onTap: () => setState(() => addressType = type),
                  ),
                ),
                if (type != 'Other') const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 18),
          _InputLabel('Full Name'),
          _StyledField(controller: nameController),
          _InputLabel('Phone Number'),
          _StyledField(controller: phoneController),
          _InputLabel('Pincode'),
          _StyledField(controller: pincodeController),
          _InputLabel('Address line'),
          _StyledField(controller: line1Controller),
          _InputLabel('Landmark (Optional)'),
          _StyledField(controller: landmarkController),
          OutlinedButton.icon(
            onPressed: () => context.go('/location'),
            icon: const Icon(Icons.my_location_outlined),
            label: const Text('Use map or current location'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InputLabel('City'),
                    _StyledField(controller: cityController),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InputLabel('State'),
                    _StyledField(controller: stateController),
                  ],
                ),
              ),
            ],
          ),
          CheckboxListTile(
            value: isDefault,
            onChanged: (value) => setState(() => isDefault = value ?? false),
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.orange,
            title: const Text(
              'Set as Default Address',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          if (error != null) ...[
            Text(
              error!,
              style: const TextStyle(
                color: AppColors.primaryAlt,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: saving ? null : _saveAddress,
            style: _orangeButton(),
            child: Text(saving
                ? 'Saving...'
                : widget.edit
                    ? 'Save Changes'
                    : 'Save Address'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAddress() async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      if (!AppConfig.useMockData) {
        await ref.read(addressApiProvider).create({
          'name': addressType,
          'recipientName': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'pincode': pincodeController.text.trim(),
          'line1': line1Controller.text.trim(),
          'area': landmarkController.text.trim(),
          'city': cityController.text.trim(),
          'state': stateController.text.trim(),
          'isDefault': isDefault,
        });
        ref.invalidate(profileAddressesProvider);
      }
      if (mounted) context.go('/profile/addresses');
    } catch (e) {
      setState(() => error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.type,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.phone,
    required this.onEdit,
    this.onDelete,
    this.onSetDefault,
    this.selected = false,
  });

  factory _AddressCard.fromAddress(
    Address address, {
    required VoidCallback onEdit,
    VoidCallback? onDelete,
    VoidCallback? onSetDefault,
  }) {
    return _AddressCard(
      selected: address.isDefault,
      type: address.isDefault ? 'Home' : 'Saved',
      name: address.name.isEmpty ? 'Saved Address' : address.name,
      address: address.line1,
      city: address.city.isEmpty ? address.area : address.city,
      state: address.state,
      pincode: address.pincode,
      phone: address.phone,
      onEdit: onEdit,
      onDelete: onDelete,
      onSetDefault: onSetDefault,
    );
  }

  final String type;
  final String name;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String phone;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSetDefault;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.orange : AppColors.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(type,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
              if (selected)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Default',
                      style: TextStyle(
                          color: AppColors.brightBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.w900)),
                )
              else
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.muted),
                  onSelected: (value) {
                    if (value == 'default') onSetDefault?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (context) => [
                    if (onSetDefault != null)
                      const PopupMenuItem(
                        value: 'default',
                        child: Text('Set as default'),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                  ],
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 34, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(address),
                Text('$city, $pincode'),
                Text(state),
                const SizedBox(height: 8),
                Text('+91 $phone'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 15),
                      label: const Text('Edit'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onDelete,
                      child: const Text('Delete',
                          style: TextStyle(color: AppColors.orange)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
