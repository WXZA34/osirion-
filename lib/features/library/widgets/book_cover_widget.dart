import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/book_cover_service.dart';

class BookCoverWidget extends StatefulWidget {
  final String title;
  final String author;
  final double width;
  final double height;
  final String? thumbnailUrl;

  const BookCoverWidget({
    super.key,
    required this.title,
    required this.author,
    this.width = 70,
    this.height = 100,
    this.thumbnailUrl,
  });

  @override
  State<BookCoverWidget> createState() => _BookCoverWidgetState();
}

class _BookCoverWidgetState extends State<BookCoverWidget> {
  String? _coverUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCover();
  }

  @override
  void didUpdateWidget(BookCoverWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title || oldWidget.author != widget.author) {
      setState(() {
        _isLoading = true;
        _coverUrl = null;
      });
      _loadCover();
    }
  }

  Future<void> _loadCover() async {
    if (widget.thumbnailUrl != null) {
      if (mounted) {
        setState(() {
          _coverUrl = widget.thumbnailUrl;
          _isLoading = false;
        });
      }
      return;
    }

    final url = await BookCoverService.fetchCoverUrl(
      widget.title,
      widget.author,
    );
    if (mounted) {
      setState(() {
        _coverUrl = url;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: widget.width,
        height: widget.height,
        color: Colors.black45,
        child: _isLoading 
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.cyan,
                ),
              ),
            )
          : (_coverUrl != null
              ? (_coverUrl!.startsWith('assets/')
                  ? Image.asset(
                      _coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                    )
                  : CachedNetworkImage(
                      imageUrl: _coverUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) {
                        if (kDebugMode) {
                          debugPrint("⚠️ [BookCover] Erreur chargement image : $_coverUrl");
                        }
                        return _buildPlaceholder();
                      },
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white10,
                          ),
                        ),
                      ),
                    ))
              : _buildPlaceholder()),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(
        Icons.menu_book,
        color: Colors.white24,
        size: 30,
      ),
    );
  }
}
