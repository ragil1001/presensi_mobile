import 'dart:collection';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';

/// A widget that loads CS task photos through the backend proxy
/// (GET /mobile/cs/foto?path=`<filePath>`).
///
/// This avoids requiring the mobile device to have direct MinIO access.
/// Uses the authenticated [ApiClient] so the request includes the Bearer token.
class CsNetworkImage extends StatefulWidget {
  /// The MinIO file path (e.g. `cleaning/123/2024-01-01_before_456.jpg`).
  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;

  const CsNetworkImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
  });

  @override
  State<CsNetworkImage> createState() => _CsNetworkImageState();
}

class _CsNetworkImageState extends State<CsNetworkImage> {
  // Cache memory dibatasi kecil untuk hemat RAM pada device low-end.
  static const int _maxMemoryCacheBytes = 512 * 1024; // 512KB
  static final LinkedHashMap<String, Uint8List> _cache =
      LinkedHashMap<String, Uint8List>();
  static int _currentMemoryCacheBytes = 0;

  final _apiClient = ApiClient();
  late Future<Uint8List> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  Future<Uint8List> _load() async {
    // Return from cache if available
    if (_cache.containsKey(widget.imagePath)) {
      final cached = _cache.remove(widget.imagePath)!;
      // Reinsert to mark as most-recently-used.
      _cache[widget.imagePath] = cached;
      return cached;
    }

    final response = await _apiClient.dio.get(
      '/mobile/cs/foto',
      queryParameters: {'path': widget.imagePath},
      options: Options(responseType: ResponseType.bytes),
    );

    final bytes = Uint8List.fromList(response.data as List<int>);
    _remember(widget.imagePath, bytes);
    return bytes;
  }

  static void _remember(String key, Uint8List bytes) {
    // Jika satu item sudah melebihi budget, jangan disimpan ke cache.
    if (bytes.lengthInBytes > _maxMemoryCacheBytes) return;

    final previous = _cache.remove(key);
    if (previous != null) {
      _currentMemoryCacheBytes -= previous.lengthInBytes;
    }

    _cache[key] = bytes;
    _currentMemoryCacheBytes += bytes.lengthInBytes;

    while (_currentMemoryCacheBytes > _maxMemoryCacheBytes &&
        _cache.isNotEmpty) {
      final oldestKey = _cache.keys.first;
      final removed = _cache.remove(oldestKey);
      if (removed != null) {
        _currentMemoryCacheBytes -= removed.lengthInBytes;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: widget.width,
            height: widget.height,
            color: AppColors.surfaceVariant,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return widget.errorWidget ??
              Container(
                width: widget.width,
                height: widget.height,
                color: AppColors.surfaceVariant,
                child: const Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: AppColors.textTertiary,
                    size: 24,
                  ),
                ),
              );
        }

        return Image.memory(
          snapshot.data!,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          gaplessPlayback: true,
        );
      },
    );
  }
}
