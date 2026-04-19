import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// =============================================================================
// Riverpod Provider 单元测试示例
// =============================================================================

// --- 被测试的 Provider ---

final counterProvider = StateProvider<int>((ref) => 0);

class CartNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void addItem(String item) {
    if (item.isNotEmpty && !state.contains(item)) {
      state = [...state, item];
    }
  }

  void removeItem(String item) {
    state = state.where((i) => i != item).toList();
  }

  void clear() => state = [];
}

final cartProvider =
    NotifierProvider<CartNotifier, List<String>>(CartNotifier.new);

// --- 测试 ---

void main() {
  group('counterProvider', () {
    test('初始值为 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(counterProvider), 0);
    });

    test('递增', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(counterProvider.notifier).state++;
      container.read(counterProvider.notifier).state++;

      expect(container.read(counterProvider), 2);
    });

    test('可以 override 初始值', () {
      final container = ProviderContainer(
        overrides: [counterProvider.overrideWith((ref) => 100)],
      );
      addTearDown(container.dispose);

      expect(container.read(counterProvider), 100);
    });

    test('listen 可以捕获变化序列', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final values = <int>[];
      container.listen(counterProvider, (prev, next) => values.add(next));

      container.read(counterProvider.notifier).state = 1;
      container.read(counterProvider.notifier).state = 2;
      container.read(counterProvider.notifier).state = 3;

      expect(values, [1, 2, 3]);
    });
  });

  group('CartNotifier', () {
    test('初始为空', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(cartProvider), isEmpty);
    });

    test('添加商品', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(cartProvider.notifier).addItem('商品A');
      container.read(cartProvider.notifier).addItem('商品B');

      expect(container.read(cartProvider), ['商品A', '商品B']);
    });

    test('不允许重复添加', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(cartProvider.notifier).addItem('商品A');
      container.read(cartProvider.notifier).addItem('商品A');

      expect(container.read(cartProvider), ['商品A']);
    });

    test('不允许添加空字符串', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(cartProvider.notifier).addItem('');

      expect(container.read(cartProvider), isEmpty);
    });

    test('删除商品', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(cartProvider.notifier).addItem('商品A');
      container.read(cartProvider.notifier).addItem('商品B');
      container.read(cartProvider.notifier).removeItem('商品A');

      expect(container.read(cartProvider), ['商品B']);
    });

    test('清空购物车', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(cartProvider.notifier).addItem('商品A');
      container.read(cartProvider.notifier).addItem('商品B');
      container.read(cartProvider.notifier).clear();

      expect(container.read(cartProvider), isEmpty);
    });
  });
}
