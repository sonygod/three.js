import three.math.Color;
import three.core.EventDispatcher;
import three.constants.*;
import three.math.MathUtils;

class Material extends EventDispatcher {

	public var isMaterial:Bool = true;
	public var id:Int;
	public var uuid:String;
	public var name:String = "";
	public var type:String = "Material";

	public var blending:Int = NormalBlending;
	public var side:Int = FrontSide;
	public var vertexColors:Bool = false;

	public var opacity:Float = 1;
	public var transparent:Bool = false;
	public var alphaHash:Bool = false;

	public var blendSrc:Int = SrcAlphaFactor;
	public var blendDst:Int = OneMinusSrcAlphaFactor;
	public var blendEquation:Int = AddEquation;
	public var blendSrcAlpha:Int = null;
	public var blendDstAlpha:Int = null;
	public var blendEquationAlpha:Int = null;
	public var blendColor:Color = new Color(0, 0, 0);
	public var blendAlpha:Float = 0;

	public var depthFunc:Int = LessEqualDepth;
	public var depthTest:Bool = true;
	public var depthWrite:Bool = true;

	public var stencilWriteMask:Int = 0xff;
	public var stencilFunc:Int = AlwaysStencilFunc;
	public var stencilRef:Int = 0;
	public var stencilFuncMask:Int = 0xff;
	public var stencilFail:Int = KeepStencilOp;
	public var stencilZFail:Int = KeepStencilOp;
	public var stencilZPass:Int = KeepStencilOp;
	public var stencilWrite:Bool = false;

	public var clippingPlanes:Array<Dynamic> = null;
	public var clipIntersection:Bool = false;
	public var clipShadows:Bool = false;

	public var shadowSide:Int = null;

	public var colorWrite:Bool = true;

	public var precision:String = null; // override the renderer's default precision for this material

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

	public function onBuild(shaderobject:Dynamic, renderer:Dynamic):Void {
	}

	public function onBeforeRender(renderer:Dynamic, scene:Dynamic, camera:Dynamic, geometry:Dynamic, object:Dynamic, group:Dynamic):Void {
	}

	public function onBeforeCompile(shaderobject:Dynamic, renderer:Dynamic):Void {
	}

	public function customProgramCacheKey():String {
		return onBeforeCompile.toString();
	}

	public function setValues(values:Dynamic) {
		if (values == null) {
			return;
		}

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

			if (currentValue != null && Std.is(currentValue, Color)) {
				cast(currentValue, Color).set(newValue);
			} else if (currentValue != null && Std.is(currentValue, Vector3) && newValue != null && Std.is(newValue, Vector3)) {
				cast(currentValue, Vector3).copy(newValue);
			} else {
				this[key] = newValue;
			}
		}
	}

	public function toJSON(meta:Dynamic = null):Dynamic {
		var isRootObject = (meta == null || Std.is(meta, String));
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
			data.normalMap = normalMap.toJSON(meta).uuid;
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
		if (attenuationDistance != null && attenuationDistance != Math.POSITIVE_INFINITY) data.attenuationDistance = attenuationDistance;
		if (attenuationColor != null) data.attenuationColor = attenuationColor.getHex();

		if (size != null) data.size = size;
		if (shadowSide != null) data.shadowSide = shadowSide;
		if (sizeAttenuation != null) data.sizeAttenuation = sizeAttenuation;

		if (blending != NormalBlending) data.blending = blending;
		if (side != FrontSide) data.side = side;
		if (vertexColors == true) data.vertexColors = true;

		if (opacity < 1) data.opacity = opacity;
		if (transparent == true) data.transparent = true;

		if (blendSrc != SrcAlphaFactor) data.blendSrc = blendSrc;
		if (blendDst != OneMinusSrcAlphaFactor) data.blendDst = blendDst;
		if (blendEquation != AddEquation) data.blendEquation = blendEquation;
		if (blendSrcAlpha != null) data.blendSrcAlpha = blendSrcAlpha;
		if (blendDstAlpha != null) data.blendDstAlpha = blendDstAlpha;
		if (blendEquationAlpha != null) data.blendEquationAlpha = blendEquationAlpha;
		if (blendColor != null && Std.is(blendColor, Color)) data.blendColor = blendColor.getHex();
		if (blendAlpha != 0) data.blendAlpha = blendAlpha;

		if (depthFunc != LessEqualDepth) data.depthFunc = depthFunc;
		if (depthTest == false) data.depthTest = depthTest;
		if (depthWrite == false) data.depthWrite = depthWrite;
		if (colorWrite == false) data.colorWrite = colorWrite;

		if (stencilWriteMask != 0xff) data.stencilWriteMask = stencilWriteMask;
		if (stencilFunc != AlwaysStencilFunc) data.stencilFunc = stencilFunc;
		if (stencilRef != 0) data.stencilRef = stencilRef;
		if (stencilFuncMask != 0xff) data.stencilFuncMask = stencilFuncMask;
		if (stencilFail != KeepStencilOp) data.stencilFail = stencilFail;
		if (stencilZFail != KeepStencilOp) data.stencilZFail = stencilZFail;
		if (stencilZPass != KeepStencilOp) data.stencilZPass = stencilZPass;
		if (stencilWrite == true) data.stencilWrite = stencilWrite;

		// rotation (SpriteMaterial)
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

		// TODO: Copied from Object3D.toJSON

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
		var dstPlanes:Array<Dynamic> = null;
		if (srcPlanes != null) {
			var n = srcPlanes.length;
			dstPlanes = new Array(n);
			for (var i = 0; i < n; i++) {
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

		userData = Json.parse(Json.stringify(source.userData));

		return this;
	}

	public function dispose():Void {
		dispatchEvent({type: "dispose"});
	}

	public function set needsUpdate(value:Bool) {
		if (value) version++;
	}

	static var _materialId:Int = 0;
}