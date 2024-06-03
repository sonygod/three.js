import js.Boot;
import js.html.parser.CstParser;
import js.html.parser.IToken;
import js.html.parser.IProcessedToken;
import js.html.parser.IParserConfig;
import js.html.parser.IRule;
import js.html.parser.ITokenVocabulary;
import js.html.parser.IRecognitionException;
import js.html.parser.ParserRuleContext;
import js.html.parser.ParserRuleContexts;

class VRMLParser {

    private var _parser: CstParser;
    private var _tokenVocabulary: ITokenVocabulary;

    public function new(tokenVocabulary: ITokenVocabulary) {
        _tokenVocabulary = tokenVocabulary;
        _parser = new CstParser(tokenVocabulary);

        var Version: IToken = _tokenVocabulary.get("Version");
        var LCurly: IToken = _tokenVocabulary.get("LCurly");
        var RCurly: IToken = _tokenVocabulary.get("RCurly");
        var LSquare: IToken = _tokenVocabulary.get("LSquare");
        var RSquare: IToken = _tokenVocabulary.get("RSquare");
        var Identifier: IToken = _tokenVocabulary.get("Identifier");
        var RouteIdentifier: IToken = _tokenVocabulary.get("RouteIdentifier");
        var StringLiteral: IToken = _tokenVocabulary.get("StringLiteral");
        var HexLiteral: IToken = _tokenVocabulary.get("HexLiteral");
        var NumberLiteral: IToken = _tokenVocabulary.get("NumberLiteral");
        var TrueLiteral: IToken = _tokenVocabulary.get("TrueLiteral");
        var FalseLiteral: IToken = _tokenVocabulary.get("FalseLiteral");
        var NullLiteral: IToken = _tokenVocabulary.get("NullLiteral");
        var DEF: IToken = _tokenVocabulary.get("DEF");
        var USE: IToken = _tokenVocabulary.get("USE");
        var ROUTE: IToken = _tokenVocabulary.get("ROUTE");
        var TO: IToken = _tokenVocabulary.get("TO");
        var NodeName: IToken = _tokenVocabulary.get("NodeName");

        _parser.rule("vrml", function (): Void {
            _parser.subRule("version");
            _parser.atLeastOne(function (): Void {
                _parser.subRule("node");
            });
            _parser.many(function (): Void {
                _parser.subRule("route");
            });
        });

        _parser.rule("version", function (): Void {
            _parser.consume(Version);
        });

        _parser.rule("node", function (): Void {
            _parser.option(function (): Void {
                _parser.subRule("def");
            });

            _parser.consume(NodeName);
            _parser.consume(LCurly);
            _parser.many(function (): Void {
                _parser.subRule("field");
            });
            _parser.consume(RCurly);
        });

        _parser.rule("field", function (): Void {
            _parser.consume(Identifier);

            _parser.or2([
                function (): Void {
                    _parser.subRule("singleFieldValue");
                },
                function (): Void {
                    _parser.subRule("multiFieldValue");
                }
            ]);
        });

        _parser.rule("def", function (): Void {
            _parser.consume(DEF);
            _parser.or([
                function (): Void {
                    _parser.consume(Identifier);
                },
                function (): Void {
                    _parser.consume(NodeName);
                }
            ]);
        });

        _parser.rule("use", function (): Void {
            _parser.consume(USE);
            _parser.or([
                function (): Void {
                    _parser.consume(Identifier);
                },
                function (): Void {
                    _parser.consume(NodeName);
                }
            ]);
        });

        _parser.rule("singleFieldValue", function (): Void {
            _parser.atLeastOne(function (): Void {
                _parser.or([
                    function (): Void {
                        _parser.subRule("node");
                    },
                    function (): Void {
                        _parser.subRule("use");
                    },
                    function (): Void {
                        _parser.consume(StringLiteral);
                    },
                    function (): Void {
                        _parser.consume(HexLiteral);
                    },
                    function (): Void {
                        _parser.consume(NumberLiteral);
                    },
                    function (): Void {
                        _parser.consume(TrueLiteral);
                    },
                    function (): Void {
                        _parser.consume(FalseLiteral);
                    },
                    function (): Void {
                        _parser.consume(NullLiteral);
                    }
                ]);
            });
        });

        _parser.rule("multiFieldValue", function (): Void {
            _parser.consume(LSquare);
            _parser.many(function (): Void {
                _parser.or([
                    function (): Void {
                        _parser.subRule("node");
                    },
                    function (): Void {
                        _parser.subRule("use");
                    },
                    function (): Void {
                        _parser.consume(StringLiteral);
                    },
                    function (): Void {
                        _parser.consume(HexLiteral);
                    },
                    function (): Void {
                        _parser.consume(NumberLiteral);
                    },
                    function (): Void {
                        _parser.consume(NullLiteral);
                    }
                ]);
            });
            _parser.consume(RSquare);
        });

        _parser.rule("route", function (): Void {
            _parser.consume(ROUTE);
            _parser.consume(RouteIdentifier);
            _parser.consume(TO);
            _parser.consume2(RouteIdentifier);
        });

        _parser.performSelfAnalysis();
    }

    public function parse(input: String): ParserRuleContext {
        return _parser.parse("vrml", input);
    }

}