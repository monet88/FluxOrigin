import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  final bool isDark;

  const HistoryScreen({super.key, required this.isDark});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'all'; // 'all' or 'saved'

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lịch sử dịch thuật',
                style: GoogleFonts.merriweather(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white : AppColors.lightPrimary,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.isDark
                        ? const Color(0xFF444444)
                        : Colors.grey[200]!,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _FilterButton(
                      label: 'Tất cả',
                      isActive: _filter == 'all',
                      isDark: widget.isDark,
                      onTap: () => setState(() => _filter = 'all'),
                    ),
                    _FilterButton(
                      label: 'Đã lưu',
                      isActive: _filter == 'saved',
                      isDark: widget.isDark,
                      onTap: () => setState(() => _filter = 'saved'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Grid of history cards
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 350,
                childAspectRatio: 1.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => _HistoryCard(
                isDark: widget.isDark,
                index: index,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? Colors.white : AppColors.lightPrimary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.grey[400] : Colors.grey[500]),
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatefulWidget {
  final bool isDark;
  final int index;

  const _HistoryCard({
    required this.isDark,
    required this.index,
  });

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? (widget.isDark
                    ? Colors.white.withOpacity(0.5)
                    : AppColors.lightPrimary.withOpacity(0.5))
                : (widget.isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder),
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(widget.isDark ? 0.3 : 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: widget.isDark
                                ? Colors.white.withOpacity(0.3)
                                : AppColors.lightPrimary.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'EN → VI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: widget.isDark
                                ? Colors.white
                                : AppColors.lightPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '2 phút trước',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isDark
                              ? Colors.grey[500]
                              : AppColors.lightPrimary.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'FluxOrigin is the sibling app...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: widget.isDark
                          ? Colors.grey[300]
                          : AppColors.lightPrimary,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: widget.isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                  ),
                  Expanded(
                    child: Text(
                      'FluxOrigin là ứng dụng anh em...',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: GoogleFonts.merriweather(
                        fontSize: 16,
                        color: widget.isDark
                            ? Colors.grey[100]
                            : AppColors.lightPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isHovered)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color:
                        widget.isDark ? Colors.white : AppColors.lightPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 12,
                    color: widget.isDark ? Colors.black : Colors.white,
                  ),
                ).animate().fadeIn(),
              ),
          ],
        ),
      ),
    );
  }
}
