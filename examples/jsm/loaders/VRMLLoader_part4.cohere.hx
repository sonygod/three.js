class VRMLParser extends CstParser {
	public function new(tokenVocabulary:TokenVocabulary) {
		super(tokenVocabulary);
		var $:VRMLParser = { };

		var Version = tokenVocabulary.Version;
		var LCurly = tokenVocabulary.LCurly;
		var RCurly = tokenVocabulary.RCurly;
		var LSquare = tokenVocabulary.LSquare;
		var RSquare = tokenVocabulary.RSquare;
		var Identifier = tokenVocabulary.Identifier;
		var RouteIdentifier = tokenVocabulary.RouteIdentifier;
		var StringLiteral = tokenVocabulary.StringLiteral;
		var HexLiteral = tokenVocabulary.HexLiteral;
		var NumberLiteral = tokenVocabulary.NumberLiteral;
		var TrueLiteral = tokenVocabulary.TrueLiteral;
		var FalseLiteral = tokenVocabulary.FalseLiteral;
		var NullLiteral = tokenVocabulary.NullLiteral;
		var DEF = tokenVocabulary.DEF;
		var USE = tokenVocabulary.USE;
		var ROUTE = tokenVocabulary.ROUTE;
		var TO = tokenVocabulary.TO;
		var NodeName = tokenVocabulary.NodeName;

		$.rule('vrml', function() {
			$.subrule($.version);
			$.atLeastOne(function() {
				$.subrule($.node);
			});
			$.many(function() {
				$.subrule($.route);
			});
		});

		$.rule('version', function() {
			$.consume(Version);
		});

		$.rule('node', function() {
			$.option(function() {
				$.subrule($.def);
			});
			$.consume(NodeName);
			$.consume(LCurly);
			$.many(function() {
				$.subrule($.field);
			});
			$.consume(RCurly);
		});

		$.rule('field', function() {
			$.consume(Identifier);
			$.choice2([
				function() { $.subrule($.singleFieldValue); },
				function() { $.subrule($.multiFieldValue); }
			]);
		});

		$.rule('def', function() {
			$.consume(DEF);
			$.choice([
				function() { $.consume(Identifier); },
				function() { $.consume(NodeName); }
			]);
		});

		$.rule('use', function() {
			$.consume(USE);
			$.choice([
				function() { $.consume(Identifier); },
				function() { $.consume(NodeName); }
			]);
		});

		$.rule('singleFieldValue', function() {
			$.atLeastOne(function() {
				$.choice([
					function() { $.subrule($.node); },
					function() { $.subrule($.use); },
					function() { $.consume(StringLiteral); },
					function() { $.consume(HexLiteral); },
					function() { $.consume(NumberLiteral); },
					function() { $.consume(TrueLiteral); },
					function() { $.consume(FalseLiteral); },
					function() { $.consume(NullLiteral); }
				]);
			});
		});

		$.rule('multiFieldValue', function() {
			$.consume(LSquare);
			$.many(function() {
				$.choice([
					function() { $.subrule($.node); },
					function() { $.subrule($.use); },
					function() { $.consume(StringLiteral); },
					function() { $.consume(HexLiteral); },
					function() { $.consume(NumberLiteral); },
					function() { $.consume(NullLiteral); }
				]);
			});
			$.consume(RSquare);
		});

		$.rule('route', function() {
			$.consume(ROUTE);
			$.consume(RouteIdentifier);
			$.consume(TO);
			$.consume(RouteIdentifier);
		});

		$performSelfAnalysis();
	}
}