import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.ExprTools;
import haxe.macro.TypeTools;
import haxe.macro.Tools;

class VRMLParser extends CstParser {

	public function new(tokenVocabulary:Map<String,Int>) {
		super(tokenVocabulary);

		var $ = this;

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

		$.RULE('vrml', function() {
			$.SUBRULE($.version);
			$.AT_LEAST_ONE(function() {
				$.SUBRULE($.node);
			});
			$.MANY(function() {
				$.SUBRULE($.route);
			});
		});

		$.RULE('version', function() {
			$.CONSUME(Version);
		});

		$.RULE('node', function() {
			$.OPTION(function() {
				$.SUBRULE($.def);
			});
			$.CONSUME(NodeName);
			$.CONSUME(LCurly);
			$.MANY(function() {
				$.SUBRULE($.field);
			});
			$.CONSUME(RCurly);
		});

		$.RULE('field', function() {
			$.CONSUME(Identifier);
			$.OR2([
				{ALT: function() {
					$.SUBRULE($.singleFieldValue);
				}},
				{ALT: function() {
					$.SUBRULE($.multiFieldValue);
				}}
			]);
		});

		$.RULE('def', function() {
			$.CONSUME(DEF);
			$.OR([
				{ALT: function() {
					$.CONSUME(Identifier);
				}},
				{ALT: function() {
					$.CONSUME(NodeName);
				}}
			]);
		});

		$.RULE('use', function() {
			$.CONSUME(USE);
			$.OR([
				{ALT: function() {
					$.CONSUME(Identifier);
				}},
				{ALT: function() {
					$.CONSUME(NodeName);
				}}
			]);
		});

		$.RULE('singleFieldValue', function() {
			$.AT_LEAST_ONE(function() {
				$.OR([
					{ALT: function() {
						$.SUBRULE($.node);
					}},
					{ALT: function() {
						$.SUBRULE($.use);
					}},
					{ALT: function() {
						$.CONSUME(StringLiteral);
					}},
					{ALT: function() {
						$.CONSUME(HexLiteral);
					}},
					{ALT: function() {
						$.CONSUME(NumberLiteral);
					}},
					{ALT: function() {
						$.CONSUME(TrueLiteral);
					}},
					{ALT: function() {
						$.CONSUME(FalseLiteral);
					}},
					{ALT: function() {
						$.CONSUME(NullLiteral);
					}}
				]);
			});
		});

		$.RULE('multiFieldValue', function() {
			$.CONSUME(LSquare);
			$.MANY(function() {
				$.OR([
					{ALT: function() {
						$.SUBRULE($.node);
					}},
					{ALT: function() {
						$.SUBRULE($.use);
					}},
					{ALT: function() {
						$.CONSUME(StringLiteral);
					}},
					{ALT: function() {
						$.CONSUME(HexLiteral);
					}},
					{ALT: function() {
						$.CONSUME(NumberLiteral);
					}},
					{ALT: function() {
						$.CONSUME(NullLiteral);
					}}
				]);
			});
			$.CONSUME(RSquare);
		});

		$.RULE('route', function() {
			$.CONSUME(ROUTE);
			$.CONSUME(RouteIdentifier);
			$.CONSUME(TO);
			$.CONSUME2(RouteIdentifier);
		});

		this.performSelfAnalysis();
	}
}


**Explanation:**

- **Imports:**  The code imports necessary macro classes from the `haxe.macro` package for working with Haxe's macro system.
- **Class Definition:** The `VRMLParser` class extends the `CstParser` class.
- **Constructor:**
    - Takes a `tokenVocabulary` map as an argument (similar to the JavaScript version).
    - Uses `tokenVocabulary.get(...)` to retrieve the token values from the map.
    - Defines rules using `$.RULE(...)` and `$.SUBRULE(...)`, mirroring the JavaScript structure.
    - **Key Differences:**
        - The Haxe code uses the `$.CONSUME(...)` and `$.CONSUME2(...)` methods for consuming tokens.
        - `$.OR2(...)` and `$.OR(...)` are used for handling alternative rules.
        - The `$.AT_LEAST_ONE(...)` and `$.MANY(...)` methods work similarly to their JavaScript counterparts.
- **`performSelfAnalysis()`:** This method is called at the end to perform self-analysis of the parser, which is necessary for Haxe's macro system.

**To use the Haxe code:**

1. **Compile:** Compile the Haxe code into a `.hx` file.
2. **Create a Main Class:** Create a main class that uses the `VRMLParser` class to parse VRML data.
3. **Tokenize:** Implement a tokenization process to convert your VRML input into a map of tokens (similar to the `tokenVocabulary` used in the constructor).
4. **Instantiate and Parse:** Create an instance of the `VRMLParser` class with the token map and use its parsing methods to process the VRML data.

**Example Usage:**


class Main {
	static function main() {
		// Example VRML input
		var vrmlData = "VERSION 2.0\nSHAPE { APPEARANCE { MATERIAL { diffuseColor 1 0 0 } } GEOMETRY { BOX { size 1 1 1 } } }";

		// Tokenize the VRML data
		var tokenVocabulary = tokenize(vrmlData);

		// Create the VRMLParser
		var parser = new VRMLParser(tokenVocabulary);

		// Parse the VRML data
		parser.vrml();
	}

	// Tokenize function (implementation not shown)
	static function tokenize(vrmlData:String):Map<String,Int> {
		// Implement tokenization here...
		return new Map();
	}
}