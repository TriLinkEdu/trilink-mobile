import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ParentAnnouncementsScreen extends StatefulWidget {
  const ParentAnnouncementsScreen({super.key});

  @override
  State<ParentAnnouncementsScreen> createState() =>
      _ParentAnnouncementsScreenState();
}

class _ParentAnnouncementsScreenState extends State<ParentAnnouncementsScreen> {
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'School', 'Class', 'Urgent'];

  final List<_AnnouncementItem> _announcements = [
    _AnnouncementItem(
      title: 'Mid-Term Exam Schedule Released',
      body:
          'The mid-term examination schedule for all classes has been finalized and published. '
          'Exams will run from April 6 to April 17. Students should review the detailed schedule '
          'posted on the school portal and begin preparations. Study guides for each subject are '
          'available from the respective teachers. Parents are encouraged to ensure their children '
          'maintain a balanced study and rest routine during this period.',
      date: 'Mar 22, 2026',
      source: 'Al-Noor International School',
      category: 'School',
      priority: _Priority.urgent,
    ),
    _AnnouncementItem(
      title: 'Science Fair – Call for Participants',
      body:
          'We are excited to announce the Annual Science Fair on April 5. Students from grades 7-12 '
          'are invited to submit project proposals. Teams of up to 3 are allowed. Projects must '
          'relate to sustainability, technology, or health. Submission deadline for proposals is '
          'March 28. Winners will receive certificates and prizes.',
      date: 'Mar 21, 2026',
      source: 'Al-Noor International School',
      category: 'School',
      priority: _Priority.normal,
    ),
    _AnnouncementItem(
      title: 'Mathematics Extra Help Sessions',
      body:
          'Mr. Ahmed Hassan will be holding extra mathematics help sessions every Wednesday '
          'from 2:00 PM to 3:30 PM in Room 201. These sessions are open to all Grade 10 '
          'students who need additional support before the mid-term exams. No registration '
          'is required—just show up with your questions.',
      date: 'Mar 20, 2026',
      source: 'Mr. Ahmed Hassan',
      category: 'Class',
      priority: _Priority.normal,
    ),
    _AnnouncementItem(
      title: 'Urgent: School Closure Due to Weather',
      body:
          'Due to the severe weather advisory issued for tomorrow, school will be closed on March 24. '
          'All classes will be conducted online via the school platform. Teachers will share '
          'virtual classroom links by 7:30 AM. Please ensure your child has internet access. '
          'Regular in-person classes will resume on March 25.',
      date: 'Mar 23, 2026',
      source: 'Al-Noor International School',
      category: 'School',
      priority: _Priority.urgent,
    ),
    _AnnouncementItem(
      title: 'Grade 7B English Book Report Due',
      body:
          'Reminder: The English book report assignment for Grade 7B is due on March 27. '
          'Students must submit a 500-word report on their chosen novel. Late submissions '
          'will receive a 10% penalty per day. If you have questions, please reach out to '
          'Mrs. Sarah Johnson during office hours.',
      date: 'Mar 19, 2026',
      source: 'Mrs. Sarah Johnson',
      category: 'Class',
      priority: _Priority.normal,
    ),
    _AnnouncementItem(
      title: 'Parent-Teacher Conference Dates',
      body:
          'Parent-teacher conferences are scheduled for March 28 and March 29. '
          'Appointments can be booked through the school portal starting March 24. '
          'Each session is 15 minutes. Please arrive 5 minutes early. If you cannot '
          'attend in person, virtual sessions are available upon request.',
      date: 'Mar 18, 2026',
      source: 'Al-Noor International School',
      category: 'School',
      priority: _Priority.normal,
    ),
  ];

  List<_AnnouncementItem> get _filteredAnnouncements {
    if (_selectedFilter == 'All') return _announcements;
    if (_selectedFilter == 'Urgent') {
      return _announcements.where((a) => a.priority == _Priority.urgent).toList();
    }
    return _announcements.where((a) => a.category == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Announcements',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredAnnouncements.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.campaign_outlined,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No announcements',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    itemCount: _filteredAnnouncements.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _AnnouncementCard(
                        announcement: _filteredAnnouncements[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AnnouncementCard extends StatefulWidget {
  final _AnnouncementItem announcement;

  const _AnnouncementCard({required this.announcement});

  @override
  State<_AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<_AnnouncementCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.announcement;
    final isUrgent = a.priority == _Priority.urgent;

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUrgent
                ? AppColors.error.withValues(alpha: 0.3)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    a.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isUrgent) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Urgent',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              a.body,
              maxLines: _isExpanded ? null : 2,
              overflow: _isExpanded ? null : TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    a.source,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  a.date,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            if (!_isExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Tap to read more',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _Priority { normal, urgent }

class _AnnouncementItem {
  final String title;
  final String body;
  final String date;
  final String source;
  final String category;
  final _Priority priority;

  _AnnouncementItem({
    required this.title,
    required this.body,
    required this.date,
    required this.source,
    required this.category,
    required this.priority,
  });
}
