import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// إعلانات المدرسة (`GET /api/mobile/banners`) كشريط صور قابل للسحب.
///
/// الصور تُحمَّل عند ظهور صفحتها فقط (PageView يبني الصفحة الحالية والمجاورة)،
/// ولا تحتاج توكن. البنرات للعرض فقط، دون فتح روابط عند الضغط.
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key, required this.banners});

  final List<SchoolBanner> banners;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _controller = PageController();
  Timer? _autoSlideTimer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (widget.banners.length < 2 ||
          !_controller.hasClients ||
          _controller.position.isScrollingNotifier.value) {
        return;
      }
      _controller.animateToPage(
        (_page + 1) % widget.banners.length,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: 16 / 7,
            child: PageView.builder(
              controller: _controller,
              itemCount: banners.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) => _BannerPage(banner: banners[i]),
            ),
          ),
        ),
        if (banners.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < banners.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == _page ? 16 : 6,
                  height: 4,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? AppColors.brandPurple
                        : AppColors.gray200,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _BannerPage extends StatelessWidget {
  const _BannerPage({required this.banner});

  final SchoolBanner banner;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.purple50),
        if (banner.imageUrl.isNotEmpty)
          Image.network(
            banner.imageUrl,
            fit: BoxFit.cover,
            // 404: الإعلان عُطّل بعد تحميل القائمة؛ نعرض خلفية فارغة.
            errorBuilder: (_, _, _) => const Center(
              child: Icon(
                LucideIcons.imageOff,
                size: 24,
                color: AppColors.purple200,
              ),
            ),
          ),
        if (banner.title.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 24, 14, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      banner.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.style(
                        size: 12,
                        weight: AppText.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
