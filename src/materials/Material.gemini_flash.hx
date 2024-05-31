import three.math.Color;
import three.core.EventDispatcher;
import three.constants.Constants;
import three.math.MathUtils;

class Material extends EventDispatcher {
	public var isMaterial:Bool;
	public var id:Int;
	public var uuid:String;
	public var name:String;
	public var type:String;
	public var blending:Int;
	public var side:Int;
	public var vertexColors:Bool;
	public var opacity:Float;
	public var transparent:Bool;
	public var alphaHash:Bool;
	public var blendSrc:Int;
	public var blendDst:Int;
	public var blendEquation:Int;
	public var blendSrcAlpha:Null<Int>;
	public var blendDstAlpha:Null<Int>;
	public var blendEquationAlpha:Null<Int>;
	public var blendColor:Color;
	public var blendAlpha:Float;
	public var depthFunc:Int;
	public var depthTest:Bool;
	public var depthWrite:Bool;
	public var stencilWriteMask:Int;
	public var stencilFunc:Int;
	public var stencilRef:Int;
	public var stencilFuncMask:Int;
	public var stencilFail:Int;
	public var stencilZFail:Int;
	public var stencilZPass:Int;
	public var stencilWrite:Bool;
	public var clippingPlanes:Null<Array<three.math.Plane>>;
	public var clipIntersection:Bool;
	public var clipShadows:Bool;
	public var shadowSide:Null<Int>;
	public var colorWrite:Bool;
	public var precision:Null<String>;
	public var polygonOffset:Bool;
	public var polygonOffsetFactor:Float;
	public var polygonOffsetUnits:Float;
	public var dithering:Bool;
	public var alphaToCoverage:Bool;
	public var premultipliedAlpha:Bool;
	public var forceSinglePass:Bool;
	public var visible:Bool;
	public var toneMapped:Bool;
	public var userData:Dynamic;
	public var version:Int;
	private var _alphaTest:Float;

	public function new() {
		super();
		this.isMaterial = true;
		this.id = ++_materialId;
		this.uuid = MathUtils.generateUUID();
		this.name = "";
		this.type = "Material";
		this.blending = Constants.NormalBlending;
		this.side = Constants.FrontSide;
		this.vertexColors = false;
		this.opacity = 1;
		this.transparent = false;
		this.alphaHash = false;
		this.blendSrc = Constants.SrcAlphaFactor;
		this.blendDst = Constants.OneMinusSrcAlphaFactor;
		this.blendEquation = Constants.AddEquation;
		this.blendSrcAlpha = null;
		this.blendDstAlpha = null;
		this.blendEquationAlpha = null;
		this.blendColor = new Color(0, 0, 0);
		this.blendAlpha = 0;
		this.depthFunc = Constants.LessEqualDepth;
		this.depthTest = true;
		this.depthWrite = true;
		this.stencilWriteMask = 0xff;
		this.stencilFunc = Constants.AlwaysStencilFunc;
		this.stencilRef = 0;
		this.stencilFuncMask = 0xff;
		this.stencilFail = Constants.KeepStencilOp;
		this.stencilZFail = Constants.KeepStencilOp;
		this.stencilZPass = Constants.KeepStencilOp;
		this.stencilWrite = false;
		this.clippingPlanes = null;
		this.clipIntersection = false;
		this.clipShadows = false;
		this.shadowSide = null;
		this.colorWrite = true;
		this.precision = null;
		this.polygonOffset = false;
		this.polygonOffsetFactor = 0;
		this.polygonOffsetUnits = 0;
		this.dithering = false;
		this.alphaToCoverage = false;
		this.premultipliedAlpha = false;
		this.forceSinglePass = false;
		this.visible = true;
		this.toneMapped = true;
		this.userData = {};
		this.version = 0;
		this._alphaTest = 0;
	}

	public function get alphaTest():Float {
		return this._alphaTest;
	}

	public function set alphaTest(value:Float) {
		if (this._alphaTest > 0 != value > 0) {
			this.version++;
		}
		this._alphaTest = value;
	}

	public function onBuild( /* shaderobject, renderer */ ) {
	}

	public function onBeforeRender( /* renderer, scene, camera, geometry, object, group */ ) {
	}

	public function onBeforeCompile( /* shaderobject, renderer */ ) {
	}

	public function customProgramCacheKey():String {
		return this.onBeforeCompile.toString();
	}

	public function setValues(values:Dynamic) {
		if (values == null) return;
		for (key in values) {
			var newValue = values[key];
			if (newValue == null) {
				trace("THREE.Material: parameter '${key}' has value of undefined.");
				continue;
			}
			var currentValue = this[key];
			if (currentValue == null) {
				trace("THREE.Material: '${key}' is not a property of THREE.${this.type}.");
				continue;
			}
			if (currentValue != null && Reflect.hasField(currentValue, "isColor")) {
				Reflect.callMethod(currentValue, "set", [newValue]);
			} else if ((currentValue != null && Reflect.hasField(currentValue, "isVector3")) && (newValue != null && Reflect.hasField(newValue, "isVector3"))) {
				Reflect.callMethod(currentValue, "copy", [newValue]);
			} else {
				this[key] = newValue;
			}
		}
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var isRootObject = (meta == null || Reflect.typeof(meta) == "String");
		if (isRootObject) {
			meta = {
				"textures": {},
				"images": {}
			};
		}
		var data:Dynamic = {
			"metadata": {
				"version": 4.6,
				"type": "Material",
				"generator": "Material.toJSON"
			}
		};
		data["uuid"] = this.uuid;
		data["type"] = this.type;
		if (this.name != "") data["name"] = this.name;
		if (this.color != null && Reflect.hasField(this.color, "isColor")) data["color"] = Reflect.callMethod(this.color, "getHex", []);
		if (this.roughness != null) data["roughness"] = this.roughness;
		if (this.metalness != null) data["metalness"] = this.metalness;
		if (this.sheen != null) data["sheen"] = this.sheen;
		if (this.sheenColor != null && Reflect.hasField(this.sheenColor, "isColor")) data["sheenColor"] = Reflect.callMethod(this.sheenColor, "getHex", []);
		if (this.sheenRoughness != null) data["sheenRoughness"] = this.sheenRoughness;
		if (this.emissive != null && Reflect.hasField(this.emissive, "isColor")) data["emissive"] = Reflect.callMethod(this.emissive, "getHex", []);
		if (this.emissiveIntensity != null && this.emissiveIntensity != 1) data["emissiveIntensity"] = this.emissiveIntensity;
		if (this.specular != null && Reflect.hasField(this.specular, "isColor")) data["specular"] = Reflect.callMethod(this.specular, "getHex", []);
		if (this.specularIntensity != null) data["specularIntensity"] = this.specularIntensity;
		if (this.specularColor != null && Reflect.hasField(this.specularColor, "isColor")) data["specularColor"] = Reflect.callMethod(this.specularColor, "getHex", []);
		if (this.shininess != null) data["shininess"] = this.shininess;
		if (this.clearcoat != null) data["clearcoat"] = this.clearcoat;
		if (this.clearcoatRoughness != null) data["clearcoatRoughness"] = this.clearcoatRoughness;
		if (this.clearcoatMap != null && Reflect.hasField(this.clearcoatMap, "isTexture")) {
			data["clearcoatMap"] = Reflect.callMethod(this.clearcoatMap, "toJSON", [meta])["uuid"];
		}
		if (this.clearcoatRoughnessMap != null && Reflect.hasField(this.clearcoatRoughnessMap, "isTexture")) {
			data["clearcoatRoughnessMap"] = Reflect.callMethod(this.clearcoatRoughnessMap, "toJSON", [meta])["uuid"];
		}
		if (this.clearcoatNormalMap != null && Reflect.hasField(this.clearcoatNormalMap, "isTexture")) {
			data["clearcoatNormalMap"] = Reflect.callMethod(this.clearcoatNormalMap, "toJSON", [meta])["uuid"];
			data["clearcoatNormalScale"] = Reflect.callMethod(this.clearcoatNormalScale, "toArray", []);
		}
		if (this.dispersion != null) data["dispersion"] = this.dispersion;
		if (this.iridescence != null) data["iridescence"] = this.iridescence;
		if (this.iridescenceIOR != null) data["iridescenceIOR"] = this.iridescenceIOR;
		if (this.iridescenceThicknessRange != null) data["iridescenceThicknessRange"] = this.iridescenceThicknessRange;
		if (this.iridescenceMap != null && Reflect.hasField(this.iridescenceMap, "isTexture")) {
			data["iridescenceMap"] = Reflect.callMethod(this.iridescenceMap, "toJSON", [meta])["uuid"];
		}
		if (this.iridescenceThicknessMap != null && Reflect.hasField(this.iridescenceThicknessMap, "isTexture")) {
			data["iridescenceThicknessMap"] = Reflect.callMethod(this.iridescenceThicknessMap, "toJSON", [meta])["uuid"];
		}
		if (this.anisotropy != null) data["anisotropy"] = this.anisotropy;
		if (this.anisotropyRotation != null) data["anisotropyRotation"] = this.anisotropyRotation;
		if (this.anisotropyMap != null && Reflect.hasField(this.anisotropyMap, "isTexture")) {
			data["anisotropyMap"] = Reflect.callMethod(this.anisotropyMap, "toJSON", [meta])["uuid"];
		}
		if (this.map != null && Reflect.hasField(this.map, "isTexture")) data["map"] = Reflect.callMethod(this.map, "toJSON", [meta])["uuid"];
		if (this.matcap != null && Reflect.hasField(this.matcap, "isTexture")) data["matcap"] = Reflect.callMethod(this.matcap, "toJSON", [meta])["uuid"];
		if (this.alphaMap != null && Reflect.hasField(this.alphaMap, "isTexture")) data["alphaMap"] = Reflect.callMethod(this.alphaMap, "toJSON", [meta])["uuid"];
		if (this.lightMap != null && Reflect.hasField(this.lightMap, "isTexture")) {
			data["lightMap"] = Reflect.callMethod(this.lightMap, "toJSON", [meta])["uuid"];
			data["lightMapIntensity"] = this.lightMapIntensity;
		}
		if (this.aoMap != null && Reflect.hasField(this.aoMap, "isTexture")) {
			data["aoMap"] = Reflect.callMethod(this.aoMap, "toJSON", [meta])["uuid"];
			data["aoMapIntensity"] = this.aoMapIntensity;
		}
		if (this.bumpMap != null && Reflect.hasField(this.bumpMap, "isTexture")) {
			data["bumpMap"] = Reflect.callMethod(this.bumpMap, "toJSON", [meta])["uuid"];
			data["bumpScale"] = this.bumpScale;
		}
		if (this.normalMap != null && Reflect.hasField(this.normalMap, "isTexture")) {
			data["normalMap"] = Reflect.callMethod(this.normalMap, "toJSON", [meta])["uuid"];
			data["normalMapType"] = this.normalMapType;
			data["normalScale"] = Reflect.callMethod(this.normalScale, "toArray", []);
		}
		if (this.displacementMap != null && Reflect.hasField(this.displacementMap, "isTexture")) {
			data["displacementMap"] = Reflect.callMethod(this.displacementMap, "toJSON", [meta])["uuid"];
			data["displacementScale"] = this.displacementScale;
			data["displacementBias"] = this.displacementBias;
		}
		if (this.roughnessMap != null && Reflect.hasField(this.roughnessMap, "isTexture")) data["roughnessMap"] = Reflect.callMethod(this.roughnessMap, "toJSON", [meta])["uuid"];
		if (this.metalnessMap != null && Reflect.hasField(this.metalnessMap, "isTexture")) data["metalnessMap"] = Reflect.callMethod(this.metalnessMap, "toJSON", [meta])["uuid"];
		if (this.emissiveMap != null && Reflect.hasField(this.emissiveMap, "isTexture")) data["emissiveMap"] = Reflect.callMethod(this.emissiveMap, "toJSON", [meta])["uuid"];
		if (this.specularMap != null && Reflect.hasField(this.specularMap, "isTexture")) data["specularMap"] = Reflect.callMethod(this.specularMap, "toJSON", [meta])["uuid"];
		if (this.specularIntensityMap != null && Reflect.hasField(this.specularIntensityMap, "isTexture")) data["specularIntensityMap"] = Reflect.callMethod(this.specularIntensityMap, "toJSON", [meta])["uuid"];
		if (this.specularColorMap != null && Reflect.hasField(this.specularColorMap, "isTexture")) data["specularColorMap"] = Reflect.callMethod(this.specularColorMap, "toJSON", [meta])["uuid"];
		if (this.envMap != null && Reflect.hasField(this.envMap, "isTexture")) {
			data["envMap"] = Reflect.callMethod(this.envMap, "toJSON", [meta])["uuid"];
			if (this.combine != null) data["combine"] = this.combine;
		}
		if (this.envMapRotation != null) data["envMapRotation"] = Reflect.callMethod(this.envMapRotation, "toArray", []);
		if (this.envMapIntensity != null) data["envMapIntensity"] = this.envMapIntensity;
		if (this.reflectivity != null) data["reflectivity"] = this.reflectivity;
		if (this.refractionRatio != null) data["refractionRatio"] = this.refractionRatio;
		if (this.gradientMap != null && Reflect.hasField(this.gradientMap, "isTexture")) {
			data["gradientMap"] = Reflect.callMethod(this.gradientMap, "toJSON", [meta])["uuid"];
		}
		if (this.transmission != null) data["transmission"] = this.transmission;
		if (this.transmissionMap != null && Reflect.hasField(this.transmissionMap, "isTexture")) data["transmissionMap"] = Reflect.callMethod(this.transmissionMap, "toJSON", [meta])["uuid"];
		if (this.thickness != null) data["thickness"] = this.thickness;
		if (this.thicknessMap != null && Reflect.hasField(this.thicknessMap, "isTexture")) data["thicknessMap"] = Reflect.callMethod(this.thicknessMap, "toJSON", [meta])["uuid"];
		if (this.attenuationDistance != null && this.attenuationDistance != Infinity) data["attenuationDistance"] = this.attenuationDistance;
		if (this.attenuationColor != null) data["attenuationColor"] = Reflect.callMethod(this.attenuationColor, "getHex", []);
		if (this.size != null) data["size"] = this.size;
		if (this.shadowSide != null) data["shadowSide"] = this.shadowSide;
		if (this.sizeAttenuation != null) data["sizeAttenuation"] = this.sizeAttenuation;
		if (this.blending != Constants.NormalBlending) data["blending"] = this.blending;
		if (this.side != Constants.FrontSide) data["side"] = this.side;
		if (this.vertexColors == true) data["vertexColors"] = true;
		if (this.opacity < 1) data["opacity"] = this.opacity;
		if (this.transparent == true) data["transparent"] = true;
		if (this.blendSrc != Constants.SrcAlphaFactor) data["blendSrc"] = this.blendSrc;
		if (this.blendDst != Constants.OneMinusSrcAlphaFactor) data["blendDst"] = this.blendDst;
		if (this.blendEquation != Constants.AddEquation) data["blendEquation"] = this.blendEquation;
		if (this.blendSrcAlpha != null) data["blendSrcAlpha"] = this.blendSrcAlpha;
		if (this.blendDstAlpha != null) data["blendDstAlpha"] = this.blendDstAlpha;
		if (this.blendEquationAlpha != null) data["blendEquationAlpha"] = this.blendEquationAlpha;
		if (this.blendColor != null && Reflect.hasField(this.blendColor, "isColor")) data["blendColor"] = Reflect.callMethod(this.blendColor, "getHex", []);
		if (this.blendAlpha != 0) data["blendAlpha"] = this.blendAlpha;
		if (this.depthFunc != Constants.LessEqualDepth) data["depthFunc"] = this.depthFunc;
		if (this.depthTest == false) data["depthTest"] = this.depthTest;
		if (this.depthWrite == false) data["depthWrite"] = this.depthWrite;
		if (this.colorWrite == false) data["colorWrite"] = this.colorWrite;
		if (this.stencilWriteMask != 0xff) data["stencilWriteMask"] = this.stencilWriteMask;
		if (this.stencilFunc != Constants.AlwaysStencilFunc) data["stencilFunc"] = this.stencilFunc;
		if (this.stencilRef != 0) data["stencilRef"] = this.stencilRef;
		if (this.stencilFuncMask != 0xff) data["stencilFuncMask"] = this.stencilFuncMask;
		if (this.stencilFail != Constants.KeepStencilOp) data["stencilFail"] = this.stencilFail;
		if (this.stencilZFail != Constants.KeepStencilOp) data["stencilZFail"] = this.stencilZFail;
		if (this.stencilZPass != Constants.KeepStencilOp) data["stencilZPass"] = this.stencilZPass;
		if (this.stencilWrite == true) data["stencilWrite"] = this.stencilWrite;
		if (this.rotation != null && this.rotation != 0) data["rotation"] = this.rotation;
		if (this.polygonOffset == true) data["polygonOffset"] = true;
		if (this.polygonOffsetFactor != 0) data["polygonOffsetFactor"] = this.polygonOffsetFactor;
		if (this.polygonOffsetUnits != 0) data["polygonOffsetUnits"] = this.polygonOffsetUnits;
		if (this.linewidth != null && this.linewidth != 1) data["linewidth"] = this.linewidth;
		if (this.dashSize != null) data["dashSize"] = this.dashSize;
		if (this.gapSize != null) data["gapSize"] = this.gapSize;
		if (this.scale != null) data["scale"] = this.scale;
		if (this.dithering == true) data["dithering"] = true;
		if (this.alphaTest > 0) data["alphaTest"] = this.alphaTest;
		if (this.alphaHash == true) data["alphaHash"] = true;
		if (this.alphaToCoverage == true) data["alphaToCoverage"] = true;
		if (this.premultipliedAlpha == true) data["premultipliedAlpha"] = true;
		if (this.forceSinglePass == true) data["forceSinglePass"] = true;
		if (this.wireframe == true) data["wireframe"] = true;
		if (this.wireframeLinewidth > 1) data["wireframeLinewidth"] = this.wireframeLinewidth;
		if (this.wireframeLinecap != "round") data["wireframeLinecap"] = this.wireframeLinecap;
		if (this.wireframeLinejoin != "round") data["wireframeLinejoin"] = this.wireframeLinejoin;
		if (this.flatShading == true) data["flatShading"] = true;
		if (this.visible == false) data["visible"] = false;
		if (this.toneMapped == false) data["toneMapped"] = false;
		if (this.fog == false) data["fog"] = false;
		if (Reflect.fieldCount(this.userData) > 0) data["userData"] = this.userData;
		function extractFromCache(cache:Dynamic) {
			var values:Array<Dynamic> = [];
			for (key in cache) {
				var data = cache[key];
				delete data["metadata"];
				values.push(data);
			}
			return values;
		}
		if (isRootObject) {
			var textures = extractFromCache(meta["textures"]);
			var images = extractFromCache(meta["images"]);
			if (textures.length > 0) data["textures"] = textures;
			if (images.length > 0) data["images"] = images;
		}
		return data;
	}

	public function clone():Material {
		return cast new this.constructor().copy(this);
	}

	public function copy(source:Material):Material {
		this.name = source.name;
		this.blending = source.blending;
		this.side = source.side;
		this.vertexColors = source.vertexColors;
		this.opacity = source.opacity;
		this.transparent = source.transparent;
		this.blendSrc = source.blendSrc;
		this.blendDst = source.blendDst;
		this.blendEquation = source.blendEquation;
		this.blendSrcAlpha = source.blendSrcAlpha;
		this.blendDstAlpha = source.blendDstAlpha;
		this.blendEquationAlpha = source.blendEquationAlpha;
		this.blendColor.copy(source.blendColor);
		this.blendAlpha = source.blendAlpha;
		this.depthFunc = source.depthFunc;
		this.depthTest = source.depthTest;
		this.depthWrite = source.depthWrite;
		this.stencilWriteMask = source.stencilWriteMask;
		this.stencilFunc = source.stencilFunc;
		this.stencilRef = source.stencilRef;
		this.stencilFuncMask = source.stencilFuncMask;
		this.stencilFail = source.stencilFail;
		this.stencilZFail = source.stencilZFail;
		this.stencilZPass = source.stencilZPass;
		this.stencilWrite = source.stencilWrite;
		var srcPlanes = source.clippingPlanes;
		var dstPlanes:Null<Array<three.math.Plane>> = null;
		if (srcPlanes != null) {
			var n = srcPlanes.length;
			dstPlanes = new Array<three.math.Plane>(n);
			for (i in 0...n) {
				dstPlanes[i] = srcPlanes[i].clone();
			}
		}
		this.clippingPlanes = dstPlanes;
		this.clipIntersection = source.clipIntersection;
		this.clipShadows = source.clipShadows;
		this.shadowSide = source.shadowSide;
		this.colorWrite = source.colorWrite;
		this.precision = source.precision;
		this.polygonOffset = source.polygonOffset;
		this.polygonOffsetFactor = source.polygonOffsetFactor;
		this.polygonOffsetUnits = source.polygonOffsetUnits;
		this.dithering = source.dithering;
		this.alphaTest = source.alphaTest;
		this.alphaHash = source.alphaHash;
		this.alphaToCoverage = source.alphaToCoverage;
		this.premultipliedAlpha = source.premultipliedAlpha;
		this.forceSinglePass = source.forceSinglePass;
		this.visible = source.visible;
		this.toneMapped = source.toneMapped;
		this.userData = Json.parse(Json.stringify(source.userData));
		return this;
	}

	public function dispose() {
		this.dispatchEvent({ "type": "dispose" });
	}

	public function set needsUpdate(value:Bool) {
		if (value == true) this.version++;
	}

	static private var _materialId:Int = 0;
}