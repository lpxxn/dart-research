// 第5章：BLoC / Cubit 状态管理 —— 天气查询应用
//
// 本示例演示了 BLoC 模式的核心概念：
// - Cubit（简化版 BLoC）
// - BLoC 完整模式（Event → BLoC → State）
// - BlocBuilder / BlocListener / BlocConsumer
// - MultiBlocProvider
// - BLoC 间通信
//
// 运行方式：flutter run -t lib/ch05_bloc.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// ============================================================
// 第一部分：Cubit 示例 —— 简单计数器
// ============================================================

/// 计数器 Cubit：Cubit 是简化版的 BLoC，不需要事件类
/// 直接通过方法调用 emit() 发出新状态
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0); // 初始状态为 0

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
  void reset() => emit(0);
}

// ============================================================
// 第二部分：BLoC 完整模式 —— 天气查询
// ============================================================

// ----- 事件定义 -----

/// 天气相关事件的基类
abstract class WeatherEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// 查询天气事件：携带城市名称
class FetchWeather extends WeatherEvent {
  final String city;
  FetchWeather(this.city);

  @override
  List<Object?> get props => [city];
}

/// 重置天气事件：回到初始状态
class ResetWeather extends WeatherEvent {}

// ----- 状态定义 -----

/// 天气状态的基类，使用 Equatable 自动实现 == 和 hashCode
abstract class WeatherState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// 初始状态：还没有查询过天气
class WeatherInitial extends WeatherState {}

/// 加载中状态：正在查询天气
class WeatherLoading extends WeatherState {}

/// 加载成功状态：包含天气数据
class WeatherLoaded extends WeatherState {
  final String city;
  final double temperature;
  final String description;
  final String icon;

  WeatherLoaded({
    required this.city,
    required this.temperature,
    required this.description,
    required this.icon,
  });

  @override
  List<Object?> get props => [city, temperature, description, icon];
}

/// 错误状态：查询失败
class WeatherError extends WeatherState {
  final String message;
  WeatherError(this.message);

  @override
  List<Object?> get props => [message];
}

// ----- BLoC 实现 -----

/// 天气 BLoC：处理天气相关事件，输出天气状态
class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  WeatherBloc() : super(WeatherInitial()) {
    // 使用 on<EventType> 注册事件处理器
    on<FetchWeather>(_onFetchWeather);
    on<ResetWeather>(_onResetWeather);
  }

  /// 处理天气查询事件
  Future<void> _onFetchWeather(
    FetchWeather event,
    Emitter<WeatherState> emit,
  ) async {
    // 发出加载中状态
    emit(WeatherLoading());

    try {
      // 模拟网络请求延迟
      await Future.delayed(const Duration(seconds: 2));

      // 校验城市名称
      if (event.city.trim().isEmpty) {
        emit(WeatherError('请输入城市名称'));
        return;
      }

      // 模拟某些城市查询失败
      if (event.city == '未知城市') {
        emit(WeatherError('找不到城市「${event.city}」的天气数据'));
        return;
      }

      // 模拟天气数据
      final random = Random();
      final weatherData = _generateWeatherData(event.city, random);

      emit(WeatherLoaded(
        city: event.city,
        temperature: weatherData['temperature'] as double,
        description: weatherData['description'] as String,
        icon: weatherData['icon'] as String,
      ));
    } catch (e) {
      emit(WeatherError('获取天气失败: $e'));
    }
  }

  /// 处理重置事件
  void _onResetWeather(
    ResetWeather event,
    Emitter<WeatherState> emit,
  ) {
    emit(WeatherInitial());
  }

  /// 生成模拟天气数据
  Map<String, dynamic> _generateWeatherData(String city, Random random) {
    final weathers = [
      {'description': '晴天', 'icon': '☀️', 'tempRange': [20.0, 35.0]},
      {'description': '多云', 'icon': '⛅', 'tempRange': [15.0, 28.0]},
      {'description': '阴天', 'icon': '☁️', 'tempRange': [10.0, 22.0]},
      {'description': '小雨', 'icon': '🌧️', 'tempRange': [8.0, 18.0]},
      {'description': '大雨', 'icon': '⛈️', 'tempRange': [5.0, 15.0]},
      {'description': '雪', 'icon': '❄️', 'tempRange': [-5.0, 5.0]},
    ];

    final weather = weathers[random.nextInt(weathers.length)];
    final tempRange = weather['tempRange'] as List<double>;
    final temp = tempRange[0] +
        random.nextDouble() * (tempRange[1] - tempRange[0]);

    return {
      'description': weather['description'],
      'icon': weather['icon'],
      'temperature': double.parse(temp.toStringAsFixed(1)),
    };
  }
}

// ============================================================
// 第三部分：历史记录 Cubit（演示 BLoC 间通信）
// ============================================================

/// 历史记录 Cubit：记录查询过的城市
class HistoryCubit extends Cubit<List<String>> {
  HistoryCubit() : super([]);

  /// 添加城市到历史记录
  void addCity(String city) {
    if (!state.contains(city)) {
      emit([city, ...state].take(10).toList()); // 最多保留 10 条
    }
  }

  /// 清除历史记录
  void clear() => emit([]);
}

// ============================================================
// 第四部分：UI 实现
// ============================================================

void main() => runApp(const Ch05BlocApp());

class Ch05BlocApp extends StatelessWidget {
  const Ch05BlocApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 MultiBlocProvider 同时提供多个 BLoC/Cubit
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => WeatherBloc()),
        BlocProvider(create: (_) => CounterCubit()),
        BlocProvider(create: (_) => HistoryCubit()),
      ],
      child: MaterialApp(
        title: 'BLoC 天气查询',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.blue,
          useMaterial3: true,
        ),
        home: const WeatherHomePage(),
      ),
    );
  }
}

/// 天气查询主页面
class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final _cityController = TextEditingController();

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌤️ BLoC 天气查询'),
        actions: [
          // Cubit 计数器：显示查询次数
          BlocBuilder<CounterCubit, int>(
            builder: (context, count) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    '查询 $count 次',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          _buildSearchBar(context),

          // BLoC 间通信：监听 WeatherBloc 状态，更新 HistoryCubit
          BlocListener<WeatherBloc, WeatherState>(
            listener: (context, state) {
              if (state is WeatherLoaded) {
                // 天气加载成功时，将城市添加到历史记录
                context.read<HistoryCubit>().addCity(state.city);
                // 增加查询计数
                context.read<CounterCubit>().increment();
              }
            },
            child: const SizedBox.shrink(),
          ),

          // 天气结果区域：使用 BlocConsumer 同时处理 UI 和副作用
          Expanded(
            child: BlocConsumer<WeatherBloc, WeatherState>(
              // listener 处理副作用（如显示 SnackBar）
              listener: (context, state) {
                if (state is WeatherError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                if (state is WeatherLoaded) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${state.city}天气加载成功！'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              // builder 构建 UI
              builder: (context, state) {
                return _buildWeatherContent(context, state);
              },
            ),
          ),

          // 历史记录区域
          _buildHistorySection(context),
        ],
      ),
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _cityController,
              decoration: InputDecoration(
                hintText: '输入城市名（如：北京、上海、广州）',
                prefixIcon: const Icon(Icons.location_city),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _searchWeather(context),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () => _searchWeather(context),
            icon: const Icon(Icons.search),
            label: const Text('查询'),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              _cityController.clear();
              context.read<WeatherBloc>().add(ResetWeather());
            },
            icon: const Icon(Icons.refresh),
            tooltip: '重置',
          ),
        ],
      ),
    );
  }

  /// 执行天气查询
  void _searchWeather(BuildContext context) {
    final city = _cityController.text.trim();
    if (city.isNotEmpty) {
      // 向 WeatherBloc 发送查询事件
      context.read<WeatherBloc>().add(FetchWeather(city));
    }
  }

  /// 根据不同状态构建天气内容
  Widget _buildWeatherContent(BuildContext context, WeatherState state) {
    if (state is WeatherInitial) {
      return _buildInitialView();
    } else if (state is WeatherLoading) {
      return _buildLoadingView();
    } else if (state is WeatherLoaded) {
      return _buildWeatherCard(context, state);
    } else if (state is WeatherError) {
      return _buildErrorView(state);
    }
    return const SizedBox.shrink();
  }

  /// 初始视图
  Widget _buildInitialView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🌍', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text(
            '输入城市名查询天气',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            '试试输入「北京」或「上海」',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// 加载视图
  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在查询天气...'),
        ],
      ),
    );
  }

  /// 天气信息卡片
  Widget _buildWeatherCard(BuildContext context, WeatherLoaded state) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.icon, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                state.city,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${state.temperature}°C',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getTemperatureColor(state.temperature),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                state.description,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 根据温度返回颜色
  Color _getTemperatureColor(double temp) {
    if (temp >= 30) return Colors.red;
    if (temp >= 20) return Colors.orange;
    if (temp >= 10) return Colors.green;
    if (temp >= 0) return Colors.blue;
    return Colors.indigo;
  }

  /// 错误视图
  Widget _buildErrorView(WeatherError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('❌', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            state.message,
            style: const TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 历史记录区域
  Widget _buildHistorySection(BuildContext context) {
    return BlocBuilder<HistoryCubit, List<String>>(
      builder: (context, cities) {
        if (cities.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('最近查询', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => context.read<HistoryCubit>().clear(),
                    child: const Text('清除'),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: cities.map((city) {
                  return ActionChip(
                    label: Text(city),
                    onPressed: () {
                      _cityController.text = city;
                      context.read<WeatherBloc>().add(FetchWeather(city));
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
