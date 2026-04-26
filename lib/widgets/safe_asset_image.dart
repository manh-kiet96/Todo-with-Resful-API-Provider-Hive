import 'package:flutter/material.dart';

/// A small helper widget that centralizes asset image loading with a
/// friendly placeholder and error fallback. Use this instead of calling
/// `Image.asset` directly when assets sometimes fail to appear.
class SafeAssetImage extends StatelessWidget {
  final String assetPath;
  final BoxFit fit;
  final double? width;
  final double? height;

  const SafeAssetImage(
    this.assetPath, {
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: fit,
      width: width,
      height: height,
      // show a neutral placeholder if the asset cannot be loaded
      errorBuilder: (context, error, stackTrace) => Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported,
          size: 64,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}
