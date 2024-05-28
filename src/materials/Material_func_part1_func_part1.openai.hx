package three.materials;

import three.math.Color;
import three.core.EventDispatcher;
import three.constants.*;

class Material extends EventDispatcher {
	var id:Int;
	var uuid:String;
	var name:String;
	var type:String;

	var blending:Int;
	var side:Int;
	var vertexColors:Bool;

	var opacity:Float;
	var transparent:Bool;
	var alphaHash:Bool;

	var blendSrc:Int;
	var blendDst:Int;
	var blendEquation:Int;
	var blendSrcAlpha:Null<Int>;
	var blendDstAlpha:Null<Int>;
	var blendEquationAlpha:Null<Int>;
	var blendColor:Color;
	var blendAlpha:Float;

	var depthFunc:Int;
	var depthTest:Bool;
	var depthWrite:Bool;

	var stencilWriteMask:Int;
	var stencilFunc:Int;
	var stencilRef:Int;
	var stencilFuncMask:Int;
	var stencilFail:Int;
	var stencilZFail:Int;
	var stencilZPass:Int;
	var stencilWrite:Bool;

	var clippingPlanes:Array<ClippingPlane>;
	var clipIntersection:Bool;
	var clipShadows:Bool;

	var shadowSide:Null<String>;

	var colorWrite:Bool;

	var precision:Null<String>;

	var polygonOffset:Bool;
	var polygonOffsetFactor:Float;
	var polygonOffsetUnits:Float;

	var dithering:Bool;

	var alphaToCoverage:Bool;
	var premultipliedAlpha:Bool;
	var forceSinglePass:Bool;

	var visible:Bool;

	var toneMapped:Bool;

	var userData:Dynamic;

	var version:Int;

	public function new() {
		super();
		id = _materialId++;
		uuid = MathUtils.generateUUID();
		name = '';
		type = 'Material';

		blending = NormalBlending;
		side = FrontSide;
		vertexColors = false;

		opacity = 1;
		transparent = false;
		alphaHash = false;

		blendSrc = SrcAlphaFactor;
		blendDst = OneMinusSrcAlphaFactor;
		blendEquation = AddEquation;
		blendSrcAlpha = null;
		blendDstAlpha = null;
		blendEquationAlpha = null;
		blendColor = new Color(0, 0, 0);
		blendAlpha = 0;

		depthFunc = LessEqualDepth;
		depthTest = true;
		depthWrite = true;

		stencilWriteMask = 0xff;
		stencilFunc = AlwaysStencilFunc;
		stencilRef = 0;
		stencilFuncMask = 0xff;
		stencilFail = KeepStencilOp;
		stencilZFail = KeepStencilOp;
		stencilZPass = KeepStencilOp;
		stencilWrite = false;

		clippingPlanes = null;
		clipIntersection = false;
		clipShadows = false;

		shadowSide = null;

		colorWrite = true;

		precision = null;

		polygonOffset = false;
		polygonOffsetFactor = 0;
		polygonOffsetUnits = 0;

		dithering = false;

		alphaToCoverage = false;
		premultipliedAlpha = false;
		forceSinglePass = false;

		visible = true;

		toneMapped = true;

		userData = {};

		version = 0;

		_alphaTest = 0;
	}

	public var alphaTest(get, set):Int;
	inline function get_alphaTest():Int {
		return _alphaTest;
	}

	inline function set_alphaTest(value:Int) {
		if (_alphaTest > 0 != value > 0) version++;
		_alphaTest = value;
	}

	dynamic function onBuild(shaderobject:Dynamic, renderer:Dynamic) {}
	dynamic function onBeforeRender(renderer:Dynamic, scene:Dynamic, camera:Dynamic, geometry:Dynamic, object:Dynamic, group:Dynamic) {}
	dynamic function onBeforeCompile(shaderobject:Dynamic, renderer:Dynamic) {}
	inline function customProgramCacheKey():String {
		return onBeforeCompile.toString();
	}

	function setValues(values:Dynamic) {
		if (values == null) return;
		for (key in values) {
			var newValue = values[key];
			if (newValue == null) {
				trace('THREE.Material: parameter \'$key\' has value of undefined.');
				continue;
			}
			var currentValue = this[key];
			if (currentValue == null) {
				trace('THREE.Material: \'$key\' is not a property of THREE.${type}.');
				continue;
			}
			if (Std.isOfType(currentValue, Color)) {
				currentValue.set(newValue);
			} else if (Std.isOfType(currentValue, Vector3)) {
				currentValue.copy(newValue);
			} else {
				this[key] = newValue;
			}
		}
	}

	function toJSON(meta:Dynamic = null):Dynamic {
		var data:Dynamic = {
			metadata: {
				version: 4.6,
				type: 'Material',
				generator: 'Material.toJSON'
			}
		};
		data.uuid = uuid;
		data.type = type;

		if (name != '') data.name = name;

		// ... (rest of the toJSON implementation)

		return data;
	}

	inline function clone():Material {
		return new Material().copy(this);
	}

	function copy(source:Material):Material {
		name = source.name;

		blending = source.blending;
		side = source.side;
		vertexColors = source.vertexColors;

		opacity = source.opacity;
		transparent = source.transparent;

		blendSrc = source.blendSrc;
		blendDst = source.blendDst;
		blendEquation = source.blendEquation;
		blendSrcAlpha = source.blendSrcAlpha;
		blendDstAlpha = source.blendDstAlpha;
		blendEquationAlpha = source.blendEquationAlpha;
		blendColor.copy(source.blendColor);
		blendAlpha = source.blendAlpha;

		depthFunc = source.depthFunc;
		depthTest = source.depthTest;
		depthWrite = source.depthWrite;

		stencilWriteMask = source.stencilWriteMask;
		stencilFunc = source.stencilFunc;
		stencilRef = source.stencilRef;
		stencilFuncMask = source.stencilFuncMask;
		stencilFail = source.stencilFail;
		stencilZFail = source.stencilZFail;
		stencilZPass = source.stencilZPass;
		stencilWrite = source.stencilWrite;

		clippingPlanes = source.clippingPlanes;
		clipIntersection = source.clipIntersection;
		clipShadows = source.clipShadows;

		shadowSide = source.shadowSide;

		colorWrite = source.colorWrite;

		precision = source.precision;

		polygonOffset = source.polygonOffset;
		polygonOffsetFactor = source.polygonOffsetFactor;
		polygonOffsetUnits = source.polygonOffsetUnits;

		dithering = source.dithering;

		alphaToCoverage = source.alphaToCoverage;
		premultipliedAlpha = source.premultipliedAlpha;
		forceSinglePass = source.forceSinglePass;

		visible = source.visible;

		toneMapped = source.toneMapped;

		userData = JSON.parse(JSON.stringify(source.userData));

		return this;
	}

	inline function dispose() {
		dispatchEvent({ type: 'dispose' });
	}

	inline function set_needsUpdate(value:Bool) {
		if (value) version++;
	}
}