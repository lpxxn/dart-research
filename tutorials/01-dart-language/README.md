# Dart 语言由浅入深完整教程

本教程从零开始，系统讲解 Dart 语言的核心概念与高级特性，适合有一定编程基础的开发者快速上手 Dart。每章配有详细文档和可运行的示例代码，理论与实践结合，助你扎实掌握 Dart 并为 Flutter 开发打下坚实基础。

## 章节目录

| 编号 | 标题 | 简介 | 文档 | 代码 |
|------|------|------|------|------|
| 01 | Hello Dart | Dart 简介、环境搭建与第一个程序 | [文档](docs/01_hello_dart.md) | [代码](bin/ch01_hello.dart) |
| 02 | 变量与类型 | var/final/const、基本类型、dynamic 与类型系统 | [文档](docs/02_variables_and_types.md) | [代码](bin/ch02_variables.dart) |
| 03 | 运算符 | 算术、逻辑、位运算、级联、展开等全部运算符 | [文档](docs/03_operators.md) | [代码](bin/ch03_operators.dart) |
| 04 | 控制流 | 条件、循环、switch 表达式、断言 | [文档](docs/04_control_flow.md) | [代码](bin/ch04_control_flow.dart) |
| 05 | 函数 | 参数类型、箭头函数、闭包、高阶函数 | [文档](docs/05_functions.md) | [代码](bin/ch05_functions.dart) |
| 06 | 集合 | List、Set、Map 及常用操作方法 | [文档](docs/06_collections.md) | [代码](bin/ch06_collections.dart) |
| 07 | 类与对象 | 类定义、构造函数、getter/setter、静态成员 | [文档](docs/07_classes.md) | [代码](bin/ch07_classes.dart) |
| 08 | 继承与多态 | extends、implements、with mixin | [文档](docs/08_inheritance.md) | [代码](bin/ch08_inheritance.dart) |
| 09 | 抽象类与接口 | 抽象类、隐式接口、工厂模式 | [文档](docs/09_abstracts.md) | [代码](bin/ch09_abstracts.dart) |
| 10 | 泛型 | 泛型类、泛型方法、泛型约束 | [文档](docs/10_generics.md) | [代码](bin/ch10_generics.dart) |
| 11 | 空安全 | 可空类型、?. / ?? / !、late 与 required | [文档](docs/11_null_safety.md) | [代码](bin/ch11_null_safety.dart) |
| 12 | 异步编程 | Future、async/await、Stream | [文档](docs/12_async.md) | [代码](bin/ch12_async.dart) |
| 13 | 异常处理 | try/catch/finally、自定义异常 | [文档](docs/13_exceptions.md) | [代码](bin/ch13_exceptions.dart) |
| 14 | 枚举与模式匹配 | 增强枚举、Dart 3 模式匹配与解构 | [文档](docs/14_enums_patterns.md) | [代码](bin/ch14_enums_patterns.dart) |
| 15 | 扩展与高级特性 | extension 方法、typedef、元数据注解 | [文档](docs/15_extensions.md) | [代码](bin/ch15_extensions.dart) |
| 16 | 包管理与项目实践 | pub 包管理、项目结构、测试与发布 | [文档](docs/16_packages.md) | [代码](bin/ch16_packages.dart) |

## 如何运行

确保已安装 Dart SDK（>= 3.10.4），然后在项目根目录下运行：

```bash
# 运行第 1 章示例
dart run bin/ch01_hello.dart

# 运行第 2 章示例
dart run bin/ch02_variables.dart

# 以此类推...
dart run bin/chXX_xxx.dart
```

也可以使用 `dart analyze` 对项目进行静态分析：

```bash
dart analyze
```
