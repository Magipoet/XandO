import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tictactoe_game/constants/app_colors.dart';
import 'package:tictactoe_game/constants/app_sizes.dart';
import 'package:tictactoe_game/models/board_size.dart';
import 'package:tictactoe_game/models/piece_size.dart';
import 'package:tictactoe_game/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          '设置',
          style: TextStyle(
            fontSize: AppSizes.titleFontSize,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: '返回',
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('加载设置失败'),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () => ref.refresh(settingsProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSection(
                title: '棋盘大小',
                child: _buildBoardSizeSelector(settings.boardSize, ref),
              ),
              const SizedBox(height: 24.0),
              _buildSection(
                title: '棋子大小',
                child: _buildPieceSizeSelector(settings.pieceSize, ref),
              ),
              const SizedBox(height: 24.0),
              _buildInfoCard(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12.0),
        child,
      ],
    );
  }

  Widget _buildBoardSizeSelector(BoardSize currentValue, WidgetRef ref) {
    return Column(
      children: BoardSize.values.map((size) {
        return RadioListTile<BoardSize>(
          title: Text(
            size.label,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          subtitle: Text(
            '屏幕宽度的 ${(size.widthRatio * 100).toInt()}%',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          value: size,
          groupValue: currentValue,
          activeColor: AppColors.buttonPrimary,
          onChanged: (value) {
            if (value != null) {
              ref.read(settingsProvider.notifier).setBoardSize(value);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildPieceSizeSelector(PieceSize currentValue, WidgetRef ref) {
    return Column(
      children: PieceSize.values.map((size) {
        return RadioListTile<PieceSize>(
          title: Text(
            size.label,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          subtitle: Text(
            '格子大小的 ${(size.cellRatio * 100).toInt()}%',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          value: size,
          groupValue: currentValue,
          activeColor: AppColors.buttonPrimary,
          onChanged: (value) {
            if (value != null) {
              ref.read(settingsProvider.notifier).setPieceSize(value);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: AppColors.boardBackground,
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '提示',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              '设置会自动保存，下次打开游戏时会恢复您的偏好设置。',
              style: TextStyle(
                fontSize: 13.0,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
