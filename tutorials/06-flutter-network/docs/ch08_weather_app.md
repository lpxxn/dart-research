# 第八章：天气 App 实战

## 概述

本章将前面所学的知识综合运用，构建一个完整的天气应用。涵盖：

- **数据模型**（WeatherData、DailyForecast）
- **HTTP 客户端封装**（MockWeatherApiClient）
- **Repository 模式**（WeatherRepository + 缓存）
- **UI 交互**（城市搜索 → 天气展示 → 五日预报）
- **下拉刷新**（RefreshIndicator）
- **错误处理**（网络失败 + 降级策略）

## 架构设计

```
┌─────────────────────────────────┐
│           UI 层                  │
│  WeatherHomePage                │
│  ├── 城市选择                    │
│  ├── 当前天气卡片                │
│  ├── 天气详情                    │
│  └── 五日预报                    │
├─────────────────────────────────┤
│         Repository 层            │
│  WeatherRepository              │
│  ├── getCurrentWeather()        │
│  ├── getForecast()              │
│  └── 内存缓存（10分钟过期）       │
├─────────────────────────────────┤
│        数据源层                   │
│  MockWeatherApiClient           │
│  ├── getCurrentWeather()        │
│  └── getForecast()              │
├─────────────────────────────────┤
│        数据模型层                 │
│  WeatherData / DailyForecast    │
└─────────────────────────────────┘
```

## 数据模型设计

### WeatherData — 当前天气

```dart
class WeatherData {
  final String city;          // 城市名
  final double temperature;   // 温度 (°C)
  final double feelsLike;     // 体感温度
  final int humidity;         // 湿度 (%)
  final double windSpeed;     // 风速 (m/s)
  final String description;   // 天气描述（晴、多云...）
  final String icon;          // 天气图标（emoji）
  final DateTime updatedAt;   // 更新时间

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      city: json['city'] as String,
      temperature: (json['temperature'] as num).toDouble(),
      // ... 其他字段
    );
  }
}
```

**设计要点**：
- 使用 `num` 转 `double`，兼容 JSON 中的整数和浮点数
- `fromJson` 工厂构造函数便于从 API 响应创建对象
- `updatedAt` 记录数据时间，供缓存策略和 UI 使用

### DailyForecast — 每日预报

```dart
class DailyForecast {
  final DateTime date;
  final double high;          // 最高温
  final double low;           // 最低温
  final String description;
  final String icon;
}
```

## HTTP 客户端封装

```dart
class MockWeatherApiClient {
  /// 模拟获取当前天气
  Future<WeatherData> getCurrentWeather(String city) async {
    await Future.delayed(Duration(milliseconds: 500 + random.nextInt(1000)));

    // 10% 概率模拟网络错误
    if (random.nextInt(10) == 0) {
      throw Exception('网络请求失败: 服务器无响应');
    }

    // 校验城市是否支持
    if (!supportedCities.contains(city)) {
      throw Exception('不支持的城市: $city');
    }

    // 返回模拟数据
    return WeatherData(...);
  }
}
```

**在实际项目中**，这里会使用 `http` 或 `dio` 包：

```dart
// 实际项目的 API 客户端
class WeatherApiClient {
  final Dio _dio;

  Future<WeatherData> getCurrentWeather(String city) async {
    final response = await _dio.get(
      '/weather',
      queryParameters: {'q': city, 'appid': apiKey, 'units': 'metric'},
    );
    return WeatherData.fromJson(response.data);
  }
}
```

## Repository 层

### 缓存策略

```dart
class WeatherRepository {
  final Map<String, WeatherData> _weatherCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration cacheExpiry = Duration(minutes: 10);

  Future<WeatherData> getCurrentWeather(
    String city, {
    bool forceRefresh = false,
  }) async {
    // 非强制刷新 + 缓存有效 → 直接返回缓存
    if (!forceRefresh && _isCacheValid(city)) {
      return _weatherCache[city]!;
    }

    // 请求新数据
    final data = await _apiClient.getCurrentWeather(city);
    _weatherCache[city] = data;
    _cacheTimestamps[city] = DateTime.now();
    return data;
  }

  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < cacheExpiry;
  }
}
```

### 并行加载

当前天气和预报是独立的请求，可以并行执行：

```dart
Future<void> _loadWeather() async {
  final results = await Future.wait([
    _repository.getCurrentWeather(_selectedCity),
    _repository.getForecast(_selectedCity),
  ]);

  _weather = results[0] as WeatherData;
  _forecast = results[1] as List<DailyForecast>;
}
```

`Future.wait` 同时发起两个请求，等全部完成后一起返回，比串行快一倍。

## UI 实现

### 页面结构

使用 `CustomScrollView` + `Sliver` 实现可滚动的复杂布局：

```dart
CustomScrollView(
  slivers: [
    SliverAppBar(
      floating: true,      // 向上滚动时隐藏，向下滚动时出现
      title: Text(city),   // 点击可选择城市
    ),
    SliverList(
      delegate: SliverChildListDelegate([
        _buildCurrentWeather(),   // 当前天气大卡片
        _buildWeatherDetails(),   // 湿度、风速等详情
        _buildForecastSection(),  // 五日预报
      ]),
    ),
  ],
)
```

### 下拉刷新

```dart
RefreshIndicator(
  onRefresh: () => _loadWeather(forceRefresh: true),
  child: CustomScrollView(...),
)
```

`RefreshIndicator` 包裹可滚动组件，下拉触发 `onRefresh` 回调。注意：
- `onRefresh` 必须返回 `Future`
- 传入 `forceRefresh: true` 绕过缓存

### 城市搜索

使用 `ModalBottomSheet` 展示城市列表：

```dart
void _showCitySearch() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      expand: false,
      builder: (context, scrollController) {
        return ListView.builder(
          controller: scrollController,
          itemCount: cities.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(cities[i]),
            onTap: () => _selectCity(cities[i]),
          ),
        );
      },
    ),
  );
}
```

### 错误处理的两种展示

**1. 全屏错误（无缓存数据时）**：

```dart
if (_error != null && _weather == null)
  SliverFillRemaining(child: _buildErrorView())
```

显示大图标 + 错误信息 + 重试按钮。

**2. 横幅提示（有缓存数据时）**：

```dart
if (_error != null && _weather != null)
  _buildErrorBanner()  // 顶部小横幅："刷新失败，显示的是缓存数据"
```

有缓存时不阻断用户，只在顶部显示提示。

## 天气卡片设计

### 渐变背景

```dart
Container(
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
      Text(weather.icon, style: TextStyle(fontSize: 64)),  // Emoji 图标
      Text('${weather.temperature}°C'),  // 温度
      Text(weather.description),          // 天气描述
    ],
  ),
)
```

### 详情卡片网格

```dart
Row(
  children: [
    _buildDetailCard('💧', '湿度', '${w.humidity}%'),
    _buildDetailCard('💨', '风速', '${w.windSpeed} m/s'),
    _buildDetailCard('🕐', '更新时间', '12:30'),
  ],
)
```

## 示例代码说明

`lib/ch08_weather_app.dart` 是一个完整可运行的天气应用：

- **10 个中国城市**可选择
- **随机生成天气数据**（7 种天气类型）
- **10% 概率模拟网络错误**
- **10 分钟缓存策略**
- **并行请求**当前天气和预报
- **下拉刷新**强制获取最新数据
- **优雅的错误处理**：有缓存数据时显示横幅，无数据时全屏错误+重试

运行方式：
```bash
flutter run -t lib/ch08_weather_app.dart
```

## 接入真实天气 API

示例使用模拟数据，接入真实 API 只需替换 `MockWeatherApiClient`：

### OpenWeatherMap API

```dart
class OpenWeatherApiClient {
  final Dio _dio;
  final String _apiKey;

  OpenWeatherApiClient({required String apiKey})
      : _apiKey = apiKey,
        _dio = Dio(BaseOptions(
          baseUrl: 'https://api.openweathermap.org/data/2.5',
        ));

  Future<WeatherData> getCurrentWeather(String city) async {
    final response = await _dio.get('/weather', queryParameters: {
      'q': city,
      'appid': _apiKey,
      'units': 'metric',
      'lang': 'zh_cn',
    });
    return WeatherData.fromJson(response.data);
  }

  Future<List<DailyForecast>> getForecast(String city) async {
    final response = await _dio.get('/forecast', queryParameters: {
      'q': city,
      'appid': _apiKey,
      'units': 'metric',
      'lang': 'zh_cn',
    });
    // 解析 5天/3小时 预报数据
    final list = response.data['list'] as List;
    return list.map((e) => DailyForecast.fromJson(e)).toList();
  }
}
```

**得益于 Repository 模式**，只需替换数据源实现，Repository 和 UI 层代码无需改动。

## 最佳实践

1. **分层架构**：数据模型 → API 客户端 → Repository → UI，各层职责清晰
2. **并行请求**：独立数据用 `Future.wait` 并行加载
3. **缓存策略**：按城市分别缓存，设置合理过期时间
4. **优雅降级**：有缓存时不阻断用户，无数据时全屏错误+重试
5. **下拉刷新**：让用户可以主动更新数据
6. **UI 反馈**：加载状态、数据来源、错误信息，每步都有反馈
7. **Emoji 图标**：开发阶段用 Emoji 代替图片资源，快速原型
8. **Material 3**：使用 `colorScheme` 动态取色，适配深色模式
