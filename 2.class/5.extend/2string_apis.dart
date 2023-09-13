extension NumberParsing on String {
  String padLeft(int width, [String padding = ' ']) {
    if (width <= this.length) {
      return this;
    }
    return padding * (width - this.length) + this;
  }

  int parseInt() => int.parse(this);
}
