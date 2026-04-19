import 'package:flutter/material.dart';

/// 第7章：对话框与底部弹窗
/// 展示各种对话框和弹窗效果：
/// AlertDialog、SimpleDialog、showGeneralDialog、
/// ModalBottomSheet、DraggableScrollableSheet、
/// SnackBar、MaterialBanner、DatePicker、TimePicker
void main() => runApp(const Ch07App());

class Ch07App extends StatelessWidget {
  const Ch07App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ch07 对话框与底部弹窗',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const DialogDemoHome(),
    );
  }
}

// ============================================================
// 首页：展示各种对话框和弹窗入口
// ============================================================
class DialogDemoHome extends StatelessWidget {
  const DialogDemoHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('对话框与底部弹窗')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('对话框 (Dialog)'),
          _DemoTile(
            title: 'AlertDialog',
            subtitle: '确认/取消对话框',
            icon: Icons.warning_amber,
            onTap: () => _showAlertDialog(context),
          ),
          _DemoTile(
            title: 'SimpleDialog',
            subtitle: '列表选择对话框',
            icon: Icons.list,
            onTap: () => _showSimpleDialog(context),
          ),
          _DemoTile(
            title: 'showGeneralDialog',
            subtitle: '自定义动画对话框（缩放效果）',
            icon: Icons.animation,
            onTap: () => _showCustomAnimatedDialog(context),
          ),

          const SizedBox(height: 16),
          _sectionTitle('底部弹窗 (Bottom Sheet)'),
          _DemoTile(
            title: 'Modal Bottom Sheet',
            subtitle: '模态底部弹窗（操作菜单）',
            icon: Icons.menu,
            onTap: () => _showModalSheet(context),
          ),
          _DemoTile(
            title: 'Draggable Bottom Sheet',
            subtitle: '可拖拽滚动底部弹窗',
            icon: Icons.drag_handle,
            onTap: () => _showDraggableSheet(context),
          ),

          const SizedBox(height: 16),
          _sectionTitle('提示消息'),
          _DemoTile(
            title: 'SnackBar',
            subtitle: '底部临时提示（带撤销操作）',
            icon: Icons.info_outline,
            onTap: () => _showSnackBar(context),
          ),
          _DemoTile(
            title: 'MaterialBanner',
            subtitle: '顶部持久提示栏',
            icon: Icons.campaign,
            onTap: () => _showBanner(context),
          ),

          const SizedBox(height: 16),
          _sectionTitle('选择器 (Picker)'),
          _DemoTile(
            title: 'DatePicker',
            subtitle: '日期选择器',
            icon: Icons.calendar_today,
            onTap: () => _showDate(context),
          ),
          _DemoTile(
            title: 'TimePicker',
            subtitle: '时间选择器',
            icon: Icons.access_time,
            onTap: () => _showTime(context),
          ),
          _DemoTile(
            title: 'DateRangePicker',
            subtitle: '日期范围选择器',
            icon: Icons.date_range,
            onTap: () => _showDateRange(context),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ============================================================
// 通用演示列表项
// ============================================================
class _DemoTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _DemoTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// ============================================================
// 1. AlertDialog：确认删除对话框
// ============================================================
Future<void> _showAlertDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // 点击外部不关闭
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.delete_forever, color: Colors.red, size: 40),
      title: const Text('确认删除'),
      content: const Text('此操作不可撤销，确定要删除这条记录吗？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('删除'),
        ),
      ],
    ),
  );

  if (!context.mounted) return;
  // 展示选择结果
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(confirmed == true ? '已删除' : '已取消'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ============================================================
// 2. SimpleDialog：列表选择
// ============================================================
Future<void> _showSimpleDialog(BuildContext context) async {
  final languages = [
    ('zh', '中文', Icons.translate),
    ('en', 'English', Icons.language),
    ('ja', '日本語', Icons.language),
    ('ko', '한국어', Icons.language),
  ];

  final result = await showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('选择语言'),
      children: languages.map((lang) {
        return SimpleDialogOption(
          onPressed: () => Navigator.pop(context, lang.$1),
          child: Row(
            children: [
              Icon(lang.$3),
              const SizedBox(width: 16),
              Text(lang.$2, style: const TextStyle(fontSize: 16)),
            ],
          ),
        );
      }).toList(),
    ),
  );

  if (!context.mounted || result == null) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('选择了: $result'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ============================================================
// 3. showGeneralDialog：自定义缩放动画对话框
// ============================================================
Future<void> _showCustomAnimatedDialog(BuildContext context) async {
  await showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    barrierDismissible: true,
    barrierLabel: '关闭',
    transitionDuration: const Duration(milliseconds: 350),
    // 自定义缩放 + 淡入动画
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: child,
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: Material(
          borderRadius: BorderRadius.circular(20),
          elevation: 8,
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.rocket_launch,
                  size: 60,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  '自定义动画对话框',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  '使用 showGeneralDialog 可以完全自定义对话框的进入和退出动画。',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// ============================================================
// 4. Modal Bottom Sheet：操作菜单
// ============================================================
Future<void> _showModalSheet(BuildContext context) async {
  final result = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true, // 显示拖拽手柄
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              '选择操作',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('拍照'),
            onTap: () => Navigator.pop(context, '拍照'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('从相册选择'),
            onTap: () => Navigator.pop(context, '相册'),
          ),
          ListTile(
            leading: const Icon(Icons.file_present),
            title: const Text('选择文件'),
            onTap: () => Navigator.pop(context, '文件'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.close, color: Colors.red),
            title: const Text('取消', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );

  if (!context.mounted || result == null) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('选择了: $result'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ============================================================
// 5. Draggable Bottom Sheet：可拖拽滚动列表
// ============================================================
Future<void> _showDraggableSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true, // 允许弹窗控制高度
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.5, // 初始高度 50%
      minChildSize: 0.25, // 最小 25%
      maxChildSize: 0.9, // 最大 90%
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // 拖拽手柄
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '可拖拽列表（上下拖动改变高度）',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const Divider(height: 1),
            // 滚动列表（必须使用提供的 scrollController）
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: 40,
                itemBuilder: (context, index) => ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text('列表项 ${index + 1}'),
                  subtitle: const Text('拖拽手柄或滚动列表'),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

// ============================================================
// 6. SnackBar：底部提示（带撤销操作）
// ============================================================
void _showSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('文件已移至回收站'),
      action: SnackBarAction(
        label: '撤销',
        onPressed: () {
          // 撤销操作
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已撤销'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ),
          );
        },
      ),
      behavior: SnackBarBehavior.floating, // 浮动样式
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ),
  );
}

// ============================================================
// 7. MaterialBanner：顶部持久提示
// ============================================================
void _showBanner(BuildContext context) {
  ScaffoldMessenger.of(context).showMaterialBanner(
    MaterialBanner(
      content: const Text('网络连接已断开，部分功能不可用'),
      leading: const Icon(Icons.wifi_off, color: Colors.orange),
      backgroundColor: Colors.orange.withValues(alpha: 0.1),
      actions: [
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
          },
          child: const Text('忽略'),
        ),
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            // 重试连接
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('正在重新连接...'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 1),
              ),
            );
          },
          child: const Text('重试'),
        ),
      ],
    ),
  );
}

// ============================================================
// 8. DatePicker：日期选择器
// ============================================================
Future<void> _showDate(BuildContext context) async {
  final date = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2030),
    helpText: '选择日期',
    cancelText: '取消',
    confirmText: '确定',
  );

  if (!context.mounted || date == null) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('选择日期: ${date.year}-${date.month}-${date.day}'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ============================================================
// 9. TimePicker：时间选择器
// ============================================================
Future<void> _showTime(BuildContext context) async {
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
    helpText: '选择时间',
    cancelText: '取消',
    confirmText: '确定',
  );

  if (!context.mounted || time == null) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('选择时间: ${time.hour}:${time.minute.toString().padLeft(2, '0')}'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ============================================================
// 10. DateRangePicker：日期范围选择器
// ============================================================
Future<void> _showDateRange(BuildContext context) async {
  final range = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2020),
    lastDate: DateTime(2030),
    helpText: '选择日期范围',
    cancelText: '取消',
    confirmText: '确定',
    saveText: '保存',
  );

  if (!context.mounted || range == null) return;
  final start = range.start;
  final end = range.end;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '日期范围: ${start.year}-${start.month}-${start.day}'
        ' 至 ${end.year}-${end.month}-${end.day}',
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
