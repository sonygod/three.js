import three.math.Color;
import three.core.EventDispatcher;
import three.constants.Constants;
import three.math.MathUtils;

class Material extends EventDispatcher {

	public var isMaterial:Bool = true;
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
	public var clippingPlanes:Null<Array<Dynamic>>;
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
		id = _materialId++;
		uuid = MathUtils.generateUUID();
		name = "";
		type = "Material";
		blending = Constants.NormalBlending;
		side = Constants.FrontSide;
		vertexColors = false;
		opacity = 1;
		transparent = false;
		alphaHash = false;
		blendSrc = Constants.SrcAlphaFactor;
		blendDst = Constants.OneMinusSrcAlphaFactor;
		blendEquation = Constants.AddEquation;
		blendSrcAlpha = null;
		blendDstAlpha = null;
		blendEquationAlpha = null;
		blendColor = new Color(0, 0, 0);
		blendAlpha = 0;
		depthFunc = Constants.LessEqualDepth;
		depthTest = true;
		depthWrite = true;
		stencilWriteMask = 0xff;
		stencilFunc = Constants.AlwaysStencilFunc;
		stencilRef = 0;
		stencilFuncMask = 0xff;
		stencilFail = Constants.KeepStencilOp;
		stencilZFail = Constants.KeepStencilOp;
		stencilZPass = Constants.KeepStencilOp;
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

	public function get alphaTest():Float {
		return _alphaTest;
	}

	public function set alphaTest(value:Float) {
		if (_alphaTest > 0 != value > 0) {
			version++;
		}
		_alphaTest = value;
	}

	public function onBuild(shaderobject:Dynamic, renderer:Dynamic):Void {
	}

	public function onBeforeRender(renderer:Dynamic, scene:Dynamic, camera:Dynamic, geometry:Dynamic, object:Dynamic, group:Dynamic):Void {
	}

	public function onBeforeCompile(shaderobject:Dynamic, renderer:Dynamic):Void {
	}

	public function customProgramCacheKey():String {
		return onBeforeCompile.toString();
	}

	public function setValues(values:Dynamic):Void {
		if (values == null) return;
		for (key in values) {
			var newValue = values[key];
			if (newValue == null) {
				warn("THREE.Material: parameter '${key}' has value of undefined.");
				continue;
			}
			var currentValue = this[key];
			if (currentValue == null) {
				warn("THREE.Material: '${key}' is not a property of THREE.${this.type}.");
				continue;
			}
			if (currentValue != null && currentValue.isColor) {
				currentValue.set(newValue);
			} else if (currentValue != null && currentValue.isVector3 && newValue != null && newValue.isVector3) {
				currentValue.copy(newValue);
			} else {
				this[key] = newValue;
			}
		}
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var isRootObject = (meta == null || typeof meta == "String");
		if (isRootObject) {
			meta = {
				textures: {},
				images: {}
			};
		}
		var data = {
			metadata: {
				version: 4.6,
				type: "Material",
				generator: "Material.toJSON"
			}
		};
		data.uuid = uuid;
		data.type = type;
		if (name != "") data.name = name;
		if (color != null && color.isColor) data.color = color.getHex();
		if (roughness != null) data.roughness = roughness;
		if (metalness != null) data.metalness = metalness;
		if (sheen != null) data.sheen = sheen;
		if (sheenColor != null && sheenColor.isColor) data.sheenColor = sheenColor.getHex();
		if (sheenRoughness != null) data.sheenRoughness = sheenRoughness;
		if (emissive != null && emissive.isColor) data.emissive = emissive.getHex();
		if (emissiveIntensity != null && emissiveIntensity != 1) data.emissiveIntensity = emissiveIntensity;
		if (specular != null && specular.isColor) data.specular = specular.getHex();
		if (specularIntensity != null) data.specularIntensity = specularIntensity;
		if (specularColor != null && specularColor.isColor) data.specularColor = specularColor.getHex();
		if (shininess != null) data.shininess = shininess;
		if (clearcoat != null) data.clearcoat = clearcoat;
		if (clearcoatRoughness != null) data.clearcoatRoughness = clearcoatRoughness;
		if (clearcoatMap != null && clearcoatMap.isTexture) {
			data.clearcoatMap = clearcoatMap.toJSON(meta).uuid;
		}
		if (clearcoatRoughnessMap != null && clearcoatRoughnessMap.isTexture) {
			data.clearcoatRoughnessMap = clearcoatRoughnessMap.toJSON(meta).uuid;
		}
		if (clearcoatNormalMap != null && clearcoatNormalMap.isTexture) {
			data.clearcoatNormalMap = clearcoatNormalMap.toJSON(meta).uuid;
			data.clearcoatNormalScale = clearcoatNormalScale.toArray();
		}
		if (dispersion != null) data.dispersion = dispersion;
		if (iridescence != null) data.iridescence = iridescence;
		if (iridescenceIOR != null) data.iridescenceIOR = iridescenceIOR;
		if (iridescenceThicknessRange != null) data.iridescenceThicknessRange = iridescenceThicknessRange;
		if (iridescenceMap != null && iridescenceMap.isTexture) {
			data.iridescenceMap = iridescenceMap.toJSON(meta).uuid;
		}
		if (iridescenceThicknessMap != null && iridescenceThicknessMap.isTexture) {
			data.iridescenceThicknessMap = iridescenceThicknessMap.toJSON(meta).uuid;
		}
		if (anisotropy != null) data.anisotropy = anisotropy;
		if (anisotropyRotation != null) data.anisotropyRotation = anisotropyRotation;
		if (anisotropyMap != null && anisotropyMap.isTexture) {
			data.anisotropyMap = anisotropyMap.toJSON(meta).uuid;
		}
		if (map != null && map.isTexture) data.map = map.toJSON(meta).uuid;
		if (matcap != null && matcap.isTexture) data.matcap = matcap.toJSON(meta).uuid;
		if (alphaMap != null && alphaMap.isTexture) data.alphaMap = alphaMap.toJSON(meta).uuid;
		if (lightMap != null && lightMap.isTexture) {
			data.lightMap = lightMap.toJSON(meta).uuid;
			data.lightMapIntensity = lightMapIntensity;
		}
		if (aoMap != null && aoMap.isTexture) {
			data.aoMap = aoMap.toJSON(meta).uuid;
			data.aoMapIntensity = aoMapIntensity;
		}
		if (bumpMap != null && bumpMap.isTexture) {
			data.bumpMap = bumpMap.toJSON(meta).uuid;
			data.bumpScale = bumpScale;
		}
		if (normalMap != null && normalMap.isTexture) {
			data.normalMap = normalMap.toJSON(meta).uuid;
			data.normalMapType = normalMapType;
			data.normalScale = normalScale.toArray();
		}
		if (displacementMap != null && displacementMap.isTexture) {
			data.displacementMap = displacementMap.toJSON(meta).uuid;
			data.displacementScale = displacementScale;
			data.displacementBias = displacementBias;
		}
		if (roughnessMap != null && roughnessMap.isTexture) data.roughnessMap = roughnessMap.toJSON(meta).uuid;
		if (metalnessMap != null && metalnessMap.isTexture) data.metalnessMap = metalnessMap.toJSON(meta).uuid;
		if (emissiveMap != null && emissiveMap.isTexture) data.emissiveMap = emissiveMap.toJSON(meta).uuid;
		if (specularMap != null && specularMap.isTexture) data.specularMap = specularMap.toJSON(meta).uuid;
		if (specularIntensityMap != null && specularIntensityMap.isTexture) data.specularIntensityMap = specularIntensityMap.toJSON(meta).uuid;
		if (specularColorMap != null && specularColorMap.isTexture) data.specularColorMap = specularColorMap.toJSON(meta).uuid;
		if (envMap != null && envMap.isTexture) {
			data.envMap = envMap.toJSON(meta).uuid;
			if (combine != null) data.combine = combine;
		}
		if (envMapRotation != null) data.envMapRotation = envMapRotation.toArray();
		if (envMapIntensity != null) data.envMapIntensity = envMapIntensity;
		if (reflectivity != null) data.reflectivity = reflectivity;
		if (refractionRatio != null) data.refractionRatio = refractionRatio;
		if (gradientMap != null && gradientMap.isTexture) {
			data.gradientMap = gradientMap.toJSON(meta).uuid;
		}
		if (transmission != null) data.transmission = transmission;
		if (transmissionMap != null && transmissionMap.isTexture) data.transmissionMap = transmissionMap.toJSON(meta).uuid;
		if (thickness != null) data.thickness = thickness;
		if (thicknessMap != null && thicknessMap.isTexture) data.thicknessMap = thicknessMap.toJSON(meta).uuid;
		if (attenuationDistance != null && attenuationDistance != Infinity) data.attenuationDistance = attenuationDistance;
		if (attenuationColor != null) data.attenuationColor = attenuationColor.getHex();
		if (size != null) data.size = size;
		if (shadowSide != null) data.shadowSide = shadowSide;
		if (sizeAttenuation != null) data.sizeAttenuation = sizeAttenuation;
		if (blending != Constants.NormalBlending) data.blending = blending;
		if (side != Constants.FrontSide) data.side = side;
		if (vertexColors == true) data.vertexColors = true;
		if (opacity < 1) data.opacity = opacity;
		if (transparent == true) data.transparent = true;
		if (blendSrc != Constants.SrcAlphaFactor) data.blendSrc = blendSrc;
		if (blendDst != Constants.OneMinusSrcAlphaFactor) data.blendDst = blendDst;
		if (blendEquation != Constants.AddEquation) data.blendEquation = blendEquation;
		if (blendSrcAlpha != null) data.blendSrcAlpha = blendSrcAlpha;
		if (blendDstAlpha != null) data.blendDstAlpha = blendDstAlpha;
		if (blendEquationAlpha != null) data.blendEquationAlpha = blendEquationAlpha;
		if (blendColor != null && blendColor.isColor) data.blendColor = blendColor.getHex();
		if (blendAlpha != 0) data.blendAlpha = blendAlpha;
		if (depthFunc != Constants.LessEqualDepth) data.depthFunc = depthFunc;
		if (depthTest == false) data.depthTest = depthTest;
		if (depthWrite == false) data.depthWrite = depthWrite;
		if (colorWrite == false) data.colorWrite = colorWrite;
		if (stencilWriteMask != 0xff) data.stencilWriteMask = stencilWriteMask;
		if (stencilFunc != Constants.AlwaysStencilFunc) data.stencilFunc = stencilFunc;
		if (stencilRef != 0) data.stencilRef = stencilRef;
		if (stencilFuncMask != 0xff) data.stencilFuncMask = stencilFuncMask;
		if (stencilFail != Constants.KeepStencilOp) data.stencilFail = stencilFail;
		if (stencilZFail != Constants.KeepStencilOp) data.stencilZFail = stencilZFail;
		if (stencilZPass != Constants.KeepStencilOp) data.stencilZPass = stencilZPass;
		if (stencilWrite == true) data.stencilWrite = stencilWrite;
		if (rotation != null && rotation != 0) data.rotation = rotation;
		if (polygonOffset == true) data.polygonOffset = true;
		if (polygonOffsetFactor != 0) data.polygonOffsetFactor = polygonOffsetFactor;
		if (polygonOffsetUnits != 0) data.polygonOffsetUnits = polygonOffsetUnits;
		if (linewidth != null && linewidth != 1) data.linewidth = linewidth;
		if (dashSize != null) data.dashSize = dashSize;
		if (gapSize != null) data.gapSize = gapSize;
		if (scale != null) data.scale = scale;
		if (dithering == true) data.dithering = true;
		if (alphaTest > 0) data.alphaTest = alphaTest;
		if (alphaHash == true) data.alphaHash = true;
		if (alphaToCoverage == true) data.alphaToCoverage = true;
		if (premultipliedAlpha == true) data.premultipliedAlpha = true;
		if (forceSinglePass == true) data.forceSinglePass = true;
		if (wireframe == true) data.wireframe = true;
		if (wireframeLinewidth > 1) data.wireframeLinewidth = wireframeLinewidth;
		if (wireframeLinecap != "round") data.wireframeLinecap = wireframeLinecap;
		if (wireframeLinejoin != "round") data.wireframeLinejoin = wireframeLinejoin;
		if (flatShading == true) data.flatShading = true;
		if (visible == false) data.visible = false;
		if (toneMapped == false) data.toneMapped = false;
		if (fog == false) data.fog = false;
		if (Reflect.field(userData, "length") > 0) data.userData = userData;
		function extractFromCache(cache:Dynamic):Array<Dynamic> {
			var values:Array<Dynamic> = [];
			for (key in cache) {
				var data = cache[key];
				Reflect.deleteField(data, "metadata");
				values.push(data);
			}
			return values;
		}
		if (isRootObject) {
			var textures = extractFromCache(meta.textures);
			var images = extractFromCache(meta.images);
			if (textures.length > 0) data.textures = textures;
			if (images.length > 0) data.images = images;
		}
		return data;
	}

	public function clone():Material {
		return new Material().copy(this);
	}

	public function copy(source:Material):Material {
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
		var srcPlanes = source.clippingPlanes;
		var dstPlanes:Null<Array<Dynamic>> = null;
		if (srcPlanes != null) {
			var n = srcPlanes.length;
			dstPlanes = new Array(n);
			for (var i = 0; i != n; ++i) {
				dstPlanes[i] = srcPlanes[i].clone();
			}
		}
		clippingPlanes = dstPlanes;
		clipIntersection = source.clipIntersection;
		clipShadows = source.clipShadows;
		shadowSide = source.shadowSide;
		colorWrite = source.colorWrite;
		precision = source.precision;
		polygonOffset = source.polygonOffset;
		polygonOffsetFactor = source.polygonOffsetFactor;
		polygonOffsetUnits = source.polygonOffsetUnits;
		dithering = source.dithering;
		alphaTest = source.alphaTest;
		alphaHash = source.alphaHash;
		alphaToCoverage = source.alphaToCoverage;
		premultipliedAlpha = source.premultipliedAlpha;
		forceSinglePass = source.forceSinglePass;
		visible = source.visible;
		toneMapped = source.toneMapped;
		userData = Reflect.copy(source.userData);
		return this;
	}

	public function dispose():Void {
		dispatchEvent({type: "dispose"});
	}

	public function set needsUpdate(value:Bool) {
		if (value == true) version++;
	}

	static var _materialId:Int = 0;
}