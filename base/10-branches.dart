// if
// if case
// swtich

void main(List<String> args) {
  var charCode = 'a';
  var token =
      switch (charCode) { 'a' || 'b' => charCode.codeUnitAt(0), _ => 0 };
  print(token);
}

/*
switch 表达式和 switch 语句的区别
1.不以case开头, 以=>结尾, => 代替了 :
2. case body 是一个表达式,  每个 case 必须有 body 必须有返回值
4. 默认 case 是 _
*/