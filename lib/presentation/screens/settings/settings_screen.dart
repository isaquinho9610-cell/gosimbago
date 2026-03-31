import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/glass/glass_card.dart';
import '../../widgets/glass/glass_scaffold.dart';
import '../../widgets/glass/glass_button.dart';
import '../../widgets/ssu_logo.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;

    return GlassScaffold(
      appBar: GlassAppBar(title: AppStrings.settingsTitle),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App info
          GlassCard(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                const SsuLogo(size: 52),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GoSimbaGo', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('숭실대학교 국제처 업무관리', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    Text('v1.0.0', style: TextStyle(color: AppColors.textHint, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          // 계정 정보
          GlassCard(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person_outline, color: AppColors.lightBlue, size: 18),
                    SizedBox(width: 8),
                    Text('계정', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, color: AppColors.textHint, size: 14),
                    const SizedBox(width: 8),
                    Text(user?.email ?? '-',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 16),
                GlassButton(
                  label: '로그아웃',
                  isPrimary: false,
                  isFullWidth: true,
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                  },
                ),
              ],
            ),
          ),

          // 데이터 안내
          GlassCard(
            opacity: 0.08,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cloud_done_outlined, color: AppColors.lightBlue, size: 16),
                    SizedBox(width: 8),
                    Text('데이터 동기화', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '모든 데이터는 클라우드에 자동 저장됩니다.\n'
                  '같은 계정으로 로그인하면 어디서든 동일한 데이터를 사용할 수 있습니다.\n\n'
                  '지원 플랫폼: macOS, Windows, iOS (웹브라우저)',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
