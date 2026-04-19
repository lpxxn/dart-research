# 第十二章：实战项目 — 天气查询 App

> 本章将运用前面学到的所有 Riverpod 知识，构建一个完整的天气查询应用，包含搜索、异步加载、错误处理、缓存和分层架构。

## 目录

1. [项目架构](#1-项目架构)
2. [数据模型](#2-数据模型)
3. [Repository 层](#3-repository-层)
4. [ViewModel 层（AsyncNotifier）](#4-viewmodel-层asyncnotifier)
5. [派生 Provider](#5-派生-provider)
6. [UI 层](#6-ui-层)
7. [错误处理与重试](#7-错误处理与重试)
8. [总结](#8-总结)

---

## 1. 项目架构

```
天气查询 App
│
├── 数据层 (Data)
│   ├── WeatherData 模型
│   └── WeatherRepository（模拟 API）
│
├── 状态层 (State)
│   ├── WeatherNotifier (AsyncNotifier)
│   ├── searchHistoryProvider (搜索历史)
│   └── 派生 Provider（最近搜索、收藏等）
│
└── UI 层 (Presentation)
    ├── 搜索栏
    ├── 天气卡片
    ├── 搜索历史
    └── 错误/加载状态
```

### 依赖关系图

```
weatherRepositoryProvider (Provider<WeatherRepository>)
          │
          ▼
weatherNotifierProvider (AsyncNotifierProvider<WeatherNotifier, WeatherData?>)
          │
          ├──→ hasWeatherDataProvider (派生)
          │
searchHistoryProvider (NotifierProvider<SearchHistoryNotifier, List<String>>)
          │
          ├──→ recentSearchesProvider (派生：最近 5 条)
```

---

## 2. 数据模型

```dart
class WeatherData {
  final String city;
  final double temperature;
  final String description;
  final int humidity;
  final double windSpeed;
  final String icon;
  final DateTime queriedAt;
}
```

---

## 3. Repository 层

```dart
abstract class WeatherRepository {
  Future<WeatherData> getWeather(String city);
}

class MockWeatherRepository implements WeatherRepository {
  @override
  Future<WeatherData> getWeather(String city) async {
    // 模拟网络请求...
    return WeatherData(...);
  }
}
```

---

## 4. ViewModel 层

```dart
class WeatherNotifier extends AsyncNotifier<WeatherData?> {
  @override
  Future<WeatherData?> build() async => null; // 初始无数据

  Future<void> searchCity(String city) async {
    state = const AsyncLoading();
    final repo = ref.read(weatherRepositoryProvider);
    state = await AsyncValue.guard(() => repo.getWeather(city));
  }
}
```

---

## 5. 派生 Provider

- `hasWeatherDataProvider`：是否有天气数据
- `recentSearchesProvider`：最近 5 条搜索记录

---

## 6. UI 层

- 搜索栏：输入城市名并搜索
- 天气卡片：显示温度、描述、湿度、风速
- 搜索历史：快速选择历史记录
- 三态处理：loading/error/data

---

## 7. 错误处理与重试

```dart
// AsyncValue.when 处理所有状态
weatherAsync.when(
  loading: () => CircularProgressIndicator(),
  error: (error, _) => Column(
    children: [
      Text('查询失败: $error'),
      ElevatedButton(
        onPressed: () => ref.read(weatherProvider.notifier).retry(),
        child: Text('重试'),
      ),
    ],
  ),
  data: (weather) => WeatherCard(weather: weather),
);
```

---

## 8. 总结

本实战项目综合运用了：

| 知识点 | 对应章节 | 在本项目中的应用 |
|--------|---------|----------------|
| ProviderScope | Ch01 | 根组件包裹 |
| Provider | Ch02 | Repository 注入 |
| Notifier | Ch03 | 搜索历史管理 |
| ref.watch/read/listen | Ch04 | 状态监听与操作 |
| AsyncNotifier | Ch05 | 天气数据加载 |
| autoDispose | Ch06 | 页面级状态 |
| Provider 组合 | Ch08 | 派生状态 |
| ProviderObserver | Ch09 | 调试日志 |
| 测试 override | Ch10 | Mock Repository |
| 架构分层 | Ch11 | 三层架构 |
