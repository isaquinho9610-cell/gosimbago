import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/glass/glass_card.dart';
import '../../widgets/glass/glass_scaffold.dart';
import '../../widgets/glass/glass_button.dart';
import '../../widgets/ssu_logo.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;

    setState(() => _isSaving = true);
    await ref.read(settingsNotifierProvider.notifier).saveApiKey(key);
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.settingsApiKeySaved),
          backgroundColor: AppColors.statusCompleted,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsNotifierProvider);

    // Pre-fill controller when key is loaded
    settingsAsync.whenData((key) {
      if (key != null && _apiKeyController.text.isEmpty) {
        _apiKeyController.text = key;
      }
    });

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

          // API Key section
          GlassCard(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.key_outlined, color: AppColors.lightBlue, size: 18),
                    const SizedBox(width: 8),
                    const Text(AppStrings.settingsApiKey, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    settingsAsync.when(
                      data: (key) => key != null && key.isNotEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.statusCompleted.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('설정됨', style: TextStyle(color: AppColors.statusCompleted, fontSize: 11)),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.statusPending.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('미설정', style: TextStyle(color: AppColors.statusPending, fontSize: 11)),
                            ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'OpenRouter API 키를 입력하세요. AI 요약 기능에 사용됩니다.',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _apiKeyController,
                  obscureText: _obscureKey,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: AppStrings.settingsApiKeyHint,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureKey ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textHint, size: 18),
                      onPressed: () => setState(() => _obscureKey = !_obscureKey),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        label: _isSaving ? '저장 중...' : AppStrings.actionSave,
                        onPressed: _isSaving ? null : _saveKey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GlassButton(
                      label: '삭제',
                      isPrimary: false,
                      onPressed: () async {
                        await ref.read(settingsNotifierProvider.notifier).clearApiKey();
                        _apiKeyController.clear();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // OpenRouter info
          GlassCard(
            opacity: 0.08,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.lightBlue, size: 16),
                    SizedBox(width: 8),
                    Text('OpenRouter API 키 발급', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. openrouter.ai 에서 회원가입\n'
                  '2. API Keys 메뉴에서 키 발급\n'
                  '3. 위 입력란에 붙여넣기\n\n'
                  '사용 모델: claude-sonnet-4-6\n'
                  '키는 기기의 보안 저장소에 안전하게 보관됩니다.',
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
