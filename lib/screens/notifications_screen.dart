import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rattil/providers/theme_provider.dart';
import 'package:rattil/utils/theme_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final bgColor = isDarkMode ? ThemeColors.darkBg : ThemeColors.lightBg;
    final cardColor = isDarkMode ? ThemeColors.darkCard : ThemeColors.lightCard;
    final textColor = isDarkMode ? ThemeColors.darkText : ThemeColors.lightText;
    final subtitleColor = isDarkMode ? ThemeColors.darkSubtitle : ThemeColors.lightSubtitle;

    // Sample notifications data
    final List<Map<String, dynamic>> notifications = [
      {
        'icon': Icons.celebration,
        'iconColor': Color(0xFFF59E0B),
        'iconBg': Color(0xFFFEF3C7),
        'title': 'Welcome to Rattil!',
        'message': 'Start your Quran learning journey today. Explore our packages.',
        'time': '2 min ago',
        'isRead': false,
      },
      {
        'icon': Icons.schedule,
        'iconColor': Color(0xFF3B82F6),
        'iconBg': Color(0xFFDBEAFE),
        'title': 'Class Reminder',
        'message': 'Your next Quran class is scheduled for tomorrow at 10:00 AM.',
        'time': '1 hour ago',
        'isRead': false,
      },
      {
        'icon': Icons.payment,
        'iconColor': Color(0xFF22C55E),
        'iconBg': Color(0xFFDCFCE7),
        'title': 'Payment Successful',
        'message': 'Your payment for Premium Intensive package has been confirmed.',
        'time': '3 hours ago',
        'isRead': true,
      },
      {
        'icon': Icons.star,
        'iconColor': Color(0xFF8B5CF6),
        'iconBg': Color(0xFFEDE9FE),
        'title': 'Achievement Unlocked!',
        'message': 'Congratulations! You completed your first week of classes.',
        'time': '1 day ago',
        'isRead': true,
      },
      {
        'icon': Icons.campaign,
        'iconColor': Color(0xFFEC4899),
        'iconBg': Color(0xFFFCE7F3),
        'title': 'Special Offer',
        'message': 'Get 20% off on yearly subscription. Limited time offer!',
        'time': '2 days ago',
        'isRead': true,
      },
      {
        'icon': Icons.person,
        'iconColor': Color(0xFF14b8a6),
        'iconBg': Color(0xFFCCFBF1),
        'title': 'Profile Updated',
        'message': 'Your profile information has been updated successfully.',
        'time': '3 days ago',
        'isRead': true,
      },
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: textColor, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Mark all as read
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('All notifications marked as read'),
                  backgroundColor: ThemeColors.primaryTeal,
                ),
              );
            },
            child: Text(
              'Mark all read',
              style: TextStyle(color: ThemeColors.primaryTeal, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: subtitleColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ll notify you when something arrives',
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitleColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final bool isRead = notification['isRead'];
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isRead ? cardColor : (isDarkMode ? Color(0xFF1E3A5F) : Color(0xFFE0F2FE)),
                    borderRadius: BorderRadius.circular(12),
                    border: !isRead
                        ? Border.all(color: ThemeColors.primaryTeal.withOpacity(0.3), width: 1)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        // Handle notification tap
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isDarkMode 
                                    ? notification['iconColor'].withOpacity(0.2)
                                    : notification['iconBg'],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                notification['icon'],
                                color: notification['iconColor'],
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notification['title'],
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: ThemeColors.primaryTeal,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notification['message'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: subtitleColor,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    notification['time'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: subtitleColor.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
