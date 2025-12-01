import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import 'sidebar_item.dart';

class Sidebar extends StatelessWidget {
  final bool isDark;
  final int selectedIndex;
  final Function(int) onItemTap;

  const Sidebar({
    super.key,
    required this.isDark,
    required this.selectedIndex,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSidebar : AppColors.lightSidebar,
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF2A2A2A) : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // User Profile Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : AppColors.lightPrimary,
                    borderRadius: BorderRadius.circular(20),
                    gradient: isDark
                        ? null
                        : LinearGradient(
                            colors: [
                              AppColors.lightPrimary.withOpacity(0.7),
                              AppColors.lightPrimary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                  ),
                  child: Center(
                    child: Text(
                      'FL',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[300] : Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Flux User',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.grey[200]
                              : AppColors.lightPrimary,
                        ),
                      ),
                      Text(
                        'Premium Account',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : AppColors.lightPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigation Items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SidebarItem(
                    icon: FontAwesomeIcons.language,
                    label: 'Dịch thuật',
                    isActive: selectedIndex == 0,
                    onTap: () => onItemTap(0),
                    isDark: isDark,
                  ),
                  SidebarItem(
                    icon: FontAwesomeIcons.clockRotateLeft,
                    label: 'Lịch sử',
                    isActive: selectedIndex == 1,
                    onTap: () => onItemTap(1),
                    isDark: isDark,
                  ),
                  SidebarItem(
                    icon: FontAwesomeIcons.bookOpenReader,
                    label: 'Từ điển',
                    isActive: selectedIndex == 2,
                    onTap: () => onItemTap(2),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),

          // Settings at bottom
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.grey.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SidebarItem(
                icon: FontAwesomeIcons.gear,
                label: 'Cài đặt',
                isActive: selectedIndex == 3,
                onTap: () => onItemTap(3),
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
