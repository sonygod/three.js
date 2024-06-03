import Er from "chevrotain.VERSION";
import k from "chevrotain.utils";
import xt from "chevrotain.regexpToAst";
import Lt from "chevrotain.regexpToAstCache";
import pn from "chevrotain.lexerOptimize";
import Tr from "chevrotain.lexerDefinitionValidator";
import Xe from "chevrotain.tokenTypes";
import kr from "chevrotain.lexerErrorProvider";
import ft from "chevrotain.lexer";
import Ue from "chevrotain.token";
import ne from "chevrotain.gast";
import Gt from "chevrotain.gastWalker";
import $e from "chevrotain.gastVisitor";
import vt from "chevrotain.gastDsl";
import Lr from "chevrotain.gastFirst";
import Mr from "chevrotain.gastFollow";
import pi from "chevrotain.gastFollowCompute";
import mt from "chevrotain.parserErrorProvider";
import mi from "chevrotain.gastResolver";
import Tt from "chevrotain.gastNext";
import yt from "chevrotain.gastLookahead";
import jr from "chevrotain.gastValidator";
import Ui from "chevrotain.gastUtils";
import et from "chevrotain.errors";
import zr from "chevrotain.parserRecovery";
import Yt from "chevrotain.parserAutomaticLookahead";
import zi from "chevrotain.parserLookahead";
import Hi from "chevrotain.cst";
import Hr from "chevrotain.functionName";
import ea from "chevrotain.cstVisitor";
import ra from "chevrotain.parserTreeBuilder";
import ia from "chevrotain.parserLexerAdapter";
import oa from "chevrotain.parserRecognizerApi";
import la from "chevrotain.parserRecognizerEngine";
import pa from "chevrotain.parserErrorHandler";
import va from "chevrotain.parserContentAssist";
import Ra from "chevrotain.parserGastRecorder";
import Na from "chevrotain.parserPerformanceTracer";
import Ia from "chevrotain.parserMixins";
import ce from "chevrotain.parser";
import La from "chevrotain.syntaxDiagrams";
import Fa from "chevrotain";

class Main {
  static main() {
    // TODO: Add your Haxe code here.
  }
}

Main.main();


This Haxe code imports all the necessary modules from the `chevrotain` library and creates a `Main` class with a `main` method.  However, it doesn't contain any actual code to use the Chevrotain library.

To use Chevrotain in your Haxe project, you'll need to:

1. **Define your token types**: Use `createToken` from the Chevrotain library to define the different tokens your parser will recognize.
2. **Define your grammar**: Use the grammar constructs like `Rule`, `Alternation`, `Option`, `Repetition`, and `Terminal` to define the structure of your language.
3. **Create a parser**: Use the `CstParser` or `EmbeddedActionsParser` classes to create a parser that will use your grammar to parse input text.

You can find examples and documentation for Chevrotain on its website: [https://chevrotain.io/](https://chevrotain.io/)

**Example of defining a token type and grammar in Haxe:**


import chevrotain.Lexer;
import chevrotain.Parser;
import chevrotain.token;
import chevrotain.gast;

class MyTokenType extends token.Token {
  static NAME:String = "MyTokenType";
}

class MyGrammar extends Parser {
  public rule:gast.Rule;

  public constructor() {
    super([MyTokenType]);

    this.rule = new gast.Rule(
      "rule",
      [
        new gast.Terminal(MyTokenType)
      ]
    );

    this.performSelfAnalysis();
  }
}

class MyParser extends Parser {
  public constructor() {
    super(new MyGrammar());
  }
}