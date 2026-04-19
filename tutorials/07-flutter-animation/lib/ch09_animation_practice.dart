import 'dart:math';

import 'package:flutter/material.dart';

/// 第9章：动画实战 — 天气动效页面
/// 纯 Flutter 实现，包含：
/// 1. 视差滚动背景（CustomPainter + AnimationController）
/// 2. 天气图标动画切换（AnimatedSwitcher）
/// 3. 温度数字滚动（TweenAnimationBuilder）
/// 4. 入场交错动画（Interval + 多动画编排）

void main() => runApp(const Ch09AnimationPracticeApp());

class Ch09AnimationPracticeApp extends StatelessWidget {
  const Ch09AnimationPracticeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '第9章：天气动效页面',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const WeatherAnimationPage(),
    );
  }
}

// ==================== 数据模型 ====================

enum WeatherType { sunny, cloudy, rainy, snowy, stormy }

class WeatherData {
  final WeatherType type;
  final String name;
  final IconData icon;
  final int temperature;
  final Color primaryColor;
  final Color secondaryColor;
  final String description;
  final int humidity;
  final int wind;
  final int visibility;

  const WeatherData({
    required this.type,
    required this.name,
    required this.icon,
    required this.temperature,
    required this.primaryColor,
    required this.secondaryColor,
    required this.description,
    required this.humidity,
    required this.wind,
    required this.visibility,
  });
}

const _weatherList = [
  WeatherData(
    type: WeatherType.sunny,
    name: '晴天',
    icon: Icons.wb_sunny_rounded,
    temperature: 32,
    primaryColor: Color(0xFFFF8F00),
    secondaryColor: Color(0xFFFFF3E0),
    description: '万里无云，阳光明媚',
    humidity: 35,
    wind: 12,
    visibility: 25,
  ),
  WeatherData(
    type: WeatherType.cloudy,
    name: '多云',
    icon: Icons.cloud_rounded,
    temperature: 24,
    primaryColor: Color(0xFF78909C),
    secondaryColor: Color(0xFFECEFF1),
    description: '云层较厚，偶有阳光',
    humidity: 60,
    wind: 18,
    visibility: 15,
  ),
  WeatherData(
    type: WeatherType.rainy,
    name: '雨天',
    icon: Icons.water_drop_rounded,
    temperature: 18,
    primaryColor: Color(0xFF42A5F5),
    secondaryColor: Color(0xFFE3F2FD),
    description: '中雨，出门记得带伞',
    humidity: 85,
    wind: 22,
    visibility: 8,
  ),
  WeatherData(
    type: WeatherType.snowy,
    name: '雪天',
    icon: Icons.ac_unit_rounded,
    temperature: -3,
    primaryColor: Color(0xFF90CAF9),
    secondaryColor: Color(0xFFE8EAF6),
    description: '大雪纷飞，注意保暖',
    humidity: 90,
    wind: 15,
    visibility: 5,
  ),
  WeatherData(
    type: WeatherType.stormy,
    name: '雷暴',
    icon: Icons.flash_on_rounded,
    temperature: 22,
    primaryColor: Color(0xFFFFD600),
    secondaryColor: Color(0xFF37474F),
    description: '雷电交加，请勿外出',
    humidity: 95,
    wind: 40,
    visibility: 3,
  ),
];

// ==================== 主页面 ====================

class WeatherAnimationPage extends StatefulWidget {
  const WeatherAnimationPage({super.key});

  @override
  State<WeatherAnimationPage> createState() => _WeatherAnimationPageState();
}

class _WeatherAnimationPageState extends State<WeatherAnimationPage>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  WeatherData get _weather => _weatherList[_currentIndex];

  // 视差背景动画控制器
  late final AnimationController _parallaxController;
  // 入场交错动画控制器
  late final AnimationController _staggerController;

  // 交错动画列表
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();

    // 视差背景持续循环
    _parallaxController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    // 入场动画
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _initStaggerAnimations();
    _staggerController.forward();
  }

  void _initStaggerAnimations() {
    const itemCount = 4;
    _fadeAnimations = List.generate(itemCount, (index) {
      final start = index * 0.15;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnimations = List.generate(itemCount, (index) {
      final start = index * 0.15;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });
  }

  @override
  void dispose() {
    _parallaxController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  void _switchWeather(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    // 重新播放入场交错动画
    _staggerController.reset();
    _staggerController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 视差滚动背景
          _ParallaxBackground(
            animation: _parallaxController,
            weather: _weather,
          ),

          // 半透明遮罩
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),

          // 内容层
          SafeArea(
            child: Column(
              children: [
                // 顶部标题
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '天气动效演示',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // 天气图标 + 温度（交错动画 0、1）
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 天气图标切换
                      FadeTransition(
                        opacity: _fadeAnimations[0],
                        child: SlideTransition(
                          position: _slideAnimations[0],
                          child: _WeatherIconSwitcher(weather: _weather),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 温度数字滚动
                      FadeTransition(
                        opacity: _fadeAnimations[1],
                        child: SlideTransition(
                          position: _slideAnimations[1],
                          child: _TemperatureDisplay(
                            temperature: _weather.temperature,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 天气描述
                      FadeTransition(
                        opacity: _fadeAnimations[2],
                        child: SlideTransition(
                          position: _slideAnimations[2],
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: Text(
                              _weather.description,
                              key: ValueKey(_weather.description),
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 天气详情卡片
                      FadeTransition(
                        opacity: _fadeAnimations[3],
                        child: SlideTransition(
                          position: _slideAnimations[3],
                          child: _WeatherDetailCards(weather: _weather),
                        ),
                      ),
                    ],
                  ),
                ),

                // 底部天气选择器
                _WeatherSelector(
                  currentIndex: _currentIndex,
                  onSelect: _switchWeather,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 视差滚动背景 ====================

class _ParallaxBackground extends StatelessWidget {
  final Animation<double> animation;
  final WeatherData weather;

  const _ParallaxBackground({
    required this.animation,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          color: Colors.black,
          child: CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ParallaxPainter(
              progress: animation.value,
              weatherType: weather.type,
              primaryColor: weather.primaryColor,
            ),
          ),
        );
      },
    );
  }
}

class _ParallaxPainter extends CustomPainter {
  final double progress;
  final WeatherType weatherType;
  final Color primaryColor;

  _ParallaxPainter({
    required this.progress,
    required this.weatherType,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 远景层：天空渐变
    _drawSky(canvas, size);
    // 中景层：云朵/星星
    _drawMiddleLayer(canvas, size);
    // 近景层：山脉
    _drawMountains(canvas, size);
  }

  void _drawSky(Canvas canvas, Size size) {
    final Color topColor;
    final Color bottomColor;

    switch (weatherType) {
      case WeatherType.sunny:
        topColor = const Color(0xFF1565C0);
        bottomColor = const Color(0xFF42A5F5);
      case WeatherType.cloudy:
        topColor = const Color(0xFF546E7A);
        bottomColor = const Color(0xFF78909C);
      case WeatherType.rainy:
        topColor = const Color(0xFF263238);
        bottomColor = const Color(0xFF455A64);
      case WeatherType.snowy:
        topColor = const Color(0xFF37474F);
        bottomColor = const Color(0xFF78909C);
      case WeatherType.stormy:
        topColor = const Color(0xFF1A237E);
        bottomColor = const Color(0xFF311B92);
    }

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [topColor, bottomColor],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader =
            gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  void _drawMiddleLayer(Canvas canvas, Size size) {
    // 云朵（中速视差）
    final cloudOffset = progress * size.width * 0.3;
    final random = Random(12);
    for (int i = 0; i < 5; i++) {
      final baseX = random.nextDouble() * size.width * 1.5;
      final baseY = size.height * (0.1 + random.nextDouble() * 0.3);
      final cloudX = (baseX + cloudOffset) % (size.width * 1.5) - size.width * 0.25;
      final cloudWidth = 60.0 + random.nextDouble() * 80;
      final cloudHeight = 20.0 + random.nextDouble() * 20;

      final cloudColor = weatherType == WeatherType.stormy
          ? Colors.grey.withValues(alpha: 0.4)
          : Colors.white.withValues(alpha: 0.3 + random.nextDouble() * 0.2);

      // 用多个椭圆组合成云朵
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cloudX, baseY),
          width: cloudWidth,
          height: cloudHeight,
        ),
        Paint()..color = cloudColor,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cloudX - cloudWidth * 0.25, baseY + 5),
          width: cloudWidth * 0.7,
          height: cloudHeight * 0.8,
        ),
        Paint()..color = cloudColor,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cloudX + cloudWidth * 0.2, baseY + 3),
          width: cloudWidth * 0.6,
          height: cloudHeight * 0.9,
        ),
        Paint()..color = cloudColor,
      );
    }

    // 雨天：绘制雨滴
    if (weatherType == WeatherType.rainy || weatherType == WeatherType.stormy) {
      _drawRain(canvas, size);
    }

    // 雪天：绘制雪花
    if (weatherType == WeatherType.snowy) {
      _drawSnow(canvas, size);
    }
  }

  void _drawRain(Canvas canvas, Size size) {
    final rainPaint = Paint()
      ..color = Colors.lightBlue.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final random = Random(42);
    for (int i = 0; i < 60; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final y = (baseY + progress * size.height * 3) % size.height;
      final length = 15.0 + random.nextDouble() * 15;
      canvas.drawLine(
        Offset(x, y),
        Offset(x - 3, y + length),
        rainPaint,
      );
    }
  }

  void _drawSnow(Canvas canvas, Size size) {
    final snowPaint = Paint()..color = Colors.white.withValues(alpha: 0.7);
    final random = Random(77);
    for (int i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      // 雪花缓慢飘落 + 水平摇摆
      final y = (baseY + progress * size.height * 0.8) % size.height;
      final xOffset = sin(progress * 2 * pi + i) * 20;
      final snowSize = 2.0 + random.nextDouble() * 3;
      canvas.drawCircle(Offset(x + xOffset, y), snowSize, snowPaint);
    }
  }

  void _drawMountains(Canvas canvas, Size size) {
    // 近景山脉（快速视差）
    final mountainOffset = progress * 60;
    final mountainPath = Path();
    mountainPath.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += 2) {
      final normalizedX = (x + mountainOffset) / size.width;
      final y = size.height * 0.7 +
          sin(normalizedX * 2 * pi) * 30 +
          sin(normalizedX * 4 * pi + 1) * 15 +
          cos(normalizedX * 6 * pi + 2) * 8;
      mountainPath.lineTo(x, y);
    }
    mountainPath.lineTo(size.width, size.height);
    mountainPath.close();

    canvas.drawPath(
      mountainPath,
      Paint()..color = const Color(0xFF1B1B2F),
    );

    // 更近的山脉层
    final nearMountainPath = Path();
    nearMountainPath.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 2) {
      final normalizedX = (x + mountainOffset * 2) / size.width;
      final y = size.height * 0.82 +
          sin(normalizedX * 3 * pi + 0.5) * 20 +
          sin(normalizedX * 5 * pi + 1.5) * 10;
      nearMountainPath.lineTo(x, y);
    }
    nearMountainPath.lineTo(size.width, size.height);
    nearMountainPath.close();

    canvas.drawPath(
      nearMountainPath,
      Paint()..color = const Color(0xFF111122),
    );
  }

  @override
  bool shouldRepaint(covariant _ParallaxPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.weatherType != weatherType;
  }
}

// ==================== 天气图标切换 ====================

class _WeatherIconSwitcher extends StatelessWidget {
  final WeatherData weather;

  const _WeatherIconSwitcher({required this.weather});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        // 旧图标向上淡出，新图标从下方弹入
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1.0).animate(animation),
              child: child,
            ),
          ),
        );
      },
      child: Icon(
        weather.icon,
        key: ValueKey(weather.type),
        size: 100,
        color: weather.primaryColor,
        shadows: [
          Shadow(
            color: weather.primaryColor.withValues(alpha: 0.5),
            blurRadius: 30,
          ),
        ],
      ),
    );
  }
}

// ==================== 温度数字滚动 ====================

class _TemperatureDisplay extends StatelessWidget {
  final int temperature;

  const _TemperatureDisplay({required this.temperature});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: temperature.toDouble(), end: temperature.toDouble()),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(
          '${value.round()}°',
          style: const TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.w200,
            color: Colors.white,
            height: 1,
          ),
        );
      },
    );
  }
}

// ==================== 天气详情卡片 ====================

class _WeatherDetailCards extends StatelessWidget {
  final WeatherData weather;

  const _WeatherDetailCards({required this.weather});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildDetailItem(Icons.water_drop_outlined, '${weather.humidity}%', '湿度'),
          _buildDetailItem(Icons.air, '${weather.wind} km/h', '风速'),
          _buildDetailItem(Icons.visibility_outlined, '${weather.visibility} km', '能见度'),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Column(
        key: ValueKey('$label-$value'),
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white70, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ==================== 天气选择器 ====================

class _WeatherSelector extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const _WeatherSelector({
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_weatherList.length, (index) {
          final weather = _weatherList[index];
          final isSelected = index == currentIndex;
          return GestureDetector(
            onTap: () => onSelect(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? weather.primaryColor.withValues(alpha: 0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    weather.icon,
                    color: isSelected ? weather.primaryColor : Colors.white38,
                    size: isSelected ? 28 : 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weather.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white38,
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
