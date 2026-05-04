import 'package:flutter/material.dart';
import 'package:tictactoe_game/constants/app_colors.dart';
import 'package:tictactoe_game/constants/app_sizes.dart';

class HelpDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _HelpDialogContent(),
    );
  }
}

class _HelpDialogContent extends StatelessWidget {
  const _HelpDialogContent();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        '游戏玩法说明',
        style: TextStyle(
          fontSize: AppSizes.winDialogTitleFontSize,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Section(title: '【游戏简介】', content: '这是一款创新的井字棋游戏，每方最多同时存在3个棋子，超过后会自动移除最早放置的棋子。'),
            _Section(title: '【玩家】', content: 'X（×）先手，O（○）后手'),
            _Section(title: '【棋盘】', content: '3×3 格子，共9个位置'),
            _Section(
              title: '【基本规则】',
              content: '1. 两名玩家轮流在棋盘上放置自己的棋子\n2. 点击任意空白格子即可落子\n3. 先将 3 个自己的棋子连成一线者获胜\n4. 连线可以是：横向、纵向、斜对角线',
            ),
            _Section(
              title: '【创新机制：动态棋子移除】',
              content: '这是本游戏与传统井字棋最大的区别：\n\n- 每名玩家最多同时在棋盘上存在 3 个棋子\n- 当玩家已有 3 个棋子时，再放新棋子会自动移除该玩家最早放置的那个棋子\n- 传统井字棋可能出现平局，但本游戏可以无限进行下去',
            ),
            _Section(
              title: '【获胜条件】',
              content: '横向 3 子连线\n纵向 3 子连线\n斜向 3 子连线',
            ),
            _Section(
              title: '【策略提示】',
              content: '1. 因为棋子会被移除，防守往往比进攻更重要\n2. 注意观察自己和对手的棋子放置顺序\n3. 利用"旧棋子会被移除"的规则进行布局\n4. 点击"重新开始"按钮可以随时重置游戏\n5. 点击"撤销"按钮可以回到上一步',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '关闭',
            style: TextStyle(
              fontSize: AppSizes.buttonFontSize,
              color: AppColors.buttonPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;

  const _Section({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontSize: 14.0,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.0,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
