import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/translations.dart';
import '../../../core/network/api_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/pricing.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/repositories/api_catalog_repository.dart';
import '../../../data/repositories/catalog_providers.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/catalog_image.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/vypar_ui.dart';
import '../../auth/application/auth_provider.dart';
import '../../cart/application/cart_provider.dart';
import '../../products/domain/product.dart';

part 'home_screen.state.dart';
part 'home_screen.search_hero.dart';
part 'home_screen.sections.dart';
part 'home_screen.deals.dart';
part 'home_screen.brand_why.dart';
