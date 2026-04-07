import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';
import '../../../core/network/api_client.dart';

class PatrolNetworkImage extends StatefulWidget {
  final String filePath;
  final double? width;
  final double? height;
  final BoxFit fit;

  const PatrolNetworkImage({
    super.key,
    required this.filePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<PatrolNetworkImage> createState() => _PatrolNetworkImageState();
}

class _PatrolNetworkImageState extends State<PatrolNetworkImage> {
  final ApiClient _apiClient = ApiClient();
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant PatrolNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final response = await _apiClient.dio.get(
        '/mobile/patrol/foto',
        queryParameters: {'path': widget.filePath},
        options: Options(responseType: ResponseType.bytes),
      );
      if (mounted) {
        setState(() {
          _imageBytes = Uint8List.fromList(response.data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_hasError || _imageBytes == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Container(
          color: Colors.grey.shade200,
          child: Icon(Icons.broken_image, color: Colors.grey.shade400),
        ),
      );
    }
    return Image.memory(
      _imageBytes!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}
