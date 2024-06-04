import three.extras.loaders.FileLoader;
import three.extras.loaders.Loader;
import three.extras.loaders.TextureLoader;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;
import three.math.Color;
import three.textures.Texture;
import three.textures.RepeatWrapping;
import three.materials.MeshBasicMaterial;
import three.materials.MeshPhysicalMaterial;
import three.nodes.Nodes;
import three.nodes.FloatNode;
import three.nodes.ColorNode;
import three.nodes.Vec2Node;
import three.nodes.Vec3Node;
import three.nodes.Vec4Node;
import three.nodes.IntNode;
import three.nodes.BoolNode;
import three.nodes.PositionLocalNode;
import three.nodes.PositionWorldNode;
import three.nodes.UVNode;
import three.nodes.VertexColorNode;
import three.nodes.NormalLocalNode;
import three.nodes.NormalWorldNode;
import three.nodes.TangentLocalNode;
import three.nodes.TangentWorldNode;
import three.nodes.TextureNode;
import three.nodes.TransformUVNode;
import three.nodes.add;
import three.nodes.sub;
import three.nodes.mul;
import three.nodes.div;
import three.nodes.mod;
import three.nodes.abs;
import three.nodes.sign;
import three.nodes.floor;
import three.nodes.ceil;
import three.nodes.round;
import three.nodes.pow;
import three.nodes.sin;
import three.nodes.cos;
import three.nodes.tan;
import three.nodes.asin;
import three.nodes.acos;
import three.nodes.atan2;
import three.nodes.sqrt;
import three.nodes.exp;
import three.nodes.clamp;
import three.nodes.min;
import three.nodes.max;
import three.nodes.normalize;
import three.nodes.length;
import three.nodes.dot;
import three.nodes.cross;
import three.nodes.normalMap;
import three.nodes.remap;
import three.nodes.smoothstep;
import three.nodes.luminance;
import three.nodes.mx_rgbtohsv;
import three.nodes.mx_hsvtorgb;
import three.nodes.mix;
import three.nodes.mx_ramplr;
import three.nodes.mx_ramptb;
import three.nodes.mx_splitlr;
import three.nodes.mx_splittb;
import three.nodes.mx_fractal_noise_float;
import three.nodes.mx_noise_float;
import three.nodes.mx_cell_noise_float;
import three.nodes.mx_worley_noise_float;
import three.nodes.mx_safepower;
import three.nodes.mx_contrast;
import three.nodes.mx_srgb_texture_to_lin_rec709;
import three.nodes.saturation;

class MXElement {
	public var name:String;
	public var nodeFunc:Dynamic;
	public var params:Array<String>;

	public function new(name:String, nodeFunc:Dynamic, params:Array<String> = null) {
		this.name = name;
		this.nodeFunc = nodeFunc;
		this.params = params;
	}
}

// Ref: https://github.com/mrdoob/three.js/issues/24674

var mx_add = (in1:Dynamic, in2:Dynamic = new FloatNode(0)) -> add(in1, in2);
var mx_subtract = (in1:Dynamic, in2:Dynamic = new FloatNode(0)) -> sub(in1, in2);
var mx_multiply = (in1:Dynamic, in2:Dynamic = new FloatNode(1)) -> mul(in1, in2);
var mx_divide = (in1:Dynamic, in2:Dynamic = new FloatNode(1)) -> div(in1, in2);
var mx_modulo = (in1:Dynamic, in2:Dynamic = new FloatNode(1)) -> mod(in1, in2);
var mx_power = (in1:Dynamic, in2:Dynamic = new FloatNode(1)) -> pow(in1, in2);
var mx_atan2 = (in1:Dynamic = new FloatNode(0), in2:Dynamic = new FloatNode(1)) -> atan2(in1, in2);

var MXElements:Array<MXElement> = [

	// << Math >>
	new MXElement('add', mx_add, ['in1', 'in2']),
	new MXElement('subtract', mx_subtract, ['in1', 'in2']),
	new MXElement('multiply', mx_multiply, ['in1', 'in2']),
	new MXElement('divide', mx_divide, ['in1', 'in2']),
	new MXElement('modulo', mx_modulo, ['in1', 'in2']),
	new MXElement('absval', abs, ['in1', 'in2']),
	new MXElement('sign', sign, ['in1', 'in2']),
	new MXElement('floor', floor, ['in1', 'in2']),
	new MXElement('ceil', ceil, ['in1', 'in2']),
	new MXElement('round', round, ['in1', 'in2']),
	new MXElement('power', mx_power, ['in1', 'in2']),
	new MXElement('sin', sin, ['in']),
	new MXElement('cos', cos, ['in']),
	new MXElement('tan', tan, ['in']),
	new MXElement('asin', asin, ['in']),
	new MXElement('acos', acos, ['in']),
	new MXElement('atan2', mx_atan2, ['in1', 'in2']),
	new MXElement('sqrt', sqrt, ['in']),
	//new MtlXElement( 'ln', ... ),
	new MXElement('exp', exp, ['in']),
	new MXElement('clamp', clamp, ['in', 'low', 'high']),
	new MXElement('min', min, ['in1', 'in2']),
	new MXElement('max', max, ['in1', 'in2']),
	new MXElement('normalize', normalize, ['in']),
	new MXElement('magnitude', length, ['in1', 'in2']),
	new MXElement('dotproduct', dot, ['in1', 'in2']),
	new MXElement('crossproduct', cross, ['in']),
	//new MtlXElement( 'transformpoint', ... ),
	//new MtlXElement( 'transformvector', ... ),
	//new MtlXElement( 'transformnormal', ... ),
	//new MtlXElement( 'transformmatrix', ... ),
	new MXElement('normalmap', normalMap, ['in', 'scale']),
	//new MtlXElement( 'transpose', ... ),
	//new MtlXElement( 'determinant', ... ),
	//new MtlXElement( 'invertmatrix', ... ),
	//new MtlXElement( 'rotate2d', rotateUV, [ 'in', radians( 'amount' )** ] ),
	//new MtlXElement( 'rotate3d', ... ),
	//new MtlXElement( 'arrayappend', ... ),
	//new MtlXElement( 'dot', ... ),

	// << Adjustment >>
	new MXElement('remap', remap, ['in', 'inlow', 'inhigh', 'outlow', 'outhigh']),
	new MXElement('smoothstep', smoothstep, ['in', 'low', 'high']),
	//new MtlXElement( 'curveadjust', ... ),
	//new MtlXElement( 'curvelookup', ... ),
	new MXElement('luminance', luminance, ['in', 'lumacoeffs']),
	new MXElement('rgbtohsv', mx_rgbtohsv, ['in']),
	new MXElement('hsvtorgb', mx_hsvtorgb, ['in']),

	// << Mix >>
	new MXElement('mix', mix, ['bg', 'fg', 'mix']),

	// << Channel >>
	new MXElement('combine2', new Vec2Node, ['in1', 'in2']),
	new MXElement('combine3', new Vec3Node, ['in1', 'in2', 'in3']),
	new MXElement('combine4', new Vec4Node, ['in1', 'in2', 'in3', 'in4']),

	// << Procedural >>
	new MXElement('ramplr', mx_ramplr, ['valuel', 'valuer', 'texcoord']),
	new MXElement('ramptb', mx_ramptb, ['valuet', 'valueb', 'texcoord']),
	new MXElement('splitlr', mx_splitlr, ['valuel', 'valuer', 'texcoord']),
	new MXElement('splittb', mx_splittb, ['valuet', 'valueb', 'texcoord']),
	new MXElement('noise2d', mx_noise_float, ['texcoord', 'amplitude', 'pivot']),
	new MXElement('noise3d', mx_noise_float, ['texcoord', 'amplitude', 'pivot']),
	new MXElement('fractal3d', mx_fractal_noise_float, ['position', 'octaves', 'lacunarity', 'diminish', 'amplitude']),
	new MXElement('cellnoise2d', mx_cell_noise_float, ['texcoord']),
	new MXElement('cellnoise3d', mx_cell_noise_float, ['texcoord']),
	new MXElement('worleynoise2d', mx_worley_noise_float, ['texcoord', 'jitter']),
	new MXElement('worleynoise3d', mx_worley_noise_float, ['texcoord', 'jitter']),

	// << Supplemental >>
	//new MtlXElement( 'tiledimage', ... ),
	//new MtlXElement( 'triplanarprojection', triplanarTextures, [ 'filex', 'filey', 'filez' ] ),
	//new MtlXElement( 'ramp4', ... ),
	//new MtlXElement( 'place2d', mx_place2d, [ 'texcoord', 'pivot', 'scale', 'rotate', 'offset' ] ),
	new MXElement('safepower', mx_safepower, ['in1', 'in2']),
	new MXElement('contrast', mx_contrast, ['in', 'amount', 'pivot']),
	//new MtlXElement( 'hsvadjust', ... ),
	new MXElement('saturate', saturation, ['in', 'amount']),
	//new MtlXElement( 'extract', ... ),
	//new MtlXElement( 'separate2', ... ),
	//new MtlXElement( 'separate3', ... ),
	//new MtlXElement( 'separate4', ... )

];

var MtlXLibrary:Map<String, MXElement> = new Map();
for (element in MXElements) {
	MtlXLibrary.set(element.name, element);
}

class MaterialXLoader extends Loader {
	public function new(manager:Dynamic) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Loader {
		var _onError = function(e:Dynamic) {
			if (onError != null) {
				onError(e);
			} else {
				console.error(e);
			}
		};
		new FileLoader(this.manager).setPath(this.path).load(url, function(text:String) {
			try {
				onLoad(this.parse(text));
			} catch(e:Dynamic) {
				_onError(e);
			}
		}, onProgress, _onError);
		return this;
	}

	public function parse(text:String):Dynamic {
		return new MaterialX(this.manager, this.path).parse(text);
	}
}

class MaterialXNode {
	public var materialX:MaterialX;
	public var nodeXML:Dynamic;
	public var nodePath:String;
	public var parent:MaterialXNode;
	public var node:Dynamic;
	public var children:Array<MaterialXNode>;

	public function new(materialX:MaterialX, nodeXML:Dynamic, nodePath:String = '') {
		this.materialX = materialX;
		this.nodeXML = nodeXML;
		this.nodePath = nodePath != '' ? nodePath + '/' + this.name : this.name;
		this.parent = null;
		this.node = null;
		this.children = new Array();
	}

	public function get element():String {
		return this.nodeXML.nodeName;
	}

	public function get nodeGraph():String {
		return this.getAttribute('nodegraph');
	}

	public function get nodeName():String {
		return this.getAttribute('nodename');
	}

	public function get interfaceName():String {
		return this.getAttribute('interfacename');
	}

	public function get output():String {
		return this.getAttribute('output');
	}

	public function get name():String {
		return this.getAttribute('name');
	}

	public function get type():String {
		return this.getAttribute('type');
	}

	public function get value():String {
		return this.getAttribute('value');
	}

	public function getNodeGraph():MaterialXNode {
		var nodeX:MaterialXNode = this;
		while (nodeX != null) {
			if (nodeX.element == 'nodegraph') {
				break;
			}
			nodeX = nodeX.parent;
		}
		return nodeX;
	}

	public function getRoot():MaterialXNode {
		var nodeX:MaterialXNode = this;
		while (nodeX.parent != null) {
			nodeX = nodeX.parent;
		}
		return nodeX;
	}

	public function get referencePath():String {
		var referencePath:String = null;
		if (this.nodeGraph != null && this.output != null) {
			referencePath = this.nodeGraph + '/' + this.output;
		} else if (this.nodeName != null || this.interfaceName != null) {
			referencePath = this.getNodeGraph().nodePath + '/' + (this.nodeName != null ? this.nodeName : this.interfaceName);
		}
		return referencePath;
	}

	public function get hasReference():Bool {
		return this.referencePath != null;
	}

	public function get isConst():Bool {
		return this.element == 'input' && this.value != null && this.type != 'filename';
	}

	public function getColorSpaceNode():Dynamic {
		var csSource:String = this.getAttribute('colorspace');
		var csTarget:String = this.getRoot().getAttribute('colorspace');
		var nodeName:String = 'mx_' + csSource + '_to_' + csTarget;
		return colorSpaceLib[nodeName];
	}

	public function getTexture():Texture {
		var filePrefix:String = this.getRecursiveAttribute('fileprefix') != null ? this.getRecursiveAttribute('fileprefix') : '';
		var loader:TextureLoader = this.materialX.textureLoader;
		var uri:String = filePrefix + this.value;
		if (uri != null) {
			var handler:Dynamic = this.materialX.manager.getHandler(uri);
			if (handler != null) loader = handler;
		}
		var texture:Texture = loader.load(uri);
		texture.wrapS = texture.wrapT = RepeatWrapping;
		texture.flipY = false;
		return texture;
	}

	public function getClassFromType(type:String):Dynamic {
		var nodeClass:Dynamic = null;
		if (type == 'integer') nodeClass = new IntNode;
		else if (type == 'float') nodeClass = new FloatNode;
		else if (type == 'vector2') nodeClass = new Vec2Node;
		else if (type == 'vector3') nodeClass = new Vec3Node;
		else if (type == 'vector4' || type == 'color4') nodeClass = new Vec4Node;
		else if (type == 'color3') nodeClass = new ColorNode;
		else if (type == 'boolean') nodeClass = new BoolNode;
		return nodeClass;
	}

	public function getNode():Dynamic {
		var node:Dynamic = this.node;
		if (node != null) {
			return node;
		}
		var type:String = this.type;
		if (this.isConst) {
			var nodeClass:Dynamic = this.getClassFromType(type);
			node = nodeClass.new(...this.getVector());
		} else if (this.hasReference) {
			node = this.materialX.getMaterialXNode(this.referencePath).getNode();
		} else {
			var element:String = this.element;
			if (element == 'convert') {
				var nodeClass:Dynamic = this.getClassFromType(type);
				node = nodeClass.new(this.getNodeByName('in'));
			} else if (element == 'constant') {
				node = this.getNodeByName('value');
			} else if (element == 'position') {
				var space:String = this.getAttribute('space');
				node = space == 'world' ? new PositionWorldNode : new PositionLocalNode;
			} else if (element == 'normal') {
				var space:String = this.getAttribute('space');
				node = space == 'world' ? new NormalWorldNode : new NormalLocalNode;
			} else if (element == 'tangent') {
				var space:String = this.getAttribute('space');
				node = space == 'world' ? new TangentWorldNode : new TangentLocalNode;
			} else if (element == 'texcoord') {
				var indexNode:MaterialXNode = this.getChildByName('index');
				var index:Int = indexNode != null ? Std.parseInt(indexNode.value) : 0;
				node = new UVNode(index);
			} else if (element == 'geomcolor') {
				var indexNode:MaterialXNode = this.getChildByName('index');
				var index:Int = indexNode != null ? Std.parseInt(indexNode.value) : 0;
				node = new VertexColorNode(index);
			} else if (element == 'tiledimage') {
				var file:MaterialXNode = this.getChildByName('file');
				var textureFile:Texture = file.getTexture();
				var uvTiling:TransformUVNode = new TransformUVNode(...this.getNodesByNames(['uvtiling', 'uvoffset']));
				node = new TextureNode(textureFile, uvTiling);
				var colorSpaceNode:Dynamic = file.getColorSpaceNode();
				if (colorSpaceNode != null) {
					node = colorSpaceNode.new(node);
				}
			} else if (element == 'image') {
				var file:MaterialXNode = this.getChildByName('file');
				var uvNode:Dynamic = this.getNodeByName('texcoord');
				var textureFile:Texture = file.getTexture();
				node = new TextureNode(textureFile, uvNode);
				var colorSpaceNode:Dynamic = file.getColorSpaceNode();
				if (colorSpaceNode != null) {
					node = colorSpaceNode.new(node);
				}
			} else if (MtlXLibrary.exists(element)) {
				var nodeElement:MXElement = MtlXLibrary.get(element);
				node = nodeElement.nodeFunc.new(...this.getNodesByNames(...nodeElement.params));
			}
		}
		if (node == null) {
			console.warn('THREE.MaterialXLoader: Unexpected node ' + new XMLSerializer().serializeToString(this.nodeXML) + '.');
			node = new FloatNode(0);
		}
		var nodeToTypeClass:Dynamic = this.getClassFromType(type);
		if (nodeToTypeClass != null) {
			node = nodeToTypeClass.new(node);
		}
		node.name = this.name;
		this.node = node;
		return node;
	}

	public function getChildByName(name:String):MaterialXNode {
		for (input in this.children) {
			if (input.name == name) {
				return input;
			}
		}
	}

	public function getNodes():Map<String, Dynamic> {
		var nodes:Map<String, Dynamic> = new Map();
		for (input in this.children) {
			var node:Dynamic = input.getNode();
			nodes.set(node.name, node);
		}
		return nodes;
	}

	public function getNodeByName(name:String):Dynamic {
		var child:MaterialXNode = this.getChildByName(name);
		return child != null ? child.getNode() : null;
	}

	public function getNodesByNames(...names:Array<String>):Array<Dynamic> {
		var nodes:Array<Dynamic> = new Array();
		for (name in names) {
			var node:Dynamic = this.getNodeByName(name);
			if (node != null) nodes.push(node);
		}
		return nodes;
	}

	public function getValue():String {
		return this.value.trim();
	}

	public function getVector():Array<Float> {
		var vector:Array<Float> = new Array();
		for (val in this.getValue().split(/[,|\s]/)) {
			if (val != '') {
				vector.push(Std.parseFloat(val.trim()));
			}
		}
		return vector;
	}

	public function getAttribute(name:String):String {
		return this.nodeXML.getAttribute(name);
	}

	public function getRecursiveAttribute(name:String):String {
		var attribute:String = this.nodeXML.getAttribute(name);
		if (attribute == null && this.parent != null) {
			attribute = this.parent.getRecursiveAttribute(name);
		}
		return attribute;
	}

	public function setStandardSurfaceToGltfPBR(material:MeshPhysicalMaterial) {
		var inputs:Map<String, Dynamic> = this.getNodes();
		var colorNode:Dynamic = null;
		if (inputs.exists('base') && inputs.exists('base_color')) colorNode = mul(inputs.get('base'), inputs.get('base_color'));
		else if (inputs.exists('base')) colorNode = inputs.get('base');
		else if (inputs.exists('base_color')) colorNode = inputs.get('base_color');
		var roughnessNode:Dynamic = null;
		if (inputs.exists('specular_roughness')) roughnessNode = inputs.get('specular_roughness');
		var metalnessNode:Dynamic = null;
		if (inputs.exists('metalness')) metalnessNode = inputs.get('metalness');
		var clearcoatNode:Dynamic = null;
		var clearcoatRoughnessNode:Dynamic = null;
		if (inputs.exists('coat')) clearcoatNode = inputs.get('coat');
		if (inputs.exists('coat_roughness')) clearcoatRoughnessNode = inputs.get('coat_roughness');
		if (inputs.exists('coat_color')) {
			colorNode = colorNode != null ? mul(colorNode, inputs.get('coat_color')) : colorNode;
		}
		var normalNode:Dynamic = null;
		if (inputs.exists('normal')) normalNode = inputs.get('normal');
		var emissiveNode:Dynamic = null;
		if (inputs.exists('emission')) emissiveNode = inputs.get('emission');
		if (inputs.exists('emissionColor')) {
			emissiveNode = emissiveNode != null ? mul(emissiveNode, inputs.get('emissionColor')) : emissiveNode;
		}
		material.colorNode = colorNode != null ? colorNode : new ColorNode(0.8, 0.8, 0.8);
		material.roughnessNode = roughnessNode != null ? roughnessNode : new FloatNode(0.2);
		material.metalnessNode = metalnessNode != null ? metalnessNode : new FloatNode(0);
		material.clearcoatNode = clearcoatNode != null ? clearcoatNode : new FloatNode(0);
		material.clearcoatRoughnessNode = clearcoatRoughnessNode != null ? clearcoatRoughnessNode : new FloatNode(0);
		if (normalNode != null) material.normalNode = normalNode;
		if (emissiveNode != null) material.emissiveNode = emissiveNode;
	}

	/*setGltfPBR( material ) {

		const inputs = this.getNodes();

		console.log( inputs );

	}*/

	public function setMaterial(material:Dynamic) {
		var element:String = this.element;
		if (element == 'gltf_pbr') {
			//this.setGltfPBR( material );
		} else if (element == 'standard_surface') {
			this.setStandardSurfaceToGltfPBR(material);
		}
	}

	public function toBasicMaterial():MeshBasicMaterial {
		var material:MeshBasicMaterial = new MeshBasicMaterial();
		material.name = this.name;
		for (nodeX in this.children.reverse()) {
			if (nodeX.name == 'out') {
				material.colorNode = nodeX.getNode();
				break;
			}
		}
		return material;
	}

	public function toPhysicalMaterial():MeshPhysicalMaterial {
		var material:MeshPhysicalMaterial = new MeshPhysicalMaterial();
		material.name = this.name;
		for (nodeX in this.children) {
			var shaderProperties:MaterialXNode = this.materialX.getMaterialXNode(nodeX.nodeName);
			shaderProperties.setMaterial(material);
		}
		return material;
	}

	public function toMaterials():Map<String, Dynamic> {
		var materials:Map<String, Dynamic> = new Map();
		var isUnlit:Bool = true;
		for (nodeX in this.children) {
			if (nodeX.element == 'surfacematerial') {
				var material:MeshPhysicalMaterial = nodeX.toPhysicalMaterial();
				materials.set(material.name, material);
				isUnlit = false;
			}
		}
		if (isUnlit) {
			for (nodeX in this.children) {
				if (nodeX.element == 'nodegraph') {
					var material:MeshBasicMaterial = nodeX.toBasicMaterial();
					materials.set(material.name, material);
				}
			}
		}
		return materials;
	}

	public function add(materialXNode:MaterialXNode) {
		materialXNode.parent = this;
		this.children.push(materialXNode);
	}
}

class MaterialX {
	public var manager:Dynamic;
	public var path:String;
	public var resourcePath:String;
	public var nodesXLib:Map<String, MaterialXNode>;
	//this.nodesXRefLib = new WeakMap();
	public var textureLoader:TextureLoader;

	public function new(manager:Dynamic, path:String) {
		this.manager = manager;
		this.path = path;
		this.resourcePath = '';
		this.nodesXLib = new Map();
		//this.nodesXRefLib = new WeakMap();
		this.textureLoader = new TextureLoader(manager);
	}

	public function addMaterialXNode(materialXNode:MaterialXNode) {
		this.nodesXLib.set(materialXNode.nodePath, materialXNode);
	}

	/*getMaterialXNodeFromXML( xmlNode ) {

        return this.nodesXRefLib.get( xmlNode );

    }*/

	public function getMaterialXNode(...names:Array<String>):MaterialXNode {
		return this.nodesXLib.get(names.join('/'));
	}

	public function parseNode(nodeXML:Dynamic, nodePath:String = ''):MaterialXNode {
		var materialXNode:MaterialXNode = new MaterialXNode(this, nodeXML, nodePath);
		if (materialXNode.nodePath != null) this.addMaterialXNode(materialXNode);
		for (childNodeXML in nodeXML.children) {
			var childMXNode:MaterialXNode = this.parseNode(childNodeXML, materialXNode.nodePath);
			materialXNode.add(childMXNode);
		}
		return materialXNode;
	}

	public function parse(text:String):Dynamic {
		var rootXML:Dynamic = new DOMParser().parseFromString(text, 'application/xml').documentElement;
		this.textureLoader.setPath(this.path);
		var materials:Map<String, Dynamic> = this.parseNode(rootXML).toMaterials();
		return {materials:materials};
	}
}

var colorSpaceLib:Map<String, Dynamic> = new Map();
colorSpaceLib.set('mx_srgb_texture_to_lin_rec709', mx_srgb_texture_to_lin_rec709);

export class MaterialXLoader extends MaterialXLoader {
}