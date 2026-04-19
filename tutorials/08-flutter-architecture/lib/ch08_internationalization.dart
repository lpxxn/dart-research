// =============================================================
// 第8章：国际化 —— 手写 Localizations 实现中英文切换
// =============================================================
//
// 本文件演示如何手动实现 Flutter 的国际化机制，
// 包括自定义 LocalizationsDelegate、Locale 切换和日期/数字格式化。
//
// 运行方式: flutter run -t lib/ch08_internationalization.dart
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

void main() => runApp(const Ch08App());

// =============================================================
// 一、自定义 AppLocalizations —— 包含所有翻译文本
// =============================================================

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  /// 通过 BuildContext 获取当前语言的翻译实例
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// 本地化代理 —— 需要在 MaterialApp 中注册
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// 所有翻译数据
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Chapter 8: Internationalization',
      'hello': 'Hello!',
      'welcome': 'Welcome to Flutter i18n Demo',
      'currentLang': 'Current Language',
      'switchLang': 'Switch Language',
      'chinese': 'Chinese',
      'english': 'English',
      'dateFormat': 'Date Formatting',
      'numberFormat': 'Number Formatting',
      'today': 'Today',
      'currency': 'Currency',
      'percentage': 'Percentage',
      'largeNumber': 'Large Number',
      'greetingMorning': 'Good Morning! ☀️',
      'greetingAfternoon': 'Good Afternoon! 🌤️',
      'greetingEvening': 'Good Evening! 🌙',
      'counter': 'Counter',
      'items': 'items',
      'noItems': 'No items',
      'oneItem': '1 item',
      'pluralDemo': 'Plural Demo',
      'description':
          'This example demonstrates how to manually implement\n'
              'Flutter Localizations for Chinese/English switching.',
    },
    'zh': {
      'appTitle': '第8章：国际化',
      'hello': '你好！',
      'welcome': '欢迎来到 Flutter 国际化演示',
      'currentLang': '当前语言',
      'switchLang': '切换语言',
      'chinese': '中文',
      'english': '英语',
      'dateFormat': '日期格式化',
      'numberFormat': '数字格式化',
      'today': '今天',
      'currency': '货币',
      'percentage': '百分比',
      'largeNumber': '大数字',
      'greetingMorning': '早上好！☀️',
      'greetingAfternoon': '下午好！🌤️',
      'greetingEvening': '晚上好！🌙',
      'counter': '计数器',
      'items': '个项目',
      'noItems': '没有项目',
      'oneItem': '1 个项目',
      'pluralDemo': '复数演示',
      'description': '本示例演示如何手动实现 Flutter 的本地化机制，\n实现中英文切换。',
    },
  };

  // ---- 便捷 getter ----
  String get appTitle => _localizedValues[locale.languageCode]!['appTitle']!;
  String get hello => _localizedValues[locale.languageCode]!['hello']!;
  String get welcome => _localizedValues[locale.languageCode]!['welcome']!;
  String get currentLang =>
      _localizedValues[locale.languageCode]!['currentLang']!;
  String get switchLang =>
      _localizedValues[locale.languageCode]!['switchLang']!;
  String get chinese => _localizedValues[locale.languageCode]!['chinese']!;
  String get english => _localizedValues[locale.languageCode]!['english']!;
  String get dateFormat =>
      _localizedValues[locale.languageCode]!['dateFormat']!;
  String get numberFormat =>
      _localizedValues[locale.languageCode]!['numberFormat']!;
  String get today => _localizedValues[locale.languageCode]!['today']!;
  String get currency => _localizedValues[locale.languageCode]!['currency']!;
  String get percentage =>
      _localizedValues[locale.languageCode]!['percentage']!;
  String get largeNumber =>
      _localizedValues[locale.languageCode]!['largeNumber']!;
  String get counter => _localizedValues[locale.languageCode]!['counter']!;
  String get noItems => _localizedValues[locale.languageCode]!['noItems']!;
  String get oneItem => _localizedValues[locale.languageCode]!['oneItem']!;
  String get pluralDemo =>
      _localizedValues[locale.languageCode]!['pluralDemo']!;
  String get description =>
      _localizedValues[locale.languageCode]!['description']!;

  /// 根据时间返回问候语
  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return _localizedValues[locale.languageCode]!['greetingMorning']!;
    } else if (hour < 18) {
      return _localizedValues[locale.languageCode]!['greetingAfternoon']!;
    } else {
      return _localizedValues[locale.languageCode]!['greetingEvening']!;
    }
  }

  /// 复数处理 —— 不同语言复数规则不同
  String itemCount(int count) {
    if (locale.languageCode == 'zh') {
      if (count == 0) return noItems;
      return '$count 个项目';
    } else {
      if (count == 0) return noItems;
      if (count == 1) return oneItem;
      return '$count items';
    }
  }
}

// =============================================================
// 二、LocalizationsDelegate —— 加载翻译数据的代理
// =============================================================

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  /// 支持的语言列表
  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  /// 加载指定语言的翻译
  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  /// 语言变化时是否需要重新加载
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// =============================================================
// 三、语言状态管理 —— 使用 ValueNotifier 管理当前语言
// =============================================================

class LocaleNotifier extends ValueNotifier<Locale> {
  LocaleNotifier() : super(const Locale('zh', 'CN'));

  void switchToEnglish() => value = const Locale('en', 'US');
  void switchToChinese() => value = const Locale('zh', 'CN');

  void toggle() {
    if (value.languageCode == 'zh') {
      switchToEnglish();
    } else {
      switchToChinese();
    }
  }

  bool get isChinese => value.languageCode == 'zh';
}

// 全局语言通知器
final localeNotifier = LocaleNotifier();

// =============================================================
// 四、应用入口
// =============================================================

class Ch08App extends StatelessWidget {
  const Ch08App({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Ch08 i18n',
          theme: ThemeData(
            colorSchemeSeed: Colors.orange,
            useMaterial3: true,
          ),
          // 关键配置：本地化代理
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // 支持的语言列表
          supportedLocales: const [
            Locale('zh', 'CN'),
            Locale('en', 'US'),
          ],
          // 当前语言
          locale: locale,
          home: const I18nDemoPage(),
        );
      },
    );
  }
}

// =============================================================
// 五、演示页面
// =============================================================

class I18nDemoPage extends StatefulWidget {
  const I18nDemoPage({super.key});

  @override
  State<I18nDemoPage> createState() => _I18nDemoPageState();
}

class _I18nDemoPageState extends State<I18nDemoPage> {
  int _itemCount = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final localeStr = locale.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          // 语言切换按钮
          TextButton.icon(
            onPressed: () => localeNotifier.toggle(),
            icon: const Icon(Icons.language),
            label: Text(localeNotifier.isChinese ? 'EN' : '中'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- 欢迎区域 ----
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(l10n.greeting,
                        style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(l10n.welcome, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    Text(l10n.description,
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ---- 当前语言信息 ----
            _buildSectionCard(
              theme,
              icon: Icons.language,
              title: l10n.currentLang,
              child: Column(
                children: [
                  _infoRow(theme, 'Locale', localeStr),
                  _infoRow(theme, 'Language Code', locale.languageCode),
                  _infoRow(theme, 'Country Code', locale.countryCode ?? '-'),
                  const SizedBox(height: 12),
                  // 语言切换按钮
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => localeNotifier.switchToChinese(),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: localeNotifier.isChinese
                                ? theme.colorScheme.primaryContainer
                                : null,
                          ),
                          child: Text('🇨🇳 ${l10n.chinese}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => localeNotifier.switchToEnglish(),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: !localeNotifier.isChinese
                                ? theme.colorScheme.primaryContainer
                                : null,
                          ),
                          child: Text('🇺🇸 ${l10n.english}'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ---- 日期格式化 ----
            _buildSectionCard(
              theme,
              icon: Icons.calendar_today,
              title: l10n.dateFormat,
              child: _buildDateFormatSection(theme, localeStr),
            ),

            const SizedBox(height: 16),

            // ---- 数字格式化 ----
            _buildSectionCard(
              theme,
              icon: Icons.numbers,
              title: l10n.numberFormat,
              child: _buildNumberFormatSection(theme, l10n, localeStr),
            ),

            const SizedBox(height: 16),

            // ---- 复数演示 ----
            _buildSectionCard(
              theme,
              icon: Icons.format_list_numbered,
              title: l10n.pluralDemo,
              child: _buildPluralSection(theme, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Text(value,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 日期格式化演示
  Widget _buildDateFormatSection(ThemeData theme, String localeStr) {
    final now = DateTime.now();
    return Column(
      children: [
        _formatRow(theme, 'yMMMMd', DateFormat.yMMMMd(localeStr).format(now)),
        _formatRow(theme, 'yMd', DateFormat.yMd(localeStr).format(now)),
        _formatRow(
            theme, 'EEEE', DateFormat.EEEE(localeStr).format(now)),
        _formatRow(theme, 'Hm', DateFormat.Hm(localeStr).format(now)),
        _formatRow(theme, 'jms', DateFormat.jms(localeStr).format(now)),
        _formatRow(theme, 'yMMMEd',
            DateFormat.yMMMEd(localeStr).format(now)),
      ],
    );
  }

  // 数字格式化演示
  Widget _buildNumberFormatSection(
      ThemeData theme, AppLocalizations l10n, String localeStr) {
    return Column(
      children: [
        _formatRow(theme, l10n.largeNumber,
            NumberFormat('#,###', localeStr).format(1234567890)),
        _formatRow(
            theme,
            l10n.currency,
            NumberFormat.currency(
                    locale: localeStr,
                    symbol: localeStr.startsWith('zh') ? '¥' : '\$')
                .format(9999.99)),
        _formatRow(theme, l10n.percentage,
            NumberFormat.percentPattern(localeStr).format(0.8567)),
        _formatRow(theme, 'Compact',
            NumberFormat.compact(locale: localeStr).format(1234567)),
      ],
    );
  }

  Widget _formatRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 复数处理演示
  Widget _buildPluralSection(ThemeData theme, AppLocalizations l10n) {
    return Column(
      children: [
        Text(l10n.itemCount(_itemCount), style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filled(
              onPressed: () =>
                  setState(() => _itemCount = (_itemCount - 1).clamp(0, 999)),
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 16),
            Text('$_itemCount',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            IconButton.filled(
              onPressed: () => setState(() => _itemCount++),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [0, 1, 5, 42, 100].map((count) {
            return ActionChip(
              label: Text('$count'),
              onPressed: () => setState(() => _itemCount = count),
            );
          }).toList(),
        ),
      ],
    );
  }
}
