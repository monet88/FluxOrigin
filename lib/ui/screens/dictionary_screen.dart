import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/upload_dictionary_modal.dart';

class DictionaryScreen extends StatefulWidget {
  final bool isDark;

  const DictionaryScreen({super.key, required this.isDark});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  bool _showModal = false;

  final List<Map<String, dynamic>> _mockDicts = [
    {
      'id': 1,
      'name': 'IT Terminology Base',
      'entries': 1240,
      'lastUpdated': '2 giờ trước',
      'type': 'cloud',
      'status': 'Đã đồng bộ',
    },
    {
      'id': 2,
      'name': 'Hợp đồng kinh tế',
      'entries': 850,
      'lastUpdated': '1 ngày trước',
      'type': 'local',
      'status': 'Cục bộ',
    },
    {
      'id': 3,
      'name': 'Marketing Glosary 2024',
      'entries': 320,
      'lastUpdated': '3 ngày trước',
      'type': 'cloud',
      'status': 'Đang tải...',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Từ điển & Thuật ngữ',
                        style: GoogleFonts.merriweather(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: widget.isDark
                              ? Colors.white
                              : AppColors.lightPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quản lý các tệp từ điển cá nhân và chuyên ngành.',
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.isDark
                              ? Colors.grey[400]
                              : AppColors.lightPrimary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _showModal = true),
                    icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
                    label: const Text('Thêm mới'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          widget.isDark ? Colors.white : AppColors.lightPrimary,
                      foregroundColor:
                          widget.isDark ? Colors.black : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Table
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Table header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: widget.isDark
                              ? Colors.black.withOpacity(0.2)
                              : Colors.grey[50]?.withOpacity(0.5),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: widget.isDark
                                  ? AppColors.darkBorder
                                  : Colors.grey[100]!,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'TÊN TỪ ĐIỂN',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: widget.isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[500],
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'SỐ MỤC',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: widget.isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[500],
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'LOẠI',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: widget.isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[500],
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'CẬP NHẬT',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: widget.isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[500],
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'TRẠNG THÁI',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: widget.isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[500],
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),

                      // Table rows
                      Expanded(
                        child: ListView.builder(
                          itemCount: _mockDicts.length,
                          itemBuilder: (context, index) => _DictRow(
                            dict: _mockDicts[index],
                            isDark: widget.isDark,
                            isLast: index == _mockDicts.length - 1,
                          ),
                        ),
                      ),

                      // Footer
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: widget.isDark
                                  ? AppColors.darkBorder
                                  : Colors.grey[100]!,
                              style: BorderStyle.solid,
                            ),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Hiển thị 3 / 3 từ điển',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: widget.isDark
                                  ? Colors.grey[600]
                                  : Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(),

        // Modal
        if (_showModal)
          UploadDictionaryModal(
            isDark: widget.isDark,
            onClose: () => setState(() => _showModal = false),
          ),
      ],
    );
  }
}

class _DictRow extends StatefulWidget {
  final Map<String, dynamic> dict;
  final bool isDark;
  final bool isLast;

  const _DictRow({
    required this.dict,
    required this.isDark,
    required this.isLast,
  });

  @override
  State<_DictRow> createState() => _DictRowState();
}

class _DictRowState extends State<_DictRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isHovered
              ? (widget.isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey[50])
              : Colors.transparent,
          border: widget.isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: widget.isDark
                        ? const Color(0xFF2A2A2A)
                        : Colors.grey[50]!,
                  ),
                ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? Colors.white.withOpacity(0.1)
                          : AppColors.lightPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: FaIcon(
                        FontAwesomeIcons.book,
                        size: 12,
                        color: widget.isDark
                            ? Colors.white
                            : AppColors.lightPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.dict['name'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color:
                          widget.isDark ? Colors.white : AppColors.lightPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                widget.dict['entries'].toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.dict['type'] == 'cloud'
                      ? (widget.isDark
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.blue[50])
                      : (widget.isDark ? Colors.grey[800] : Colors.grey[100]),
                  border: Border.all(
                    color: widget.dict['type'] == 'cloud'
                        ? (widget.isDark
                            ? Colors.blue.withOpacity(0.3)
                            : Colors.blue[200]!)
                        : (widget.isDark
                            ? Colors.grey[600]!
                            : Colors.grey[200]!),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      widget.dict['type'] == 'cloud'
                          ? FontAwesomeIcons.cloud
                          : FontAwesomeIcons.hardDrive,
                      size: 10,
                      color: widget.dict['type'] == 'cloud'
                          ? (widget.isDark
                              ? Colors.blue[400]
                              : Colors.blue[700])
                          : (widget.isDark
                              ? Colors.grey[400]
                              : Colors.grey[600]),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.dict['type'] == 'cloud' ? 'Cloud' : 'Local',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.dict['type'] == 'cloud'
                            ? (widget.isDark
                                ? Colors.blue[400]
                                : Colors.blue[700])
                            : (widget.isDark
                                ? Colors.grey[400]
                                : Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                widget.dict['lastUpdated'],
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.dict['status'] == 'Đã đồng bộ'
                          ? Colors.green
                          : (widget.dict['status'] == 'Cục bộ'
                              ? Colors.grey[400]
                              : Colors.yellow),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.dict['status'],
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          widget.isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 48,
              child: IconButton(
                onPressed: () {},
                icon: FaIcon(
                  FontAwesomeIcons.ellipsisVertical,
                  size: 16,
                  color: widget.isDark ? Colors.grey[400] : Colors.grey[400],
                ),
                style: IconButton.styleFrom(
                  backgroundColor: _isHovered
                      ? (widget.isDark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.grey[200])
                      : Colors.transparent,
                  shape: const CircleBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
