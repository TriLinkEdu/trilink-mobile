import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// AI Assistant with Learning Path, Resources, and Evaluate Me tabs.
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Learning Path', 'Resources', 'Evaluate M...'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                children: [
                  // Logo
                  Icon(Icons.auto_awesome, color: AppColors.primary, size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Assistant',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final isSelected = _selectedTab == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          _tabs[i],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 6),

            // Content
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: const [
                  _LearningPathTab(),
                  _ResourcesTab(),
                  _EvaluateTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      // FAB
      floatingActionButton: FloatingActionButton.small(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
      ),
    );
  }
}

// ─── Learning Path Tab ───────────────────────────────────────────────────────

class _LearningPathTab extends StatelessWidget {
  const _LearningPathTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Personalized Path',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Curated specifically for you based on your recent quiz results in Physics and Mathematics.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Path items
          const _PathItem(
            index: 1,
            icon: Icons.rocket_launch_rounded,
            title: 'Forces & Motion',
            subject: 'Physics',
            duration: '15 min',
            progress: 0.6,
            isActive: true,
          ),
          const SizedBox(height: 14),
          const _PathItem(
            index: 2,
            icon: Icons.precision_manufacturing_rounded,
            title: "Newton's Laws",
            subject: 'Physics',
            duration: '20 min',
            progress: 0.0,
            isActive: false,
          ),
          const SizedBox(height: 14),
          const _PathItem(
            index: 3,
            icon: Icons.speed_rounded,
            title: 'Friction & Gravity',
            subject: 'Physics',
            duration: '10 min',
            progress: 0.0,
            isActive: false,
          ),
          const SizedBox(height: 20),

          // AI Insight
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withAlpha(25),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Insight',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "You seem to learn faster with visual aids. We've prioritized video content for your next topics.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PathItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String title;
  final String subject;
  final String duration;
  final double progress;
  final bool isActive;

  const _PathItem({
    required this.index,
    required this.icon,
    required this.title,
    required this.subject,
    required this.duration,
    required this.progress,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withAlpha(60)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$index. $title',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$subject • $duration',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.bookmark_border_rounded,
                color: Colors.grey.shade400,
                size: 22,
              ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppColors.primary.withAlpha(30),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continue',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.play_arrow_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Start',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Resources Tab ───────────────────────────────────────────────────────────

class _ResourcesTab extends StatelessWidget {
  const _ResourcesTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'AI-curated study resources coming soon',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

// ─── Evaluate Tab ────────────────────────────────────────────────────────────

class _EvaluateTab extends StatelessWidget {
  const _EvaluateTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'AI evaluation coming soon',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
