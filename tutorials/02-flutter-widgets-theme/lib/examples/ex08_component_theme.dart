import 'package:flutter/material.dart';

/// 第8章示例：组件级主题定制
///
/// 演示如何通过 ThemeData 中的组件主题属性统一定制
/// ElevatedButton、OutlinedButton、TextField、Card、Chip 等组件的外观，
/// 并提供"默认主题 vs 定制主题"的对比展示。
class ComponentThemeExample extends StatelessWidget {
  const ComponentThemeExample({super.key});

  /// 品牌主色
  static const _brandPrimary = Color(0xFF6750A4);

  /// 定制后的完整组件主题
  static ThemeData _buildCustomTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      // ---- ElevatedButton: 胶囊形，品牌色 ----
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _brandPrimary,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          elevation: 2,
        ),
      ),

      // ---- OutlinedButton: 同样胶囊形，品牌色边框 ----
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _brandPrimary,
          side: const BorderSide(color: _brandPrimary, width: 1.5),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ---- TextField: 填充式圆角，聚焦时品牌色下划线 ----
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0EBF8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _brandPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: TextStyle(color: Colors.grey[600]),
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),

      // ---- Card: 12px 圆角，微妙阴影 ----
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: Colors.black.withAlpha(40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ---- Chip: 圆角胶囊，品牌配色 ----
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF0EBF8),
        labelStyle: const TextStyle(
          color: _brandPrimary,
          fontWeight: FontWeight.w500,
        ),
        shape: const StadiumBorder(),
        side: BorderSide(color: _brandPrimary.withAlpha(60)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('第8章：组件级主题')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 说明文字
            Text('默认主题 vs 定制主题', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '左侧为默认主题组件，右侧为通过组件主题定制后的组件。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),

            // ---- 对比区域 ----
            _ComparisonSection(
              title: '按钮',
              defaultSide: const _DefaultButtons(),
              customSide: Builder(
                builder: (ctx) => Theme(
                  data: _buildCustomTheme(ctx),
                  child: const _CustomButtons(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            _ComparisonSection(
              title: '输入框',
              defaultSide: const _DefaultTextField(),
              customSide: Builder(
                builder: (ctx) => Theme(
                  data: _buildCustomTheme(ctx),
                  child: const _CustomTextField(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            _ComparisonSection(
              title: '卡片',
              defaultSide: const _DefaultCard(),
              customSide: Builder(
                builder: (ctx) => Theme(
                  data: _buildCustomTheme(ctx),
                  child: const _CustomCard(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            _ComparisonSection(
              title: '标签 (Chip)',
              defaultSide: const _DefaultChips(),
              customSide: Builder(
                builder: (ctx) => Theme(
                  data: _buildCustomTheme(ctx),
                  child: const _CustomChips(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ---- 完整定制展示区 ----
            Text('完整定制效果', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Builder(
              builder: (ctx) => Theme(
                data: _buildCustomTheme(ctx),
                child: const _FullCustomShowcase(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 对比区域框架
// ============================================================================

/// 左右对比区域
class _ComparisonSection extends StatelessWidget {
  final String title;
  final Widget defaultSide;
  final Widget customSide;

  const _ComparisonSection({
    required this.title,
    required this.defaultSide,
    required this.customSide,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左边：默认主题
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '默认',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    defaultSide,
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 右边：定制主题
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF8FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ComponentThemeExample._brandPrimary.withAlpha(60),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '定制',
                      style: TextStyle(
                        fontSize: 12,
                        color: ComponentThemeExample._brandPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    customSide,
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// 默认主题组件
// ============================================================================

class _DefaultButtons extends StatelessWidget {
  const _DefaultButtons();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(onPressed: () {}, child: const Text('确认')),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: () {}, child: const Text('取消')),
      ],
    );
  }
}

class _DefaultTextField extends StatelessWidget {
  const _DefaultTextField();

  @override
  Widget build(BuildContext context) {
    return const TextField(
      decoration: InputDecoration(labelText: '用户名', hintText: '请输入...'),
    );
  }
}

class _DefaultCard extends StatelessWidget {
  const _DefaultCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('默认卡片', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('这是默认样式', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _DefaultChips extends StatelessWidget {
  const _DefaultChips();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        Chip(label: Text('Flutter')),
        Chip(label: Text('Dart')),
        Chip(label: Text('主题')),
      ],
    );
  }
}

// ============================================================================
// 定制主题组件（样式来自 Theme，无需手动指定）
// ============================================================================

class _CustomButtons extends StatelessWidget {
  const _CustomButtons();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(onPressed: () {}, child: const Text('确认')),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: () {}, child: const Text('取消')),
      ],
    );
  }
}

class _CustomTextField extends StatelessWidget {
  const _CustomTextField();

  @override
  Widget build(BuildContext context) {
    return const TextField(
      decoration: InputDecoration(labelText: '用户名', hintText: '请输入...'),
    );
  }
}

class _CustomCard extends StatelessWidget {
  const _CustomCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('定制卡片', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('12px 圆角 + 微阴影', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _CustomChips extends StatelessWidget {
  const _CustomChips();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        Chip(label: Text('Flutter')),
        Chip(label: Text('Dart')),
        Chip(label: Text('主题')),
      ],
    );
  }
}

// ============================================================================
// 完整定制效果展示区
// ============================================================================

class _FullCustomShowcase extends StatelessWidget {
  const _FullCustomShowcase();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: ComponentThemeExample._brandPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  '完整组件主题演示',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 输入框
            const TextField(
              decoration: InputDecoration(
                labelText: '邮箱地址',
                hintText: 'user@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: '密码',
                hintText: '请输入密码',
                prefixIcon: Icon(Icons.lock_outlined),
                suffixIcon: Icon(Icons.visibility_off_outlined),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            // 标签
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: Icon(Icons.star, size: 16),
                  label: Text('推荐'),
                ),
                Chip(
                  avatar: Icon(Icons.local_fire_department, size: 16),
                  label: Text('热门'),
                ),
                Chip(
                  avatar: Icon(Icons.new_releases, size: 16),
                  label: Text('最新'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('返回'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('登录'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
