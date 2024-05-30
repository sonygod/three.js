package three.js.examples.jsm.loaders;

import haxe.ds.StringMap;

class VRMLParser extends CstParser
{
    public function new(tokenVocabulary:StringMap<Dynamic>)
    {
        super(tokenVocabulary);

        var $ = this;

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

        $.RULE('vrml', function()
        {
            $.SUBRULE($.version);
            $.AT_LEAST_ONE(function()
            {
                $.SUBRULE($.node);
            });
            $.MANY(function()
            {
                $.SUBRULE($.route);
            });
        });

        $.RULE('version', function()
        {
            $.CONSUME(Version);
        });

        $.RULE('node', function()
        {
            $.OPTION(function()
            {
                $.SUBRULE($.def);
            });
            $.CONSUME(NodeName);
            $.CONSUME(LCurly);
            $.MANY(function()
            {
                $.SUBRULE($.field);
            });
            $.CONSUME(RCurly);
        });

        $.RULE('field', function()
        {
            $.CONSUME(Identifier);
            $.OR2([
                { ALT: function()
                {
                    $.SUBRULE($.singleFieldValue);
                } },
                { ALT: function()
                {
                    $.SUBRULE($.multiFieldValue);
                } }
            ]);
        });

        $.RULE('def', function()
        {
            $.CONSUME(DEF);
            $.OR([
                { ALT: function()
                {
                    $.CONSUME(Identifier);
                } },
                { ALT: function()
                {
                    $.CONSUME(NodeName);
                } }
            ]);
        });

        $.RULE('use', function()
        {
            $.CONSUME(USE);
            $.OR([
                { ALT: function()
                {
                    $.CONSUME(Identifier);
                } },
                { ALT: function()
                {
                    $.CONSUME(NodeName);
                } }
            ]);
        });

        $.RULE('singleFieldValue', function()
        {
            $.AT_LEAST_ONE(function()
            {
                $.OR([
                    { ALT: function()
                    {
                        $.SUBRULE($.node);
                    } },
                    { ALT: function()
                    {
                        $.SUBRULE($.use);
                    } },
                    { ALT: function()
                    {
                        $.CONSUME(StringLiteral);
                    } },
                    { ALT: function()
                    {
                        $.CONSUME(HexLiteral);
                    } },
                    { ALT: function()
                    {
                        $.CONSUME(NumberLiteral);
                    } },
                    { ALT: function()
                    {
                        $.CONSUME(TrueLiteral);
                    } },
                    { ALT: function()
                    {
                        $.CONSUME(FalseLiteral);
                    } },
                    { ALT: function()
                    {
                        $.CONSUME(NullLiteral);
                    } }
                ]);
            });
        });

        $.RULE('multiFieldValue', function()
        {
            $.CONSUME(LSquare);
            $.MANY(function()
            {
                $.OR([
                    { ALT: function()
                    {
                        $.SUBRULE($.node);
                    } },
                    { ALT: function()
                    {
                        $.SUBRULE($.use);
                    } },
                    { ALT: function()
                    {
                        $.CONSUME(StringLiteral);
                    } },
                    { ALT: function()
                    {
                        $.CONSUME(HexLiteral);
                    } },
                    { ALT: function()
                    {
                        $.CONSUME(NumberLiteral);
                    } },
                    { ALT: function()
                    {
                        $.CONSUME(NullLiteral);
                    } }
                ]);
            });
            $.CONSUME(RSquare);
        });

        $.RULE('route', function()
        {
            $.CONSUME(ROUTE);
            $.CONSUME(RouteIdentifier);
            $.CONSUME(TO);
            $.CONSUME2(RouteIdentifier);
        });

        this.performSelfAnalysis();
    }
}