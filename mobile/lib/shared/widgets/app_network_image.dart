import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage(
      {super.key, required this.url, this.fit = BoxFit.cover});
  final String url;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) => CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, __) =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorWidget: (_, __, ___) =>
          const Icon(Icons.image_not_supported_outlined));
}
