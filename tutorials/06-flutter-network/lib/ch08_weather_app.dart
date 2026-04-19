import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// 第八章：天气 App 实战
/// 综合运用数据模型、HTTP 封装、Repository 模式、UI 交互

void main() => runApp(const Ch08App());

// ============================================================
// 数据模型
// ============================================================

/// 当前天气数据
class WeatherData {
  final String city;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String description;
  final String icon;
  final DateTime updatedAt;

  const WeatherData({
    required this.city,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.icon,
    required this.updatedAt,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      city: json['city'] as String,
      temperature: (json['temperature'] as num).toDouble(),
      feelsLike: (json['feelsLike'] as num).toDouble(),
      humidity: json['humidity'] as int,
      windSpeed: (json['windSpeed'] as num).toDouble(),
      description: json['description'] as String,
      icon: json['icon'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// 每日预报
class DailyForecast {
  final DateTime date;
  final double high;
  final double low;
  final String description;
  final String icon;

  const DailyForecast({
    required this.date,
    required this.high,
    required this.low,
    required this.description,
    required this.icon,
  });
}

// ============================================================
// 模拟 HTTP 客户端
// ============================================================

class MockWeatherApiClient {
  final _random = Random();

  /// 支持的城市列表
  static const List<String> supportedCities = [
    '北京', '上海', '广州', '深圳', '杭州',
    '成都', '武汉', '南京', '西安', '重庆',
  ];

  /// 天气描述和图标
  static const List<Map<String, String>> _weatherTypes = [
    {'desc': '晴', 'icon': '☀️'},
    {'desc': '多云', 'icon': '⛅'},
    {'desc': '阴', 'icon': '☁️'},
    {'desc': '小雨', 'icon': '🌦️'},
    {'desc': '大雨', 'icon': '🌧️'},
    {'desc': '雷阵雨', 'icon': '⛈️'},
    {'desc': '雪', 'icon': '❄️'},
  ];

  /// 模拟获取当前天气
  Future<WeatherData> getCurrentWeather(String city) async {
    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1000)));

    // 10% 概率模拟错误
    if (_random.nextInt(10) == 0) {
      throw Exception('网络请求失败: 服务器无响应');
    }

    if (!supportedCities.contains(city)) {
      throw Exception('不支持的城市: $city');
    }

    final weatherType = _weatherTypes[_random.nextInt(_weatherTypes.length)];
    final temp = 10.0 + _random.nextInt(25) + _random.nextDouble();

    return WeatherData(
      city: city,
      temperature: double.parse(temp.toStringAsFixed(1)),
      feelsLike: double.parse((temp + _random.nextInt(5) - 2).toStringAsFixed(1)),
      humidity: 30 + _random.nextInt(60),
      windSpeed: double.parse((_random.nextDouble() * 10).toStringAsFixed(1)),
      description: weatherType['desc']!,
      icon: weatherType['icon']!,
      updatedAt: DateTime.now(),
    );
  }

  /// 模拟获取未来 5 天预报
  Future<List<DailyForecast>> getForecast(String city) async {
    await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(500)));

    if (!supportedCities.contains(city)) {
      throw Exception('不支持的城市: $city');
    }

    final now = DateTime.now();
    return List.generate(5, (i) {
      final weatherType = _weatherTypes[_random.nextInt(_weatherTypes.length)];
      final high = 15.0 + _random.nextInt(20);
      return DailyForecast(
        date: now.add(Duration(days: i + 1)),
        high: double.parse(high.toStringAsFixed(1)),
        low: double.parse((high - 5 - _random.nextInt(8)).toStringAsFixed(1)),
        description: weatherType['desc']!,
        icon: weatherType['icon']!,
      );
    });
  }
}

// ============================================================
// Repository 层 —— 协调数据获取和缓存
// ============================================================

class WeatherRepository {
  final MockWeatherApiClient _apiClient;

  // 内存缓存
  final Map<String, WeatherData> _weatherCache = {};
  final Map<String, List<DailyForecast>> _forecastCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  static const Duration cacheExpiry = Duration(minutes: 10);

  WeatherRepository({MockWeatherApiClient? apiClient})
      : _apiClient = apiClient ?? MockWeatherApiClient();

  /// 获取当前天气（带缓存）
  Future<WeatherData> getCurrentWeather(String city, {bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid(city)) {
      return _weatherCache[city]!;
    }

    final data = await _apiClient.getCurrentWeather(city);
    _weatherCache[city] = data;
    _cacheTimestamps[city] = DateTime.now();
    return data;
  }

  /// 获取天气预报（带缓存）
  Future<List<DailyForecast>> getForecast(String city, {bool forceRefresh = false}) async {
    final cacheKey = '${city}_forecast';
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      return _forecastCache[city]!;
    }

    final data = await _apiClient.getForecast(city);
    _forecastCache[city] = data;
    _cacheTimestamps[cacheKey] = DateTime.now();
    return data;
  }

  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < cacheExpiry;
  }
}

// ============================================================
// UI 层
// ============================================================

class Ch08App extends StatelessWidget {
  const Ch08App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ch08 - 天气 App',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final WeatherRepository _repository = WeatherRepository();
  final TextEditingController _searchController = TextEditingController();

  WeatherData? _weather;
  List<DailyForecast> _forecast = [];
  bool _loading = false;
  String? _error;
  String _selectedCity = '北京';

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 加载天气数据
  Future<void> _loadWeather({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 并行加载当前天气和预报
      final results = await Future.wait([
        _repository.getCurrentWeather(_selectedCity, forceRefresh: forceRefresh),
        _repository.getForecast(_selectedCity, forceRefresh: forceRefresh),
      ]);

      setState(() {
        _weather = results[0] as WeatherData;
        _forecast = results[1] as List<DailyForecast>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  /// 选择城市
  void _selectCity(String city) {
    setState(() => _selectedCity = city);
    _loadWeather(forceRefresh: true);
    Navigator.pop(context); // 关闭搜索面板
  }

  /// 显示城市搜索面板
  void _showCitySearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildCitySearchSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _loadWeather(forceRefresh: true),
        child: CustomScrollView(
          slivers: [
            // AppBar
            SliverAppBar(
              expandedHeight: 60,
              floating: true,
              title: GestureDetector(
                onTap: _showCitySearch,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 20),
                    const SizedBox(width: 4),
                    Text(_selectedCity),
                    const Icon(Icons.keyboard_arrow_down, size: 20),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loading ? null : () => _loadWeather(forceRefresh: true),
                ),
              ],
            ),
            // 内容
            if (_loading && _weather == null)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _weather == null)
              SliverFillRemaining(child: _buildErrorView(colorScheme))
            else if (_weather != null)
              SliverList(
                delegate: SliverChildListDelegate([
                  // 错误提示（有缓存数据时显示在顶部）
                  if (_error != null) _buildErrorBanner(),
                  // 当前天气
                  _buildCurrentWeather(colorScheme),
                  // 天气详情
                  _buildWeatherDetails(colorScheme),
                  // 预报
                  if (_forecast.isNotEmpty) _buildForecastSection(colorScheme),
                  const SizedBox(height: 32),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  /// 城市搜索面板
  Widget _buildCitySearchSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('选择城市', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              // 城市列表
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: MockWeatherApiClient.supportedCities.length,
                  itemBuilder: (context, index) {
                    final city = MockWeatherApiClient.supportedCities[index];
                    final isSelected = city == _selectedCity;
                    return ListTile(
                      leading: Icon(
                        isSelected ? Icons.location_on : Icons.location_city,
                        color: isSelected ? colorScheme.primary : null,
                      ),
                      title: Text(
                        city,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : null,
                          color: isSelected ? colorScheme.primary : null,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: colorScheme.primary)
                          : null,
                      onTap: () => _selectCity(city),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 当前天气卡片
  Widget _buildCurrentWeather(ColorScheme colorScheme) {
    final w = _weather!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(w.icon, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 8),
          Text(
            '${w.temperature.toStringAsFixed(0)}°C',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          Text(
            w.description,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '体感 ${w.feelsLike.toStringAsFixed(0)}°C',
            style: TextStyle(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }

  /// 天气详情网格
  Widget _buildWeatherDetails(ColorScheme colorScheme) {
    final w = _weather!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildDetailCard('💧', '湿度', '${w.humidity}%', colorScheme),
          const SizedBox(width: 12),
          _buildDetailCard('💨', '风速', '${w.windSpeed} m/s', colorScheme),
          const SizedBox(width: 12),
          _buildDetailCard(
            '🕐',
            '更新时间',
            '${w.updatedAt.hour.toString().padLeft(2, '0')}:${w.updatedAt.minute.toString().padLeft(2, '0')}',
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
      String icon, String label, String value, ColorScheme colorScheme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.6))),
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  /// 五日预报
  Widget _buildForecastSection(ColorScheme colorScheme) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('未来 5 天预报',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ..._forecast.map((f) {
            final weekday = weekdays[f.date.weekday - 1];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text('周$weekday',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  Text(f.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f.description)),
                  Text(
                    '${f.low.toStringAsFixed(0)}° / ${f.high.toStringAsFixed(0)}°',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 错误视图（全屏）
  Widget _buildErrorView(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 64,
                color: colorScheme.error.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('加载失败', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _loadWeather(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  /// 错误横幅（有数据时）
  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '刷新失败，显示的是缓存数据',
              style: TextStyle(
                  fontSize: 13, color: Colors.orange.shade800),
            ),
          ),
        ],
      ),
    );
  }
}
