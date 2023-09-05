import 'dart:math';

typedef VoidFunction = void Function();

class ExceptionWithMessage {
  final String message;
  const ExceptionWithMessage(this.message);
}

abstract class Logger {
  void logException(Type t, [String? msg]);
  void doneLogging();
}

void tryFunction(VoidFunction untrustworthy, Logger logger) {
  try {
    untrustworthy();
  } on ExceptionWithMessage catch (e) {
    logger.logException(e.runtimeType, e.message);
  } on Exception {
    logger.logException(Exception);
  } finally {
    logger.doneLogging();
  }
}

class MyLogger extends Logger {
  Type? lastType;
  String lastMessage = '';
  bool done = false;

  @override
  void doneLogging() {
    done = true;
  }

  @override
  void logException(Type t, [String? msg]) {
    lastType = t;
    lastMessage = msg ?? '';
  }
}

void main() {
  final errs = <String>[];
  var logger = MyLogger();
  try {
    tryFunction(() => throw Exception(), logger);
    if ('${logger.lastType}' != 'Exception' &&
        '${logger.lastType}' != '_Exception') {
      errs.add('Expected Exception, got ${logger.lastType}');
    }
    if (logger.lastMessage != '') {
      errs.add('Expected empty message, got ${logger.lastMessage}');
    }
    if (!logger.done) {
      _result(false, [
        'Untrustworthy threw an ExceptionWithMessage(\'Hey!\'), and an exception of type ${e.runtimeType} was unhandled by tryFunction.'
      ]);
    }
  } catch (e) {
    errs.add('Caught $e');
  }
  try {
    tryFunction(() => throw 'A String', logger)
  }
}

void _result(bool bool, List<String> list) {
  print('bool: $bool, list: $list');
}
