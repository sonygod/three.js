import haxe.Serializer;
import haxe.Unserializer;

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
	public var blendSrcAlpha:Int;
	public var blendDstAlpha:Int;
	public var blendEquationAlpha:Int;
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
	public var clippingPlanes:Array<Plane>;
	public var clipIntersection:Bool;
	public var clipShadows:Bool;
	public var shadowSide:Int;
	public var colorWrite:Bool;
	public var precision:Int;
	public var polygonOffset:Bool;
	public var polygonOffsetFactor:Float;
	public var polygonOffsetUnits:Float;
	public var dithering:Bool;
	public var alphaTest:Float;
	public var alphaToCoverage:Bool;
	public var premultipliedAlpha:Bool;
	public var forceSinglePass:Bool;
	public var visible:Bool;
	public var toneMapped:Bool;
	public var userData:Dynamic;
	public var version:Int;

	public function new() {
		super();
		isMaterial = true;
		id = _materialId++;
		uuid = MathUtils.generateUUID();
		name = "";
		type = "Material";
		blending = NormalBlending;
		side = FrontSide;
		vertexColors = false;
		opacity = 1.0;
		transparent = false;
		alphaHash = false;
		blendSrc = SrcAlphaFactor;
		blendDst = OneMinusSrcAlphaFactor;
		blendEquation = AddEquation;
		blendSrcAlpha = null;
		blendDstAlpha = null;
		blendEquationAlpha = null;
		blendColor = new Color(0, 0, 0);
		blendAlpha = 0.0;
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
		polygonOffsetFactor = 0.0;
		polygonOffsetUnits = 0.0;
		dithering = false;
		alphaTest = 0.0;
		alphaToCoverage = false;
		premultipliedAlpha = false;
		forceSinglePass = false;
		visible = true;
		toneMapped = true;
		userData = {};
		version = 0;
	}

	public function set alphaTest(value:Float) {
		if (alphaTest > 0 != value > 0) {
			version++;
		}
		alphaTest = value;
	}

	public function onBuild(shaderobject:ShaderObject, renderer:OpenFLRenderer) -> Void {

	}

	public function onBeforeRender(renderer:OpenFLRenderer, scene:Scene, camera:Camera, geometry:Geometry, object:DisplayObject, group:DisplayObject) -> Void {

	}

	public function onBeforeCompile(shaderobject:ShaderObject, renderer:OpenFLRenderer) -> Void {

	}

	public function customProgramCacheKey():String {
		return onBeforeCompile.toString();
	}

	public function setValues(values:Dynamic) -> Void {
		if (values == null) return;
		for (key in values) {
			var newValue = values[key];
			if (newValue == null) {
				trace("Material: parameter '" + key + "' has value of null.");
				continue;
			}
			var currentValue = this[key];
			if (currentValue == null) {
				trace("Material: '" + key + "' is not a property of " + type + ".");
				continue;
			}
			if (currentValue != null && Std.is(currentValue, Color)) {
				currentValue.set(newValue);
			} else if (currentValue != null && Std.is(currentValue, Vector3) && newValue != null && Std.is(newValue, Vector3)) {
				currentValue.copy(newValue);
			} else {
				this[key] = newValue;
			}
		}
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var isRootObject = (meta == null || typeof meta == "string");
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
		// standard Material serialization
		data.uuid = uuid;
		data.type = type;
		if (name != "") data.name = name;
		if (color != null && Std.is(color, Color)) data.color = color.getHex();
		if (roughness != null) data.roughness = roughness;
		if (metalness != null) data.metalness = metalness;
		if (sheen != null) data.sheen = sheen;
		if (sheenColor != null && Std.is(sheenColor, Color)) data.sheenColor = sheenColor.getHex();
		if (sheenRoughness != null) data.sheenRoughness = sheenRoughness;
		if (emissive != null && Std.is(emissive, Color)) data.emissive = emissive.getHex();
		if (emissiveIntensity != null && emissiveIntensity != 1) data.emissiveIntensity = emissiveIntensity;
		if (specular != null && Std.is(specular, Color)) data.specular = specular.getHex();
		if (specularIntensity != null) data.specularIntensity = specularIntensity;
		if (specularColor != null && Std.is(specularColor, Color)) data.specularColor = specularColor.getHex();
		if (shininess != null) data.shininess = shininess;
		if (clearcoat != null) data.clearcoat = clearcoat;
		if (clearcoatRoughness != null) data.clearcoatRoughness = clearcoatRoughness;
		if (clearcoatMap != null && Std.is(clearcoatMap, Texture)) {
			data.clearcoatMap = clearcoatMap.toJSON(meta).uuid;
		}
		if (clearcoatRoughnessMap != null && Std.is(clearcoatRoughnessMap, Texture)) {
			data.clearcoatRoughnessMap = clearcoatRoughnessMap.toJSON(meta).uuid;
		}
		if (clearcoatNormalMap != null && Std.is(clearcoatNormalMap, Texture)) {
			data.clearcoatNormalMap = clearcoatNormalMap.toJSON(meta).uuid;
			data.clearcoatNormalScale = clearcoatNormalScale.toArray();
		}
		if (dispersion != null) data.dispersion = dispersion;
		if (iridescence != null) data.iridescence = iridescence;
		if (iridescenceIOR != null) data.iridescenceIOR = iridescenceIOR;
		if (iridescenceThicknessRange != null) data.iridescenceThicknessRange = iridescenceThicknessRange;
		if (iridescenceMap != null && Std.is(iridescenceMap, Texture)) {
			data.iridescenceMap = iridescenceMap.toJSON(meta).uuid;
		}
		if (iridescenceThicknessMap != null && Std.is(iridescenceThicknessMap, Texture)) {
			data.iridescenceThicknessMap = iridescenceThicknessMap.toJSON(meta).uuid;
		}
		if (anisotropy != null) data.anisotropy = anisotropy;
		if (anisotropyRotation != null) data.anisotropyRotation = anisotropyRotation;
		if (anisotropyMap != null && Std.is(anisotropyMap, Texture)) {
			data.anisotropyMap = anisotropyMap.toJSON(meta).uuid;
		}
		if (map != null && Std.is(map, Texture)) data.map = map.toJSON(meta).uuid;
		if (matcap != null && Std.is(matcap, Texture)) data.matcap = matcap.toJSON(meta).uuid;
		if (alphaMap != null && Std.is(alphaMap, Texture)) data.alphaMap = alphaMap.toJSON(meta).uuid;
		if (lightMap != null && Std.is(lightMap, Texture)) {
			data.lightMap = lightMap.toJSON(meta).uuid;
			data.lightMapIntensity = lightMapIntensity;
		}
		if (aoMap != null && Std.is(aoMap, Texture)) {
			data.aoMap = aoMap.toJSON(meta).uuid;
			data.aoMapIntensity = aoMapIntensity;
		}
		if (bumpMap != null && Std.is(bumpMap, Texture)) {
			data.bumpMap = bumpMap.toJSON(meta).uuid;
			data.bumpScale = bumpScale;
		}
		if (normalMap != null && Std.is(normalMap, Texture)) {
			dataCoefficient = normalMap.toJSON(meta).uuid;
			data.normalMapType = normalMapType;
			data.normalScale = normalScale.toArray();
		}
		if (displacementMap != null && Std.is(displacementMap, Texture)) {
			data.displacementMap = displacementMap.toJSON(meta).uuid;
			data.displacementScale = displacementScale;
			data.displacementBias = displacementBias;
		}
		if (roughnessMap != null && Std.is(roughnessMap, Texture)) data.roughnessMap = roughnessMap.toJSON(meta).uuid;
		if (metalnessMap != null && Std.is(metalnessMap, Texture)) data.metalnessMap = metalnessMap.toJSON(meta).uuid;
		if (emissiveMap != null && Std.is(emissiveMap, Texture)) data.emissiveMap = emissiveMap.toJSON(meta).uuid;
		if (specularMap != null && Std.is(specularMap, Texture)) data.specularMap = specularMap.toJSON(meta).uuid;
		if (specularIntensityMap != null && Std.is(specularIntensityMap, Texture)) data.specularIntensityMap = specularIntensityMap.toJSON(meta).uuid;
		if (specularColorMap != null && Std.is(specularColorMap, Texture)) data.specularColorMap = specularColorMap.toJSON(meta).uuid;
		if (envMap != null && Std.is(envMap, Texture)) {
			data.envMap = envMap.toJSON(meta).uuid;
			if (combine != null) data.combine = combine;
		}
		if (envMapRotation != null) data.envMapRotation = envMapRotation.toArray();
		if (envMapIntensity != null) data.envMapIntensity = envMapIntensity;
		if (reflectivity != null) data.reflectivity = reflectivity;
		if (refractionRatio != null) data.refractionRatio = refractionRatio;
		if (gradientMap != null && Std.is(gradientMap, Texture)) {
			data.gradientMap = gradientMap.toJSON(meta).uuid;
		}
		if (transmission != null) data.transmission = transmission;
		if (transmissionMap != null && Std.is(transmissionMap, Texture)) data.transmissionMap = transmissionMap.toJSON(meta).uuid;
		if (thickness != null) data.thickness = thickness;
		if (thicknessMap != null && Std.is(thicknessMap, Texture)) data.thicknessMap = thicknessMap.toJSON(meta).uuid;
		if (attenuationDistance != null && attenuationDistance != Infinity) data.attenuationDistance = attenuationDistance;
		if (attenuationColor != null && Std.is(attenuationColor, Color)) data.attenuationColor = attenuationColor.getHex();
		if (size != null) data.size = size;
		if (shadowSide != null) data.shadowSide = shadowSide;
		if (sizeAttenuation != null) data.sizeAttenuation = sizeAttenuation;
		if (blending != NormalBlending) data.blending = blending;
		if (side != FrontSide) data.side = side;
		if (vertexColors) data.vertexColors = vertexColors;
		if (opacity < 1.0) data.opacity = opacity;
		if (transparent) data.transparent = transparent;
		if (blendSrc != SrcAlphaFactor) data.blendSrc = blendSrc;
		if (blendDst != OneMinusSrcAlphaFactor) data.blendDst = blendDst;
		if (blendEquation != AddEquation) data.blendEquation = blendEquation;
		if (blendSrcAlpha != null) data.blendSrcAlpha = blendSrcAlpha;
		if (blendDstAlpha != null) data.blendDstAlpha = blendDstAlpha;
		if (blendEquationAlpha != null) data.blendEquationAlpha = blendEquationAlpha;
		if (blendColor != null && Std.is(blendColor, Color)) data.blendColor = blendColor.getHex();
		if (blendAlpha != 0.0) data.blendAlpha = blendAlpha;
		if (depthFunc != LessEqualDepth) data.depthFunc = depthFunc;
		if (!depthTest) data.depthTest = depthTest;
		if (!depthWrite) data.depthWrite = depthWrite;
		if (!colorWrite) data.colorWrite = colorWrite;
		if (stencilWriteMask != 0xff) data.stencilWriteMask = stencilWriteMask;
		if (stencilFunc != AlwaysStencilFunc) data.stencilFunc = stencilFunc;
		if (stencilRef != 0) data.stencilRef = stencilRef;
		if (stencilFuncMask != 0xff) data.stencilFuncMask = stencilFuncMask;
		if (stencilFail != KeepStencilOp) data.stencilFail = stencilFail;
		if (stencilZFail != KeepStencilOp) data.stencilZFail = stencilZFail;
		if (stencilZPass != KeepStencilOp) data.stencilZPass = stencilZPass;
		if (stencilWrite) data.stencilWrite = stencilWrite;
		// rotation (SpriteMaterial)
		if (rotation != null && rotation != 0) data.rotation = rotation;
		if (polygonOffset) data.polygonOffset = polygonOffset;
		if (polygonOffsetFactor != 0.0) data.polygonOffsetFactor = polygonOffsetFactor;
		if (polygonOffsetUnits != 0.0) data.polygonOffsetUnits = polygonOffsetUnits;
		if (linewidth != null && linewidth != 1) data.linewidth = linewidth;
		if (dashSize != null) data.dashSize = dashSize;
		if (gapSize != null) data.gapSize = gapSize;
		if (scale != null) data.scale = scale;
		if (dithering) data.dithering = dithering;
		if (alphaTest > 0.0) data.alphaTest = alphaTest;
		if (alphaHash) data.alphaHash = alphaHash;
		if (alphaToCoverage) data.alphaToCoverage = alphaToCoverage;
		if (premultipliedAlpha) data.premultipliedAlpha = premultipliedAlpha;
		if (forceSinglePass) data.forceSinglePass = forceSinglePass;
		if (wireframe) data.wireframe = wireframe;
		if (wireframeLinewidth > 1) data.wireframeLinewidth = wireframeLinewidth;
		if (wireframeLinecap != "round") data.wireframeLinecap = wireframeLinecap;
		if (wireframeLinejoin != "round") data.wireframeLinejoin = wireframeLinejoin;
		if (flatShading) data.flatShading = flatShading;
		if (!visible) data.visible = visible;
		if (!toneMapped) data.toneMapped = toneMapped;
		if (!fog) data.fog = fog;
		if (Reflect.field(userData) != null
	if (Reflect.field(userData) != null) {
		data.userData = userData;
	}

	function extractFromCache(cache:Dynamic):Array<Dynamic> {
		var values = [];
		for (key in cache) {
			var data = cache[key];
			delete data.metadata;
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
	return new this.constructor().copy(this);
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
	var dstPlanes:Array<Plane> = null;
	if (srcPlanes != null) {
		var n = srcPlanes.length;
		dstPlanes = new Array(n);
		for (i = 0; i < n; i++) {
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
	userData = JSON.parse(JSON.stringify(source.userData));
	return this;
}

public function dispose():Void {
	dispatchEvent(new Event("dispose"));
}

public function set needsUpdate(value:Bool):Void {
	if (value) version++;
}

static var _materialId:Int = 0;

public static function get Material():Material {
	return cast(new Material());
}