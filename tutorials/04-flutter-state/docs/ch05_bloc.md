# 第5章：BLoC / Cubit 状态管理

## 目录

1. [BLoC 模式的设计理念](#1-bloc-模式的设计理念)
2. [Cubit 入门](#2-cubit-入门)
3. [BLoC 完整模式](#3-bloc-完整模式)
4. [BlocBuilder / BlocListener / BlocConsumer](#4-blocbuilder--bloclistener--blocconsumer)
5. [MultiBlocProvider](#5-multiblocprovider)
6. [BLoC 间通信](#6-bloc-间通信)
7. [实战：天气查询应用](#7-实战天气查询应用)
8. [最佳实践](#8-最佳实践)

---

## 1. BLoC 模式的设计理念

### 什么是 BLoC？

BLoC（**B**usiness **Lo**gic **C**omponent）是由 Google 工程师提出的一种架构模式，核心思想是：

- **事件驱动**：UI 层通过发送事件（Event）来触发业务逻辑
- **单向数据流**：Event → BLoC → State，数据只朝一个方向流动
- **关注点分离**：UI 只负责展示和发送事件，业务逻辑全部在 BLoC 中处理

### 单向数据流示意图

```
┌─────────┐    Event     ┌─────────┐    State    ┌─────────┐
│         │ ──────────▶  │         │ ──────────▶ │         │
│   UI    │              │  BLoC   │             │   UI    │
│ (用户)   │              │ (逻辑)   │             │ (重建)   │
│         │ ◀──────────  │         │             │         │
└─────────┘              └─────────┘             └─────────┘
```

### 为什么选择 BLoC？

| 优势 | 说明 |
|------|------|
| 可测试性 | 纯 Dart 类，不依赖 Flutter，易于单元测试 |
| 可预测性 | 给定相同事件序列，总是产生相同状态序列 |
| 关注点分离 | UI 与业务逻辑完全解耦 |
| 团队协作 | 不同开发者可以独立开发 UI 和业务逻辑 |

### 安装依赖

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  flutter_bloc: ^8.0.0
  equatable: ^2.0.0  # 用于简化状态比较
```

---

## 2. Cubit 入门

### 什么是 Cubit？

Cubit 是 BLoC 的简化版本。它去掉了事件（Event）类，直接通过方法调用来改变状态：

```
┌─────────┐   方法调用    ┌─────────┐    State    ┌─────────┐
│   UI    │ ──────────▶  │  Cubit  │ ──────────▶ │   UI    │
└─────────┘              └─────────┘             └─────────┘
```

### 计数器 Cubit 示例

```dart
// 定义 Cubit：直接继承 Cubit<State类型>
class CounterCubit extends Cubit<int> {
  // 构造函数中传入初始状态
  CounterCubit() : super(0);

  // 通过方法直接 emit 新状态
  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
  void reset() => emit(0);
}
```

### 在 UI 中使用 Cubit

```dart
// 1. 使用 BlocProvider 提供 Cubit 实例
BlocProvider(
  create: (context) => CounterCubit(),
  child: MyCounterPage(),
)

// 2. 在子组件中读取和操作
class MyCounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 使用 BlocBuilder 监听状态变化
        BlocBuilder<CounterCubit, int>(
          builder: (context, count) {
            return Text('计数: $count');
          },
        ),
        // 调用 Cubit 的方法
        ElevatedButton(
          onPressed: () => context.read<CounterCubit>().increment(),
          child: Text('增加'),
        ),
      ],
    );
  }
}
```

### Cubit vs BLoC 对比

| 特性 | Cubit | BLoC |
|------|-------|------|
| 复杂度 | 低 | 高 |
| 事件类 | 不需要 | 需要定义 |
| 可追溯性 | 一般 | 好（每个事件都可记录） |
| 适用场景 | 简单状态 | 复杂业务流程 |

---

## 3. BLoC 完整模式

### Event → BLoC → State 三要素

BLoC 完整模式需要定义三个部分：

#### 3.1 定义事件（Event）

```dart
// 使用 sealed class 或抽象类定义事件
abstract class WeatherEvent {}

// 具体事件
class FetchWeather extends WeatherEvent {
  final String city;
  FetchWeather(this.city);
}

class ResetWeather extends WeatherEvent {}
```

#### 3.2 定义状态（State）

```dart
// 使用 Equatable 简化状态比较
abstract class WeatherState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WeatherInitial extends WeatherState {}

class WeatherLoading extends WeatherState {}

class WeatherLoaded extends WeatherState {
  final String city;
  final double temperature;
  final String description;

  WeatherLoaded({
    required this.city,
    required this.temperature,
    required this.description,
  });

  @override
  List<Object?> get props => [city, temperature, description];
}

class WeatherError extends WeatherState {
  final String message;
  WeatherError(this.message);

  @override
  List<Object?> get props => [message];
}
```

#### 3.3 实现 BLoC

```dart
class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  WeatherBloc() : super(WeatherInitial()) {
    // 使用 on<Event> 注册事件处理器
    on<FetchWeather>(_onFetchWeather);
    on<ResetWeather>(_onResetWeather);
  }

  Future<void> _onFetchWeather(
    FetchWeather event,
    Emitter<WeatherState> emit,
  ) async {
    emit(WeatherLoading()); // 发送加载状态

    try {
      // 模拟网络请求
      await Future.delayed(Duration(seconds: 2));
      
      emit(WeatherLoaded(
        city: event.city,
        temperature: 25.0,
        description: '晴天',
      ));
    } catch (e) {
      emit(WeatherError('获取天气失败: $e'));
    }
  }

  void _onResetWeather(
    ResetWeather event,
    Emitter<WeatherState> emit,
  ) {
    emit(WeatherInitial());
  }
}
```

### Equatable 的作用

Equatable 让我们可以比较两个状态对象是否相等，避免不必要的 UI 重建：

```dart
// 没有 Equatable 时，每次 emit 都会触发重建
// 有 Equatable 时，相同的状态不会触发重建
final state1 = WeatherLoaded(city: '北京', temperature: 25, description: '晴');
final state2 = WeatherLoaded(city: '北京', temperature: 25, description: '晴');
print(state1 == state2); // true（有 Equatable）
```

---

## 4. BlocBuilder / BlocListener / BlocConsumer

### 4.1 BlocBuilder

用于根据状态**重建 UI**：

```dart
BlocBuilder<WeatherBloc, WeatherState>(
  // buildWhen 可以控制什么时候重建（可选）
  buildWhen: (previous, current) {
    return current is WeatherLoaded; // 只在加载成功时重建
  },
  builder: (context, state) {
    if (state is WeatherInitial) {
      return Text('请输入城市名查询天气');
    } else if (state is WeatherLoading) {
      return CircularProgressIndicator();
    } else if (state is WeatherLoaded) {
      return Text('${state.city}: ${state.temperature}°C');
    } else if (state is WeatherError) {
      return Text('错误: ${state.message}');
    }
    return SizedBox.shrink();
  },
)
```

### 4.2 BlocListener

用于执行**一次性副作用**（不重建 UI），比如显示 SnackBar、导航等：

```dart
BlocListener<WeatherBloc, WeatherState>(
  // listenWhen 控制什么时候触发（可选）
  listenWhen: (previous, current) {
    return current is WeatherError;
  },
  listener: (context, state) {
    if (state is WeatherError) {
      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
    if (state is WeatherLoaded) {
      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('天气加载成功！')),
      );
    }
  },
  child: WeatherWidget(), // 子组件不会因为 listener 重建
)
```

### 4.3 BlocConsumer

**同时需要**监听副作用和重建 UI 时使用（BlocBuilder + BlocListener 的组合）：

```dart
BlocConsumer<WeatherBloc, WeatherState>(
  listener: (context, state) {
    // 处理副作用
    if (state is WeatherError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  builder: (context, state) {
    // 构建 UI
    if (state is WeatherLoading) {
      return CircularProgressIndicator();
    } else if (state is WeatherLoaded) {
      return Text('${state.city}: ${state.temperature}°C');
    }
    return Text('请查询天气');
  },
)
```

### 三者对比

| Widget | 重建 UI | 执行副作用 | 使用场景 |
|--------|---------|-----------|---------|
| BlocBuilder | ✅ | ❌ | 纯 UI 展示 |
| BlocListener | ❌ | ✅ | SnackBar、导航、日志 |
| BlocConsumer | ✅ | ✅ | 同时需要两者 |

---

## 5. MultiBlocProvider

当页面需要多个 BLoC 时，使用 MultiBlocProvider 避免嵌套：

```dart
// ❌ 不好的写法：嵌套过深
BlocProvider(
  create: (context) => WeatherBloc(),
  child: BlocProvider(
    create: (context) => ThemeBloc(),
    child: BlocProvider(
      create: (context) => AuthBloc(),
      child: MyApp(),
    ),
  ),
)

// ✅ 好的写法：使用 MultiBlocProvider
MultiBlocProvider(
  providers: [
    BlocProvider(create: (context) => WeatherBloc()),
    BlocProvider(create: (context) => ThemeBloc()),
    BlocProvider(create: (context) => AuthBloc()),
  ],
  child: MyApp(),
)
```

同样，`MultiBlocListener` 可以合并多个 BlocListener：

```dart
MultiBlocListener(
  listeners: [
    BlocListener<WeatherBloc, WeatherState>(
      listener: (context, state) { /* ... */ },
    ),
    BlocListener<AuthBloc, AuthState>(
      listener: (context, state) { /* ... */ },
    ),
  ],
  child: MyWidget(),
)
```

---

## 6. BLoC 间通信

### 场景：一个 BLoC 需要响应另一个 BLoC 的状态变化

使用 `BlocListener` 监听一个 BLoC 的变化，然后向另一个 BLoC 发送事件：

```dart
// 例如：认证状态变化时，重新加载天气数据
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is Authenticated) {
      // 当用户登录后，自动获取天气
      context.read<WeatherBloc>().add(
        FetchWeather(state.user.defaultCity),
      );
    }
    if (state is Unauthenticated) {
      // 当用户登出后，重置天气
      context.read<WeatherBloc>().add(ResetWeather());
    }
  },
  child: WeatherPage(),
)
```

### 在 BLoC 内部监听另一个 BLoC

也可以通过构造函数注入 Stream 的方式：

```dart
class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  final Stream<AuthState> authStream;
  late final StreamSubscription<AuthState> _authSubscription;

  WeatherBloc({required this.authStream}) : super(WeatherInitial()) {
    // 监听认证状态流
    _authSubscription = authStream.listen((authState) {
      if (authState is Authenticated) {
        add(FetchWeather(authState.user.defaultCity));
      }
    });

    on<FetchWeather>(_onFetchWeather);
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
```

---

## 7. 实战：天气查询应用

完整代码见 `lib/ch05_bloc.dart`，实现了：

1. **WeatherEvent**：`FetchWeather`（查询天气）和 `ResetWeather`（重置）
2. **WeatherState**：`Initial` / `Loading` / `Loaded` / `Error` 四种状态
3. **WeatherBloc**：处理事件并发出对应状态
4. **UI 层**：
   - 输入框输入城市名
   - 点击查询按钮发送 `FetchWeather` 事件
   - 使用 `BlocConsumer` 同时展示状态和处理错误提示
   - 加载中显示进度指示器
   - 加载完成显示天气信息卡片

---

## 8. 最佳实践

### 8.1 命名规范

- **Event**：使用动词过去式或名词，如 `WeatherFetched`、`FetchWeather`
- **State**：描述当前状态，如 `WeatherLoading`、`WeatherLoaded`
- **BLoC**：以 `Bloc` 结尾，如 `WeatherBloc`

### 8.2 状态设计原则

```dart
// ✅ 推荐：使用单一状态类包含所有信息
class WeatherState extends Equatable {
  final WeatherStatus status; // enum: initial, loading, success, failure
  final Weather? weather;
  final String? errorMessage;
  
  // copyWith 方法用于创建新状态
  WeatherState copyWith({...}) { ... }
}

// ✅ 也可以：使用多个独立状态类（适合状态间差异大的情况）
abstract class WeatherState {}
class WeatherInitial extends WeatherState {}
class WeatherLoading extends WeatherState {}
class WeatherLoaded extends WeatherState { ... }
class WeatherError extends WeatherState { ... }
```

### 8.3 测试 BLoC

```dart
// BLoC 是纯 Dart 类，非常容易测试
void main() {
  group('WeatherBloc', () {
    late WeatherBloc bloc;

    setUp(() {
      bloc = WeatherBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('初始状态是 WeatherInitial', () {
      expect(bloc.state, isA<WeatherInitial>());
    });

    // 使用 blocTest 测试事件序列
    blocTest<WeatherBloc, WeatherState>(
      '查询天气成功',
      build: () => WeatherBloc(),
      act: (bloc) => bloc.add(FetchWeather('北京')),
      expect: () => [
        isA<WeatherLoading>(),
        isA<WeatherLoaded>(),
      ],
    );
  });
}
```

### 8.4 其他建议

- **一个页面一个 BLoC**：避免一个 BLoC 管理太多状态
- **BLoC 不依赖 BuildContext**：保持可测试性
- **使用 Equatable**：避免不必要的 UI 重建
- **简单场景用 Cubit**：不需要事件追溯时，Cubit 更简洁
- **复杂场景用 BLoC**：需要记录事件日志、事件转换等高级功能时

---

## 参考资源

- [flutter_bloc 官方文档](https://bloclibrary.dev)
- [BLoC 架构教程](https://bloclibrary.dev/architecture/)
- [flutter_bloc API 参考](https://pub.dev/documentation/flutter_bloc/latest/)
