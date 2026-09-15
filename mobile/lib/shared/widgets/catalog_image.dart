import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import 'app_network_image.dart';

class CatalogImage extends StatelessWidget {
  const CatalogImage(
    this.path, {
    super.key,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveCatalogImage(path);
    if (resolved.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
      );
    }
    if (resolved.startsWith('http')) {
      return SizedBox(
        width: width,
        height: height,
        child: AppNetworkImage(url: resolved, fit: fit),
      );
    }
    return Image.asset(
      resolved,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.inventory_2_outlined, color: Colors.grey),
    );
  }
}

String resolveCatalogImage(String path) {
  if (path.trim().isEmpty) return '';
  if (path.startsWith('http')) return path;
  if (path.startsWith('assets/')) return path;
  if (path.startsWith('/')) {
    final origin = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$origin$path';
  }
  if (_isStoragePath(path)) return _supabasePublicAsset(path);
  if (path.startsWith('products/')) return 'assets/images/$path';
  return path;
}

bool _isStoragePath(String path) {
  // Admin uploads store relative object paths; resolve them for every app screen.
  final normalized = path.toLowerCase();
  return normalized.startsWith('categories/') ||
      normalized.startsWith('brands/') ||
      normalized.startsWith('banners/') ||
      normalized.startsWith('uploads/') ||
      normalized.startsWith('public/');
}

String _supabasePublicAsset(String path) {
  final cleanPath = path.replaceFirst(RegExp(r'^public/'), '');
  return 'https://vltszvnfazjsdtlbfxdc.supabase.co/storage/v1/object/public/vyparhub-assets/$cleanPath';
}
