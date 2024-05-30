class VRMLLoader extends Loader {
	public function new(manager:Dynamic) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
		var scope:Dynamic = this;
		var path:String = (scope.path == '') ? LoaderUtils.extractUrlBase(url) : scope.path;
		var loader:FileLoader = new FileLoader(scope.manager);
		loader.path = scope.path;
		loader.requestHeader = scope.requestHeader;
		loader.withCredentials = scope.withCredentials;
		loader.load(url, function(text:String) {
			try {
				onLoad(scope.parse(text, path));
			} catch (e) {
				if (onError) {
					onError(e);
				} else {
					trace(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(data:String, path:String):Dynamic {
		var nodeMap:Dynamic = { };
		function generateVRMLTree(data:String):Dynamic {
			// create lexer, parser and visitor
			var tokenData:Dynamic = createTokens();
			var lexer:VRMLLexer = new VRMLLexer(tokenData.tokens);
			var parser:VRMLParser = new VRMLParser(tokenData.tokenVocabulary);
			var visitor:Dynamic = createVisitor(parser.getBaseCstVisitorConstructor());
			// lexing
			var lexingResult:Dynamic = lexer.lex(data);
			parser.input = lexingResult.tokens;
			// parsing
			var cstOutput:Dynamic = parser.vrml();
			if (parser.errors.length > 0) {
				trace(parser.errors);
				throw new Error('THREE.VRMLLoader: Parsing errors detected.');
			}
			// actions
			var ast:Dynamic = visitor.visit(cstOutput);
			return ast;
		}
		function createTokens():Dynamic {
			var createToken:Dynamic = chevrotain.createToken;
			// from http://gun.teipir.gr/VRML-amgem/spec/part1/concepts.html#SyntaxBasics
			var RouteIdentifier:Dynamic = createToken({ name: 'RouteIdentifier', pattern: /[^\x30-\x39\0-\x20\x22\x27\x23\x2b\x2c\x2d\x2e\x5b\x5d\x5c\x7b\x7d][^\0-\x20\x22\x27\x23\x2b\x2c\x2d\x2e\x5b\x5d\x5c\x7b\x7d]*[\.][^\x30-\x39\0-\x20\x22\x27\x23\x2b\x2c\x2d\x2e\x5b\x5d\x5c\x7b\x7d][^\0-\x20\x22\x27\x23\x2b\x2c\x2d\x2e\x5b\x5d\x5c\x7b\x7d]*/ });
			var Identifier:Dynamic = createToken({ name: 'Identifier', pattern: /[^\x30-\x39\0-\x20\x22\x27\x23\x2b\x2c\x2d\x2e\x5b\x5d\x5c\x7b\x7d]([^\0-\x20\x22\x27\x23\x2b\x2c\x2e\x5b\x5d\x5c\x7b\x7d]*)/, longer_alt: RouteIdentifier });
			// from http://gun.teipir.gr/VRML-amgem/spec/part1/nodesRef.html
			var nodeTypes:Array<String> = [
				'Anchor', 'Billboard', 'Collision', 'Group', 'Transform', // grouping nodes
				'Inline', 'LOD', 'Switch', // special groups
				'AudioClip', 'DirectionalLight', 'PointLight', 'Script', 'Shape', 'Sound', 'SpotLight', 'WorldInfo', // common nodes
				'CylinderSensor', 'PlaneSensor', 'ProximitySensor', 'SphereSensor', 'TimeSensor', 'TouchSensor', 'VisibilitySensor', // sensors
				'Box', 'Cone', 'Cylinder', 'ElevationGrid', 'Extrusion', 'IndexedFaceSet', 'IndexedLineSet', 'PointSet', 'Sphere', // geometries
				'Color', 'Coordinate', 'Normal', 'TextureCoordinate', // geometric properties
				'Appearance', 'FontStyle', 'ImageTexture', 'Material', 'MovieTexture', 'PixelTexture', 'TextureTransform', // appearance
				'ColorInterpolator', 'CoordinateInterpolator', 'NormalInterpolator', 'OrientationInterpolator', 'PositionInterpolator', 'ScalarInterpolator', // interpolators
				'Background', 'Fog', 'NavigationInfo', 'Viewpoint', // bindable nodes
				'Text' // Text must be placed at the end of the regex so there are no matches for TextureTransform and TextureCoordinate
			];
			//
			var Version:Dynamic = createToken({
				name: 'Version',
				pattern: /#VRML.*/,
				longer_alt: Identifier
			});
			var NodeName:Dynamic = createToken({
				name: 'NodeName',
				pattern: new EReg('|' + nodeTypes.join('|'), 'i'),
				longer_alt: Identifier
			});
			var DEF:Dynamic = createToken({
				name: 'DEF',
				pattern: /DEF/,
				longer_alt: Identifier
			});
			var USE:Dynamic = createToken({
				name: 'USE',
				pattern: /USE/,
				longer_alt: Identifier
			});
			var ROUTE:Dynamic = createToken({
				name: 'ROUTE',
				pattern: /ROUTE/,
				longer_alt: Identifier
			});
			var TO:Dynamic = createToken({
				name: 'TO',
				pattern: /TO/,
				longer_alt: Identifier
			});
			//
			var StringLiteral:Dynamic = createToken({ name: 'StringLiteral', pattern: /"(?:[^\\"\n\r]|\\[bfnrtv"\\/]|\\u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])*"/ });
			var HexLiteral:Dynamic = createToken({ name: 'HexLiteral', pattern: /0[xX][0-9a-fA-F]+/ });
			var NumberLiteral:Dynamic = createToken({ name: 'NumberLiteral', pattern: /[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?/ });
			var TrueLiteral:Dynamic = createToken({ name: 'TrueLiteral', pattern: /TRUE/ });
			var FalseLiteral:Dynamic = createToken({ name: 'FalseLiteral', pattern: /FALSE/ });
			var NullLiteral:Dynamic = createToken({ name: 'NullLiteral', pattern: /NULL/ });
			var LSquare:Dynamic = createToken({ name: 'LSquare', pattern: /\[/ });
			var RSquare:Dynamic = createToken({ name{ name: 'RSquare', pattern: /]/ });
			var LCurly:Dynamic = createToken({ name: 'LCurly', pattern: /{/ });
			var RCurly:Dynamic = createToken({ name: 'RCurly', pattern: /}/ });
			var Comment:Dynamic = createToken({
				name: 'Comment',
				pattern: /#.*/,
				group: chevrotain.Lexer.SKIPPED
			});
			// commas, blanks, tabs, newlines and carriage returns are whitespace characters wherever they appear outside of string fields
			var WhiteSpace:Dynamic = createToken({
				name: 'WhiteSpace',
				pattern: /[ ,\s]/,
				group: chevrotain.Lexer.SKIPPED
			});
			var tokens:Array<Dynamic> = [
				WhiteSpace,
				// keywords appear before the Identifier
				NodeName,
				DEF,
				USE,
				ROUTE,
				TO,
				TrueLiteral,
				FalseLiteral,
				NullLiteral,
				// the Identifier must appear after the keywords because all keywords are valid identifiers
				Version,
				Identifier,
				RouteIdentifier,
				StringLiteral,
				HexLiteral,
				NumberLiteral,
				LSquare,
				RSquare,
				LCurly,
				RCurly,
				Comment
			];
			var tokenVocabulary:Dynamic = { };
			for (i in 0...tokens.length) {
				var token:Dynamic = tokens[i];
				tokenVocabulary[token.name] = token;
			}
			return { tokens: tokens, tokenVocabulary: tokenVocabulary };
		}
		function createVisitor(BaseVRMLVisitor:Dynamic):Dynamic {
			// the visitor is created dynmaically based on the given base class
			class VRMLToASTVisitor extends BaseVRMLVisitor {
				public function new() {
					super();
					this.validateVisitor();
				}
				public function vrml(ctx:Dynamic):Dynamic {
					var data:Dynamic = {
						version: this.visit(ctx.version),
						nodes: [],
						routes: []
					};
					for (i in 0...ctx.node.length) {
						var node:Dynamic = ctx.node[i];
						data.nodes.push(this.visit(node));
					}
					if (ctx.route) {
						for (i in 0...ctx.route.length) {
							var route:Dynamic = ctx.route[i];
							data.routes.push(this.visit(route));
						}
					}
					return data;
				}
				public function version(ctx:Dynamic):Dynamic {
					return ctx.Version[0].image;
				}
				public function node(ctx:Dynamic):Dynamic {
					var data:Dynamic = {
						name: ctx.NodeName[0].image,
						fields: []
					};
					if (ctx.field) {
						for (i in 0...ctx.field.length) {
							var field:Dynamic = ctx.field[i];
							data.fields.push(this.visit(field));
						}
					}
					// DEF
					if (ctx.def) {
						data.DEF = this.visit(ctx.def[0]);
					}
					return data;
				}
				public function field(ctx:Dynamic):Dynamic {
					var data:Dynamic = {
						name: ctx.Identifier[0].image,
						type: null,
						values: null
					};
					var result:Dynamic;
					// SFValue
					if (ctx.singleFieldValue) {
						result = this.visit(ctx.singleFieldValue[0]);
					}
					// MFValue
					if (ctx.multiFieldValue) {
						result = this.visit(ctx.multiFieldValue[0]);
					}
					data.type = result.type;
					data.values = result.values;
					return data;
				}
				public function def(ctx:Dynamic):Dynamic {
					return (ctx.Identifier || ctx.NodeName)[0].image;
				}
				public function use(ctx:Dynamic):Dynamic {
					return { USE: (ctx.Identifier || ctx.NodeName)[0].image };
				}
				public function singleFieldValue(ctx:Dynamic):Dynamic {
					return processField(this, ctx);
				}
				public function multiFieldValue(ctx:Dynamic):Dynamic {
					return processField(this, ctx);
				}
				public function route(ctx:Dynamic):Dynamic {
					var data:Dynamic = {
						FROM: ctx.RouteIdentifier[0].image,
						TO: ctx.RouteIdentifier[1].image
					};
					return data;
				}
			}
			function processField(scope:Dynamic, ctx:Dynamic):Dynamic {
				var field:Dynamic = {
					type: null,
					values: []
				};
				if (ctx.node) {
					field.type = 'node';
					for (i in 0...ctx.node.length) {
						var node:Dynamic = ctx.node[i];
						field.values.push(scope.visit(node));
					}
				}
				if (ctx.use) {
					field.type = 'use';
					for (i in 0...ctx.use.length) {
						var use:Dynamic = ctx.use[i];
						field.values.push(scope.visit(use));
					}
				}
				if (ctx.StringLiteral) {
					field.type = 'string';
					for (i in 0...ctx.StringLiteral.length) {
						var stringLiteral:Dynamic = ctx.StringLiteral[i];
						field.values.push(stringLiteral.image.replace(/'|"/g, ''));
					}
				}
				if (ctx.NumberLiteral) {
					field.type = 'number';
					for (i in 0...ctx.NumberLiteral.length) {
						var numberLiteral:Dynamic = ctx.NumberLiteral[i];
						field.values.push(Std.parseFloat(numberLiteral.image));
					}
				}
				if (ctx.HexLiteral) {
					field.type = 'hex';
					for (i in 0...ctx.HexLiteral.length) {
						var hexLiteral:Dynamic = ctx.HexLiteral[i];
						field.values.push(hexLiteral.image);
					}
				}
				if (ctx.TrueLiteral) {
					field.type = 'boolean';
					for (i in 0...ctx.TrueLiteral.length) {
						var trueLiteral:Dynamic = ctx.TrueLiteral[i];
						if (trueLiteral.image == 'TRUE') field.values.push(true);
					}
				}
				if (ctx.FalseLiteral) {
					field.type = 'boolean';
					for (i in 0...ctx.FalseLiteral.length) {
						var falseLiteral:Dynamic = ctx.FalseLiteral[i];
						if (falseLiteral.image == 'FALSE') field.values.push(false);
					}
				}
				if (ctx.NullLiteral) {
					field.type = 'null';
					for (i in 0...ctx.NullLiteral.length) {
						ctx.NullLiteral.forEach(function() {
							field.values.push(null);
						});
					}
				}
				return field;
			}
			return new VRMLToASTVisitor();
		}
		function parseTree(tree:Dynamic):Dynamic {
			// console.log( JSON.stringify( tree, null, 2 ) );
			var nodes:Dynamic = tree.nodes;
			var scene:Scene = new Scene();
			// first iteration: build nodemap based on DEF statements
			for (i in 0...nodes.length) {
				var node:Dynamic = nodes[i];
				buildNodeMap(node);
			}
			// second iteration: build nodes
			for (i in 0...nodes.length) {
				var node:Dynamic = nodes[i];
				var object:Dynamic = getNode(node);
				if (Std.is(object, Object3D)) scene.add(object);
				if (node.name == 'WorldInfo') scene.userData.worldInfo = object;
			}
			return scene;
		}
		function buildNodeMap(node:Dynamic):Void {
			if (node.DEF) {
				nodeMap[node.DEF] = node;
			}
			var fields:Dynamic = node.fields;
			for (i in 0...fields.length) {
				var field:Dynamic = fields[i];
				if (field.type == 'node') {
					var fieldValues:Dynamic = field.values;
					for (j in 0...fieldValues.length) {
						buildNodeMap(fieldValues[j]);
					}
				}
			}
		}
		function getNode(node:Dynamic):Dynamic {
			// handle case where a node refers to a different one
			if (node.USE) {
				return resolveUSE(node.USE);
			}
			if (node.build != null) return node.build;
			node.build = buildNode(node);
			return node.build;
		}
		// node builder
		function buildNode(node:Dynamic):Dynamic {
			var nodeName:String = node.name;
			var build:Dynamic;
			switch (nodeName) {
				case 'Anchor':
				case 'Group':
				case 'Transform':
				case 'Collision':
					build = buildGroupingNode(node);
					break;
				case 'Background':
					build = buildBackgroundNode(node);
					break;
				case 'Shape':
					build = buildShapeNode(node);
					break