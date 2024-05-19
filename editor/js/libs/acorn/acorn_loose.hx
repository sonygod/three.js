class LooseParser {

  private var _input:String;
  private var _options:acorn.Options;
  private var _toks:Tokenizer;
  private var _tok:Token;
  private var _last:Token;
  private var _ahead:Array<Dynamic>;
  private var _context:Array<Int>;
  private var _curIndent:Int;
  private var _curLineStart:Int;
  private var _nextLineStart:Int;

  constructor(input:String, options:acorn.Options) {
    this._input = input;
    this._options = options;
    this._toks = new Tokenizer(input, options);
    this._tok = new Token();
    this._last = new Token();
    this._ahead = [];
    this._context = [];
    this._curIndent = 0;
    this._curLineStart = 0;
    this._nextLineStart = 0;
    this.next();
  }

  private function next():Void {
    this._last = this._tok;
    if (this._ahead.length > 0) {
      this._tok = this._ahead.shift();
    } else {
      this._tok = this.readToken();
    }

    if (this._tok.start >= this._nextLineStart) {
      this._curLineStart = this._nextLineStart;
      this._nextLineStart = this.lineEnd(this._curLineStart) + 1;
    }
  }

  private function readToken():Token {
    for (;;) {
      this._toks.next();
      if (this._toks.type === tt.dot && this._input.substr(this._toks.end, 1) === ".") {
        this._toks.end++;
        this._toks.type = tt.ellipsis;
      }
      return new Token(this._toks);
    }
  }

  private function resetTo(pos:Int):Void {
    this._toks.pos = pos;
    var ch = this._input.charAt(pos - 1);
    this._toks.exprAllowed = !ch || /[\[\{\(,;:?\/*=+\-~!|&%^<>]/.test(ch) || /[enwfd]/.test(ch) && /\b(keywords|case|else|return|throw|new|in|(instance|type)of|delete|void)$/.test(this._input.slice(pos - 10, pos));

    if (this._options.locations) {
      this._toks.curLine = 1;
      this._toks.lineStart = lineBreakG.lastIndex = 0;
      var match = undefined;
      while ((match = lineBreakG.exec(this._input)) && match.index < pos) {
        ++this._toks.curLine;
        this._toks.lineStart = match.index + match[0].length;
      }
    }
  }

  private function lookAhead(n:Int):Token {
    while (n > this._ahead.length) this._ahead.push(this.readToken());
    return this._ahead[n - 1];
  }

  // ...

}