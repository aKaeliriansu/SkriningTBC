import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Menampilkan HTML Stitch dari asset (setelah Anda mengunduh ke assets/stitch/).
class StitchHtmlWebView extends StatefulWidget {
  const StitchHtmlWebView({
    super.key,
    required this.assetPath,
    this.backgroundColor,
  });

  final String assetPath;
  final Color? backgroundColor;

  @override
  State<StitchHtmlWebView> createState() => _StitchHtmlWebViewState();
}

class _StitchHtmlWebViewState extends State<StitchHtmlWebView> {
  late final WebViewController _controller;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(widget.backgroundColor ?? Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (err) {
            if (mounted) {
              setState(() {
                _loading = false;
                _error = err.description;
              });
            }
          },
        ),
      );
    _controller.loadFlutterAsset(widget.assetPath).catchError((Object e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Pratinjau HTML Stitch di web belum didukung. Gunakan Android/iOS atau '
            'buka berkas ${widget.assetPath} di browser.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Gagal memuat ${widget.assetPath}\n$_error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: WebViewWidget(controller: _controller)),
        if (_loading)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.white54,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
