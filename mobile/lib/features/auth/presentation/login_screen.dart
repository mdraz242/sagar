import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/translations.dart';
import '../../../core/location/india_location_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../application/auth_provider.dart';

part 'login_screen.password_login.dart';
part 'login_screen.otp_login.dart';
part 'login_screen.forgot_password.dart';
part 'login_screen.shared_widgets.dart';
