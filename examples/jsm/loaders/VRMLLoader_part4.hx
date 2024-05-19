package three.js.examples.jm.loaders;

import haxe.ds.StringMap;

class VRMLParser extends CstParser
{
    public function new(tokenVocabulary:StringMap<Token>) 
    {
        super(tokenVocabulary);

        var $:VRMLParser = this;

        var Version = tokenVocabulary.get('Version');
        var LCurly = tokenVocabulary.get('LCurly');
        var RCurly = tokenVocabulary.get('RCurly');
        var LSquare = tokenVocabulary.get('LSquare');
        var RSquare = tokenVocabulary.get('RSquare');
        var Identifier = tokenVocabulary.get('Identifier');
        var RouteIdentifier = tokenVocabulary.get('RouteIdentifier');
        var StringLiteral = tokenVocabulary.get('StringLiteral');
        var HexLiteral = tokenVocabulary.get('HexLiteral');
        var NumberLiteral = tokenVocabulary.get('NumberLiteral');
        var TrueLiteral = tokenVocabulary.get('TrueLiteral');
        var FalseLiteral = tokenVocabulary.get('FalseLiteral');
        var NullLiteral = tokenVocabulary.get('NullLiteral');
        var DEF = tokenVocabulary.get('DEF');
        var USE = tokenVocabulary.get('USE');
        var ROUTE = tokenVocabulary.get('ROUTE');
        var TO = tokenVocabulary.get('TO');
        var NodeName = tokenVocabulary.get('NodeName');

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