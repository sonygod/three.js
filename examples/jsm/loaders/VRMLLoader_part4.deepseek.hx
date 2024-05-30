class VRMLParser extends CstParser {

    public function new(tokenVocabulary:Map<String, Int>) {
        super(tokenVocabulary);

        var Version = tokenVocabulary['Version'];
        var LCurly = tokenVocabulary['LCurly'];
        var RCurly = tokenVocabulary['RCurly'];
        var LSquare = tokenVocabulary['LSquare'];
        var RSquare = tokenVocabulary['RSquare'];
        var Identifier = tokenVocabulary['Identifier'];
        var RouteIdentifier = tokenVocabulary['RouteIdentifier'];
        var StringLiteral = tokenVocabulary['StringLiteral'];
        var HexLiteral = tokenVocabulary['HexLiteral'];
        var NumberLiteral = tokenVocabulary['NumberLiteral'];
        var TrueLiteral = tokenVocabulary['TrueLiteral'];
        var FalseLiteral = tokenVocabulary['FalseLiteral'];
        var NullLiteral = tokenVocabulary['NullLiteral'];
        var DEF = tokenVocabulary['DEF'];
        var USE = tokenVocabulary['USE'];
        var ROUTE = tokenVocabulary['ROUTE'];
        var TO = tokenVocabulary['TO'];
        var NodeName = tokenVocabulary['NodeName'];

        this.RULE('vrml', function () {
            this.SUBRULE(this.version);
            this.AT_LEAST_ONE(function () {
                this.SUBRULE(this.node);
            });
            this.MANY(function () {
                this.SUBRULE(this.route);
            });
        });

        this.RULE('version', function () {
            this.CONSUME(Version);
        });

        this.RULE('node', function () {
            this.OPTION(function () {
                this.SUBRULE(this.def);
            });
            this.CONSUME(NodeName);
            this.CONSUME(LCurly);
            this.MANY(function () {
                this.SUBRULE(this.field);
            });
            this.CONSUME(RCurly);
        });

        this.RULE('field', function () {
            this.CONSUME(Identifier);
            this.OR2([
                {ALT: function () {
                    this.SUBRULE(this.singleFieldValue);
                }},
                {ALT: function () {
                    this.SUBRULE(this.multiFieldValue);
                }}
            ]);
        });

        this.RULE('def', function () {
            this.CONSUME(DEF);
            this.OR([
                {ALT: function () {
                    this.CONSUME(Identifier);
                }},
                {ALT: function () {
                    this.CONSUME(NodeName);
                }}
            ]);
        });

        this.RULE('use', function () {
            this.CONSUME(USE);
            this.OR([
                {ALT: function () {
                    this.CONSUME(Identifier);
                }},
                {ALT: function () {
                    this.CONSUME(NodeName);
                }}
            ]);
        });

        this.RULE('singleFieldValue', function () {
            this.AT_LEAST_ONE(function () {
                this.OR([
                    {ALT: function () {
                        this.SUBRULE(this.node);
                    }},
                    {ALT: function () {
                        this.SUBRULE(this.use);
                    }},
                    {ALT: function () {
                        this.CONSUME(StringLiteral);
                    }},
                    {ALT: function () {
                        this.CONSUME(HexLiteral);
                    }},
                    {ALT: function () {
                        this.CONSUME(NumberLiteral);
                    }},
                    {ALT: function () {
                        this.CONSUME(TrueLiteral);
                    }},
                    {ALT: function () {
                        this.CONSUME(FalseLiteral);
                    }},
                    {ALT: function () {
                        this.CONSUME(NullLiteral);
                    }}
                ]);
            });
        });

        this.RULE('multiFieldValue', function () {
            this.CONSUME(LSquare);
            this.MANY(function () {
                this.OR([
                    {ALT: function () {
                        this.SUBRULE(this.node);
                    }},
                    {ALT: function () {
                        this.SUBRULE(this.use);
                    }},
                    {ALT: function () {
                        this.CONSUME(StringLiteral);
                    }},
                    {ALT: function () {
                        this.CONSUME(HexLiteral);
                    }},
                    {ALT: function () {
                        this.CONSUME(NumberLiteral);
                    }},
                    {ALT: function () {
                        this.CONSUME(NullLiteral);
                    }}
                ]);
            });
            this.CONSUME(RSquare);
        });

        this.RULE('route', function () {
            this.CONSUME(ROUTE);
            this.CONSUME(RouteIdentifier);
            this.CONSUME(TO);
            this.CONSUME2(RouteIdentifier);
        });

        this.performSelfAnalysis();
    }
}