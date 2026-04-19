import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// 第十二章：实战项目 — 天气查询 App
// 综合运用：AsyncNotifier、Provider 组合、依赖注入、错误处理、搜索历史
// =============================================================================

// -----------------------------------------------------------------------------
// 1. 数据模型
// -----------------------------------------------------------------------------

class WeatherData {
  final String city;
  final double temperature;
  final String description;
  final int humidity;
  final double windSpeed;
  final String icon;
  final DateTime queriedAt;

  const WeatherData({
    required this.city,
    required this.temperature,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.icon,
    required this.queriedAt,
  });
}

// -----------------------------------------------------------------------------
// 2. Repository 层（依赖注入）
// -----------------------------------------------------------------------------

/// 天气 Repository 接口
abstract class WeatherRepository {
  Future<WeatherData> getWeather(String city);
}

/// 模拟实现（真实项目中替换为 API 调用）
class MockWeatherRepository implements WeatherRepository {
  final _random = Random();

  // 模拟天气数据
  static const _weatherTypes = [
    ('☀️', '晴天'),
    ('⛅', '多云'),
    ('🌧️', '小雨'),
    ('⛈️', '雷暴'),
    ('🌨️', '小雪'),
    ('🌤️', '晴间多云'),
    ('🌫️', '雾'),
  ];

  @override
  Future<WeatherData> getWeather(String city) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 800 + Random().nextInt(700)));

    // 模拟错误（城市名包含 "error"）
    if (city.toLowerCase().contains('error')) {
      throw Exception('无法获取 "$city" 的天气信息：网络连接超时');
    }

    final weather = _weatherTypes[_random.nextInt(_weatherTypes.length)];

    return WeatherData(
      city: city,
      temperature: 10 + _random.nextDouble() * 25,
      description: weather.$2,
      humidity: 30 + _random.nextInt(60),
      windSpeed: _random.nextDouble() * 30,
      icon: weather.$1,
      queriedAt: DateTime.now(),
    );
  }
}

/// ✅ Repository Provider（测试时可 override）
final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return MockWeatherRepository();
});

// -----------------------------------------------------------------------------
// 3. ViewModel 层：AsyncNotifier
// -----------------------------------------------------------------------------

/// 天气查询 AsyncNotifier
class WeatherNotifier extends AsyncNotifier<WeatherData?> {
  @override
  Future<WeatherData?> build() async {
    // 初始状态：没有数据
    return null;
  }

  /// 搜索城市天气
  Future<void> searchCity(String city) async {
    if (city.trim().isEmpty) return;

    state = const AsyncLoading();

    final repo = ref.read(weatherRepositoryProvider);
    state = await AsyncValue.guard(() => repo.getWeather(city.trim()));

    // 成功后记录搜索历史
    if (state.hasValue && state.value != null) {
      ref.read(searchHistoryProvider.notifier).addSearch(city.trim());
    }
  }

  /// 重试上次搜索
  Future<void> retry() async {
    final lastCity = state.value?.city ??
        ref.read(searchHistoryProvider).firstOrNull;
    if (lastCity != null) {
      await searchCity(lastCity);
    }
  }

  /// 清除天气数据
  void clear() {
    state = const AsyncData(null);
  }
}

final weatherProvider =
    AsyncNotifierProvider<WeatherNotifier, WeatherData?>(WeatherNotifier.new);

// -----------------------------------------------------------------------------
// 4. 搜索历史 Notifier
// -----------------------------------------------------------------------------

class SearchHistoryNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void addSearch(String city) {
    // 去重，最新的排在前面
    final newList = [city, ...state.where((c) => c != city)];
    // 最多保留 10 条
    state = newList.take(10).toList();
  }

  void removeSearch(String city) {
    state = state.where((c) => c != city).toList();
  }

  void clearAll() => state = [];
}

final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<String>>(
        SearchHistoryNotifier.new);

// -----------------------------------------------------------------------------
// 5. 派生 Provider
// -----------------------------------------------------------------------------

/// 最近 5 条搜索
final recentSearchesProvider = Provider<List<String>>((ref) {
  return ref.watch(searchHistoryProvider).take(5).toList();
});

/// 是否有天气数据
final hasWeatherDataProvider = Provider<bool>((ref) {
  final weather = ref.watch(weatherProvider);
  return weather.hasValue && weather.value != null;
});

// -----------------------------------------------------------------------------
// 6. 入口（带 ProviderObserver）
// -----------------------------------------------------------------------------

class _WeatherObserver extends ProviderObserver {
  @override
  void didUpdateProvider(ProviderBase<Object?> provider, Object? previousValue,
      Object? newValue, ProviderContainer container) {
    debugPrint('📊 [Weather] ${provider.name ?? provider.runtimeType} 更新');
  }
}

void main() {
  runApp(
    ProviderScope(
      observers: [_WeatherObserver()],
      child: const Ch12App(),
    ),
  );
}

class Ch12App extends StatelessWidget {
  const Ch12App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ch12 - 天气查询',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const WeatherPage(),
    );
  }
}

// -----------------------------------------------------------------------------
// 7. 天气查询页面
// -----------------------------------------------------------------------------

class WeatherPage extends ConsumerStatefulWidget {
  const WeatherPage({super.key});

  @override
  ConsumerState<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends ConsumerState<WeatherPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search([String? city]) {
    final query = city ?? _searchController.text;
    if (query.isEmpty) return;
    _searchController.text = query;
    ref.read(weatherProvider.notifier).searchCity(query);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(weatherProvider);
    final recentSearches = ref.watch(recentSearchesProvider);

    // 副作用：查询失败时显示 SnackBar
    ref.listen(weatherProvider, (prev, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${next.error}'),
            action: SnackBarAction(
              label: '重试',
              onPressed: () => ref.read(weatherProvider.notifier).retry(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('🌤️ 天气查询'),
        centerTitle: true,
        actions: [
          if (ref.watch(hasWeatherDataProvider))
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => ref.read(weatherProvider.notifier).clear(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 搜索栏
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '输入城市名（如：北京、上海、error 触发错误）',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _search,
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: _search,
            ),
            const SizedBox(height: 12),

            // 快捷搜索
            Wrap(
              spacing: 8,
              children: ['北京', '上海', '广州', '深圳', '杭州', '成都'].map((city) {
                return ActionChip(
                  label: Text(city),
                  onPressed: () => _search(city),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 天气结果
            weatherAsync.when(
              loading: () => const _WeatherLoading(),
              error: (error, _) => _WeatherError(
                error: error,
                onRetry: () => ref.read(weatherProvider.notifier).retry(),
              ),
              data: (weather) => weather == null
                  ? const _WeatherEmpty()
                  : _WeatherCard(weather: weather),
            ),
            const SizedBox(height: 24),

            // 搜索历史
            if (recentSearches.isNotEmpty) ...[
              Row(
                children: [
                  const Text('🕐 搜索历史',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        ref.read(searchHistoryProvider.notifier).clearAll(),
                    child: const Text('清空'),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: recentSearches.map((city) {
                  return InputChip(
                    label: Text(city),
                    onPressed: () => _search(city),
                    onDeleted: () => ref
                        .read(searchHistoryProvider.notifier)
                        .removeSearch(city),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 8. UI 组件
// -----------------------------------------------------------------------------

class _WeatherLoading extends StatelessWidget {
  const _WeatherLoading();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在查询天气...'),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherEmpty extends StatelessWidget {
  const _WeatherEmpty();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Text('🌍', style: TextStyle(fontSize: 48)),
              SizedBox(height: 8),
              Text('输入城市名查询天气'),
              Text('点击上方城市芯片快速查询',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _WeatherError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text('$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  final WeatherData weather;
  const _WeatherCard({required this.weather});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 城市和图标
            Text(weather.icon, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 8),
            Text(weather.city,
                style: Theme.of(context).textTheme.headlineMedium),
            Text(weather.description,
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 16),

            // 温度
            Text(
              '${weather.temperature.toStringAsFixed(1)}°C',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 详细信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _infoItem(Icons.water_drop, '湿度', '${weather.humidity}%'),
                _infoItem(Icons.air, '风速', '${weather.windSpeed.toStringAsFixed(1)} m/s'),
                _infoItem(Icons.access_time, '查询时间',
                    '${weather.queriedAt.hour}:${weather.queriedAt.minute.toString().padLeft(2, '0')}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue.shade300),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

// =============================================================================
// 知识点总结 — 综合运用：
//
// 1. ProviderScope + ProviderObserver（Ch01/Ch09）
// 2. Provider<WeatherRepository> 依赖注入（Ch02/Ch08）
// 3. NotifierProvider 管理搜索历史（Ch03）
// 4. ref.watch/read/listen（Ch04）
// 5. AsyncNotifier 管理异步天气数据（Ch05）
// 6. 派生 Provider（recentSearches、hasWeatherData）（Ch08）
// 7. AsyncValue.when 三态 UI（Ch05）
// 8. 错误处理与重试（Ch05/Ch11）
// 9. 分层架构：Repository → Notifier → UI（Ch11）
// =============================================================================
