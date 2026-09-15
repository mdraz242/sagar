import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/network/api_services.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/vypar_ui.dart';
import '../../auth/application/auth_provider.dart';

part 'profile_subpages.addresses.dart';
part 'profile_subpages.payments.dart';
part 'profile_subpages.refer_help.dart';
part 'profile_subpages.rate_about.dart';
part 'profile_subpages.logout_deletion.dart';
part 'profile_subpages.shared_widgets.dart';

final profileAddressesProvider =
    FutureProvider.autoDispose<List<Address>>((ref) {
  if (AppConfig.useMockData) return Future.value(const []);
  return ref.watch(addressApiProvider).list();
});

final accountDeletionOtpProvider = StateProvider<String?>((ref) => null);
