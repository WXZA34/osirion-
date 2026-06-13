import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'full_screen_image_viewer.dart';

class AvatarViewer extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
  final IconData fallbackIcon;
  final VoidCallback? onTap;
  final bool enableFullScreen;

  const AvatarViewer({
    super.key,
    this.imageUrl,
    this.radius = 30,
    this.borderColor,
    this.borderWidth = 2,
    this.boxShadow,
    this.fallbackIcon = Icons.person,
    this.onTap,
    this.enableFullScreen = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else if (enableFullScreen && imageUrl != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenImageViewer(imageUrl: imageUrl!),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border:
              borderColor != null
                  ? Border.all(color: borderColor!, width: borderWidth)
                  : null,
          boxShadow: boxShadow,
        ),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: Colors.white10,
          child: ClipOval(
            child: imageUrl != null && imageUrl!.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: imageUrl!,
                    width: radius * 2,
                    height: radius * 2,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: borderColor ?? Colors.white24,
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(fallbackIcon, color: Colors.white54, size: radius),
                  )
                : imageUrl != null && !imageUrl!.startsWith('http')
                    ? Image.file(
                        File(imageUrl!),
                        width: radius * 2,
                        height: radius * 2,
                        fit: BoxFit.cover,
                      )
                    : Icon(fallbackIcon, color: Colors.white54, size: radius),
          ),
        ),
      ),
    );
  }
}

