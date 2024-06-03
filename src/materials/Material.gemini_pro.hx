import three.math.Color;
import three.core.EventDispatcher;
import three.constants.Constants;
import three.math.MathUtils;

class Material extends EventDispatcher {

	public var isMaterial:Bool = true;

	public var id:Int;
	public var uuid:String;
	public var name:String;
	public var type:String = "Material";

	public var blending:Int = Constants.NormalBlending;
	public var side:Int = Constants.FrontSide;
	public var vertexColors:Bool = false;

	public var opacity:Float = 1;
	public var transparent:Bool = false;
	public var alphaHash:Bool = false;

	public var blendSrc:Int = Constants.SrcAlphaFactor;
	public var blendDst:Int = Constants.OneMinusSrcAlphaFactor;
	public var blendEquation:Int = Constants.AddEquation;
	public var blendSrcAlpha:Null<Int> = null;
	public var blendDstAlpha:Null<Int> = null;
	public var blendEquationAlpha:Null<Int> = null;
	public var blendColor:Color = new Color(0, 0, 0);
	public var blendAlpha:Float = 0;

	public var depthFunc:Int = Constants.LessEqualDepth;
	public var depthTest:Bool = true;
	public var depthWrite:Bool = true;

	public var stencilWriteMask:Int = 0xff;
	public var stencilFunc:Int = Constants.AlwaysStencilFunc;
	public var stencilRef:Int = 0;
	public var stencilFuncMask:Int = 0xff;
	public var stencilFail:Int = Constants.KeepStencilOp;
	public var stencilZFail:Int = Constants.KeepStencilOp;
	public var stencilZPass:Int = Constants.KeepStencilOp;
	public var stencilWrite:Bool = false;

	public var clippingPlanes:Null<Array<Dynamic>> = null;
	public var clipIntersection:Bool = false;
	public var clipShadows:Bool = false;

	public var shadowSide:Null<Int> = null;

	public var colorWrite:Bool = true;

	public var precision:Null<String> = null;

	public var polygonOffset:Bool = false;
	public var polygonOffsetFactor:Float = 0;
	public var polygonOffsetUnits:Float = 0;

	public var dithering:Bool = false;

	public var alphaToCoverage:Bool = false;
	public var premultipliedAlpha:Bool = false;
	public var forceSinglePass:Bool = false;

	public var visible:Bool = true;

	public var toneMapped:Bool = true;

	public var userData:Dynamic = {};

	public var version:Int = 0;

	private var _alphaTest:Float = 0;

	public function new() {
		super();
		id = _materialId++;
		uuid = MathUtils.generateUUID();
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

	public function onBuild(/* shaderobject:Dynamic, renderer:Dynamic */):Void { }

	public function onBeforeRender(/* renderer:Dynamic, scene:Dynamic, camera:Dynamic, geometry:Dynamic, object:Dynamic, group:Dynamic */):Void { }

	public function onBeforeCompile(/* shaderobject:Dynamic, renderer:Dynamic */):Void { }

	public function customProgramCacheKey():String {
		return onBeforeCompile.toString();
	}

	public function setValues(values:Dynamic) {
		if (values == null) return;
		for (key in values) {
			var newValue = values[key];
			if (newValue == null) {
				warn("THREE.Material: parameter '${key}' has value of undefined.");
				continue;
			}
			var currentValue = this[key];
			if (currentValue == null) {
				warn("THREE.Material: '${key}' is not a property of THREE.${type}.");
				continue;
			}
			if (currentValue != null && cast currentValue : Color) {
				currentValue.set(newValue);
			} else if (currentValue != null && cast currentValue : three.math.Vector3 && newValue != null && cast newValue : three.math.Vector3) {
				currentValue.copy(newValue);
			} else {
				this[key] = newValue;
			}
		}
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var isRootObject = meta == null || typeof meta == "String";
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
		if (color != null && cast color : Color) data.color = color.getHex();
		if (roughness != null) data.roughness = roughness;
		if (metalness != null) data.metalness = metalness;
		if (sheen != null) data.sheen = sheen;
		if (sheenColor != null && cast sheenColor : Color) data.sheenColor = sheenColor.getHex();
		if (sheenRoughness != null) data.sheenRoughness = sheenRoughness;
		if (emissive != null && cast emissive : Color) data.emissive = emissive.getHex();
		if (emissiveIntensity != null && emissiveIntensity != 1) data.emissiveIntensity = emissiveIntensity;
		if (specular != null && cast specular : Color) data.specular = specular.getHex();
		if (specularIntensity != null) data.specularIntensity = specularIntensity;
		if (specularColor != null && cast specularColor : Color) data.specularColor = specularColor.getHex();
		if (shininess != null) data.shininess = shininess;
		if (clearcoat != null) data.clearcoat = clearcoat;
		if (clearcoatRoughness != null) data.clearcoatRoughness = clearcoatRoughness;
		if (clearcoatMap != null && cast clearcoatMap : three.textures.Texture) data.clearcoatMap = clearcoatMap.toJSON(meta).uuid;
		if (clearcoatRoughnessMap != null && cast clearcoatRoughnessMap : three.textures.Texture) data.clearcoatRoughnessMap = clearcoatRoughnessMap.toJSON(meta).uuid;
		if (clearcoatNormalMap != null && cast clearcoatNormalMap : three.textures.Texture) {
			data.clearcoatNormalMap = clearcoatNormalMap.toJSON(meta).uuid;
			data.clearcoatNormalScale = clearcoatNormalScale.toArray();
		}
		if (dispersion != null) data.dispersion = dispersion;
		if (iridescence != null) data.iridescence = iridescence;
		if (iridescenceIOR != null) data.iridescenceIOR = iridescenceIOR;
		if (iridescenceThicknessRange != null) data.iridescenceThicknessRange = iridescenceThicknessRange;
		if (iridescenceMap != null && cast iridescenceMap : three.textures.Texture) data.iridescenceMap = iridescenceMap.toJSON(meta).uuid;
		if (iridescenceThicknessMap != null && cast iridescenceThicknessMap : three.textures.Texture) data.iridescenceThicknessMap = iridescenceThicknessMap.toJSON(meta).uuid;
		if (anisotropy != null) data.anisotropy = anisotropy;
		if (anisotropyRotation != null) data.anisotropyRotation = anisotropyRotation;
		if (anisotropyMap != null && cast anisotropyMap : three.textures.Texture) data.anisotropyMap = anisotropyMap.toJSON(meta).uuid;
		if (map != null && cast map : three.textures.Texture) data.map = map.toJSON(meta).uuid;
		if (matcap != null && cast matcap : three.textures.Texture) data.matcap = matcap.toJSON(meta).uuid;
		if (alphaMap != null && cast alphaMap : three.textures.Texture) data.alphaMap = alphaMap.toJSON(meta).uuid;
		if (lightMap != null && cast lightMap : three.textures.Texture) {
			data.lightMap = lightMap.toJSON(meta).uuid;
			data.lightMapIntensity = lightMapIntensity;
		}
		if (aoMap != null && cast aoMap : three.textures.Texture) {
			data.aoMap = aoMap.toJSON(meta).uuid;
			data.aoMapIntensity = aoMapIntensity;
		}
		if (bumpMap != null && cast bumpMap : three.textures.Texture) {
			data.bumpMap = bumpMap.toJSON(meta).uuid;
			data.bumpScale = bumpScale;
		}
		if (normalMap != null && cast normalMap : three.textures.Texture) {
			data.normalMap = normalMap.toJSON(meta).uuid;
			data.normalMapType = normalMapType;
			data.normalScale = normalScale.toArray();
		}
		if (displacementMap != null && cast displacementMap : three.textures.Texture) {
			data.displacementMap = displacementMap.toJSON(meta).uuid;
			data.displacementScale = displacementScale;
			data.displacementBias = displacementBias;
		}
		if (roughnessMap != null && cast roughnessMap : three.textures.Texture) data.roughnessMap = roughnessMap.toJSON(meta).uuid;
		if (metalnessMap != null && cast metalnessMap : three.textures.Texture) data.metalnessMap = metalnessMap.toJSON(meta).uuid;
		if (emissiveMap != null && cast emissiveMap : three.textures.Texture) data.emissiveMap = emissiveMap.toJSON(meta).uuid;
		if (specularMap != null && cast specularMap : three.textures.Texture) data.specularMap = specularMap.toJSON(meta).uuid;
		if (specularIntensityMap != null && cast specularIntensityMap : three.textures.Texture) data.specularIntensityMap = specularIntensityMap.toJSON(meta).uuid;
		if (specularColorMap != null && cast specularColorMap : three.textures.Texture) data.specularColorMap = specularColorMap.toJSON(meta).uuid;
		if (envMap != null && cast envMap : three.textures.Texture) {
			data.envMap = envMap.toJSON(meta).uuid;
			if (combine != null) data.combine = combine;
		}
		if (envMapRotation != null) data.envMapRotation = envMapRotation.toArray();
		if (envMapIntensity != null) data.envMapIntensity = envMapIntensity;
		if (reflectivity != null) data.reflectivity = reflectivity;
		if (refractionRatio != null) data.refractionRatio = refractionRatio;
		if (gradientMap != null && cast gradientMap : three.textures.Texture) data.gradientMap = gradientMap.toJSON(meta).uuid;
		if (transmission != null) data.transmission = transmission;
		if (transmissionMap != null && cast transmissionMap : three.textures.Texture) data.transmissionMap = transmissionMap.toJSON(meta).uuid;
		if (thickness != null) data.thickness = thickness;
		if (thicknessMap != null && cast thicknessMap : three.textures.Texture) data.thicknessMap = thicknessMap.toJSON(meta).uuid;
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
		if (blendColor != null && cast blendColor : Color) data.blendColor = blendColor.getHex();
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
		if (Reflect.hasField(userData, "")) data.userData = userData;
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
			var textures:Array<Dynamic> = extractFromCache(meta.textures);
			var images:Array<Dynamic> = extractFromCache(meta.images);
			if (textures.length > 0) data.textures = textures;
			if (images.length > 0) data.images = images;
		}
		return data;
	}

	public function clone():Material {
		return cast new this.constructor() : Material.copy(this);
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
			for (i in 0...n) {
				dstPlanes[i] = cast srcPlanes[i] : Dynamic.clone();
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

	static public var _materialId:Int = 0;
}