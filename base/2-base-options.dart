// 可空类型
// ??= 赋值运算符，如果变量为null，则赋值
String? name = 'Jane';
String? address = null;
int? a; // = null
a ??= 3;
print(a); // <-- Prints 3.

a ??= 5;
print(a); // <-- Still prints 3.

int? a; // = null
a ??= 3;
print(a); // <-- Prints 3.