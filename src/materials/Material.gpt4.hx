package three;

import three.math.Color;
import three.core.EventDispatcher;
import three.constants.Blending;
import three.constants.Side;
import three.constants.DepthFunc;
import three.constants.StencilFunc;
import three.constants.StencilOp;
import three.math.MathUtils;

class Material extends EventDispatcher {

  public var isMaterial:Bool = true;

  public var id:Int;

  public var uuid:String;

  public var name:String;

  public var type:String;

  public var blending:Blending;

  public var side:Side;

  public var vertexColors:Bool;

  public var opacity:Float;

  public var transparent:Bool;

  public var alphaHash:Bool;

  public var blendSrc:Blending;

  public var blendDst:Blending;

  public var blendEquation:Blending;

  public var blendSrcAlpha:Null<Blending>;

  public var blendDstAlpha:Null<Blending>;

  public var blendEquationAlpha:Null<Blending>;

  public var blendColor:Color;

  public var blendAlpha:Float;

  public var depthFunc:DepthFunc;

  public var depthTest:Bool;

  public var depthWrite:Bool;

  public var stencilWriteMask:Int;

  public var stencilFunc:StencilFunc;

  public var stencilRef:Int;

  public var stencilFuncMask:Int;

  public var stencilFail:StencilOp;

  public var stencilZFail:StencilOp;

  public var stencilZPass:StencilOp;

  public var stencilWrite:Bool;

  public var clippingPlanes:Null<Array<Plane>>;

  public var clipIntersection:Bool;

  public var clipShadows:Bool;

  public var shadowSide:Null<Side>;

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
    this.id = _materialId++;
    this.uuid = MathUtils.generateUUID();

    this.name = "";
    this.type = "Material";

    this.blending = Blending.NormalBlending;
    this.side = Side.FrontSide;
    this.vertexColors = false;

    this.opacity = 1;
    this.transparent = false;
    this.alphaHash = false;

    this.blendSrc = Blending.SrcAlphaFactor;
    this.blendDst = Blending.OneMinusSrcAlphaFactor;
    this.blendEquation = Blending.AddEquation;
    this.blendSrcAlpha = null;
    this.blendDstAlpha = null;
    this.blendEquationAlpha = null;
    this.blendColor = new Color(0, 0, 0);
    this.blendAlpha = 0;

    this.depthFunc = DepthFunc.LessEqualDepth;
    this.depthTest = true;
    this.depthWrite = true;

    this.stencilWriteMask = 0xff;
    this.stencilFunc = StencilFunc.AlwaysStencilFunc;
    this.stencilRef = 0;
    this.stencilFuncMask = 0xff;
    this.stencilFail = StencilOp.KeepStencilOp;
    this.stencilZFail = StencilOp.KeepStencilOp;
    this.stencilZPass = StencilOp.KeepStencilOp;
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

  public var alphaTest(get, set):Float;

  public function get_alphaTest():Float {
    return _alphaTest;
  }

  public function set_alphaTest(value:Float):Float {
    if (_alphaTest > 0 != value > 0) {
      this.version++;
    }
    _alphaTest = value;
    return value;
  }

  public function onBuild(shaderobject:Dynamic, renderer:Dynamic):Void {
  }

  public function onBeforeRender(renderer:Dynamic, scene:Dynamic, camera:Dynamic, geometry:Dynamic, object:Dynamic, group:Dynamic):Void {
  }

  public function onBeforeCompile(shaderobject:Dynamic, renderer:Dynamic):Void {
  }

  public function customProgramCacheKey():String {
    return this.onBeforeCompile.toString();
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
      if (currentValue != null && Reflect.isFunction(currentValue.isColor)) {
        currentValue.set(newValue);
      } else if ((currentValue != null && Reflect.isFunction(currentValue.isVector3)) && (newValue != null && Reflect.isFunction(newValue.isVector3))) {
        currentValue.copy(newValue);
      } else {
        this[key] = newValue;
      }
    }
  }

  public function toJSON(meta:Dynamic):Dynamic {
    var isRootObject = (meta == null || Std.is(meta, String));
    if (isRootObject) {
      meta = {
        "textures": {},
        "images": {}
      };
    }
    var data = {
      "metadata": {
        "version": 4.6,
        "type": "Material",
        "generator": "Material.toJSON"
      }
    };
    data.uuid = this.uuid;
    data.type = this.type;
    if (this.name != "") data.name = this.name;
    if (this.color != null && Reflect.isFunction(this.color.isColor)) data.color = this.color.getHex();
    if (this.roughness != null) data.roughness = this.roughness;
    if (this.metalness != null) data.metalness = this.metalness;
    if (this.sheen != null) data.sheen = this.sheen;
    if (this.sheenColor != null && Reflect.isFunction(this.sheenColor.isColor)) data.sheenColor = this.sheenColor.getHex();
    if (this.sheenRoughness != null) data.sheenRoughness = this.sheenRoughness;
    if (this.emissive != null && Reflect.isFunction(this.emissive.isColor)) data.emissive = this.emissive.getHex();
    if (this.emissiveIntensity != null && this.emissiveIntensity != 1) data.emissiveIntensity = this.emissiveIntensity;
    if (this.specular != null && Reflect.isFunction(this.specular.isColor)) data.specular = this.specular.getHex();
    if (this.specularIntensity != null) data.specularIntensity = this.specularIntensity;
    if (this.specularColor != null && Reflect.isFunction(this.specularColor.isColor)) data.specularColor = this.specularColor.getHex();
    if (this.shininess != null) data.shininess = this.shininess;
    if (this.clearcoat != null) data.clearcoat = this.clearcoat;
    if (this.clearcoatRoughness != null) data.clearcoatRoughness = this.clearcoatRoughness;
    if (this.clearcoatMap != null && Reflect.isFunction(this.clearcoatMap.isTexture)) {
      data.clearcoatMap = this.clearcoatMap.toJSON(meta).uuid;
    }
    if (this.clearcoatRoughnessMap != null && Reflect.isFunction(this.clearcoatRoughnessMap.isTexture)) {
      data.clearcoatRoughnessMap = this.clearcoatRoughnessMap.toJSON(meta).uuid;
    }
    if (this.clearcoatNormalMap != null && Reflect.isFunction(this.clearcoatNormalMap.isTexture)) {
      data.clearcoatNormalMap = this.clearcoatNormalMap.toJSON(meta).uuid;
      data.clearcoatNormalScale = this.clearcoatNormalScale.toArray();
    }
    if (this.dispersion != null) data.dispersion = this.dispersion;
    if (this.iridescence != null) data.iridescence = this.iridescence;
    if (this.iridescenceIOR != null) data.iridescenceIOR = this.iridescenceIOR;
    if (this.iridescenceThicknessRange != null) data.iridescenceThicknessRange = this.iridescenceThicknessRange;
    if (this.iridescenceMap != null && Reflect.isFunction(this.iridescenceMap.isTexture)) {
      data.iridescenceMap = this.iridescenceMap.toJSON(meta).uuid;
    }
    if (this.iridescenceThicknessMap != null && Reflect.isFunction(this.iridescenceThicknessMap.isTexture)) {
      data.iridescenceThicknessMap = this.iridescenceThicknessMap.toJSON(meta).uuid;
    }
    if (this.anisotropy != null) data.anisotropy = this.anisotropy;
    if (this.anisotropyRotation != null) data.anisotropyRotation = this.anisotropyRotation;
    if (this.anisotropyMap != null && Reflect.isFunction(this.anisotropyMap.isTexture)) {
      data.anisotropyMap = this.anisotropyMap.toJSON(meta).uuid;
    }
    if (this.map != null && Reflect.isFunction(this.map.isTexture)) data.map = this.map.toJSON(meta).uuid;
    if (this.matcap != null && Reflect.isFunction(this.matcap.isTexture)) data.matcap = this.matcap.toJSON(meta).uuid;
    if (this.alphaMap != null && Reflect.isFunction(this.alphaMap.isTexture)) data.alphaMap = this.alphaMap.toJSON(meta).uuid;
    if (this.lightMap != null && Reflect.isFunction(this.lightMap.isTexture)) {
      data.lightMap = this.lightMap.toJSON(meta).uuid;
      data.lightMapIntensity = this.lightMapIntensity;
    }
    if (this.aoMap != null && Reflect.isFunction(this.aoMap.isTexture)) {
      data.aoMap = this.aoMap.toJSON(meta).uuid;
      data.aoMapIntensity = this.aoMapIntensity;
    }
    if (this.bumpMap != null && Reflect.isFunction(this.bumpMap.isTexture)) {
      data.bumpMap = this.bumpMap.toJSON(meta).uuid;
      data.bumpScale = this.bumpScale;
    }
    if (this.normalMap != null && Reflect.isFunction(this.normalMap.isTexture)) {
      data.normalMap = this.normalMap.toJSON(meta).uuid;
      data.normalMapType = this.normalMapType;
      data.normalScale = this.normalScale.toArray();
    }
    if (this.displacementMap != null && Reflect.isFunction(this.displacementMap.isTexture)) {
      data.displacementMap = this.displacementMap.toJSON(meta).uuid;
      data.displacementScale = this.displacementScale;
      data.displacementBias = this.displacementBias;
    }
    if (this.roughnessMap != null && Reflect.isFunction(this.roughnessMap.isTexture)) data.roughnessMap = this.roughnessMap.toJSON(meta).uuid;
    if (this.metalnessMap != null && Reflect.isFunction(this.metalnessMap.isTexture)) data.metalnessMap = this.metalnessMap.toJSON(meta).uuid;
    if (this.emissiveMap != null && Reflect.isFunction(this.emissiveMap.isTexture)) data.emissiveMap = this.emissiveMap.toJSON(meta).uuid;
    if (this.specularMap != null && Reflect.isFunction(this.specularMap.isTexture)) data.specularMap = this.specularMap.toJSON(meta).uuid;
    if (this.specularIntensityMap != null && Reflect.isFunction(this.specularIntensityMap.isTexture)) data.specularIntensityMap = this.specularIntensityMap.toJSON(meta).uuid;
    if (this.specularColorMap != null && Reflect.isFunction(this.specularColorMap.isTexture)) data.specularColorMap = this.specularColorMap.toJSON(meta).uuid;
    if (this.envMap != null && Reflect.isFunction(this.envMap.isTexture)) {
      data.envMap = this.envMap.toJSON(meta).uuid;
      if (this.combine != null) data.combine = this.combine;
    }
    if (this.envMapRotation != null) data.envMapRotation = this.envMapRotation.toArray();
    if (this.envMapIntensity != null) data.envMapIntensity = this.envMapIntensity;
    if (this.reflectivity != null) data.reflectivity = this.reflectivity;
    if (this.refractionRatio != null) data.refractionRatio = this.refractionRatio;
    if (this.gradientMap != null && Reflect.isFunction(this.gradientMap.isTexture)) {
      data.gradientMap = this.gradientMap.toJSON(meta).uuid;
    }
    if (this.transmission != null) data.transmission = this.transmission;
    if (this.transmissionMap != null && Reflect.isFunction(this.transmissionMap.isTexture)) data.transmissionMap = this.transmissionMap.toJSON(meta).uuid;
    if (this.thickness != null) data.thickness = this.thickness;
    if (this.thicknessMap != null && Reflect.isFunction(this.thicknessMap.isTexture)) data.thicknessMap = this.thicknessMap.toJSON(meta).uuid;
    if (this.attenuationDistance != null && this.attenuationDistance != Math.POSITIVE_INFINITY) data.attenuationDistance = this.attenuationDistance;
    if (this.attenuationColor != null) data.attenuationColor = this.attenuationColor.getHex();
    if (this.size != null) data.size = this.size;
    if (this.shadowSide != null) data.shadowSide = this.shadowSide;
    if (this.sizeAttenuation != null) data.sizeAttenuation = this.sizeAttenuation;
    if (this.blending != Blending.NormalBlending) data.blending = this.blending;
    if (this.side != Side.FrontSide) data.side = this.side;
    if (this.vertexColors == true) data.vertexColors = true;
    if (this.opacity < 1) data.opacity = this.opacity;
    if (this.transparent == true) data.transparent = true;
    if (this.blendSrc != Blending.SrcAlphaFactor) data.blendSrc = this.blendSrc;
    if (this.blendDst != Blending.OneMinusSrcAlphaFactor) data.blendDst = this.blendDst;
    if (this.blendEquation != Blending.AddEquation) data.blendEquation = this.blendEquation;
    if (this.blendSrcAlpha != null) data.blendSrcAlpha = this.blendSrcAlpha;
    if (this.blendDstAlpha != null) data.blendDstAlpha = this.blendDstAlpha;
    if (this.blendEquationAlpha != null) data.blendEquationAlpha = this.blendEquationAlpha;
    if (this.blendColor != null && Reflect.isFunction(this.blendColor.isColor)) data.blendColor = this.blendColor.getHex();
    if (this.blendAlpha != 0) data.blendAlpha = this.blendAlpha;
    if (this.depthFunc != DepthFunc.LessEqualDepth) data.depthFunc = this.depthFunc;
    if (this.depthTest == false) data.depthTest = this.depthTest;
    if (this.depthWrite == false) data.depthWrite = this.depthWrite;
    if (this.colorWrite == false) data.colorWrite = this.colorWrite;
    if (this.stencilWriteMask != 0xff) data.stencilWriteMask = this.stencilWriteMask;
    if (this.stencilFunc != StencilFunc.AlwaysStencilFunc) data.stencilFunc = this.stencilFunc;
    if (this.stencilRef != 0) data.stencilRef = this.stencilRef;
    if (this.stencilFuncMask != 0xff) data.stencilFuncMask = this.stencilFuncMask;
    if (this.stencilFail != StencilOp.KeepStencilOp) data.stencilFail = this.stencilFail;
    if (this.stencilZFail != StencilOp.KeepStencilOp) data.stencilZFail = this.stencilZFail;
    if (this.stencilZPass != StencilOp.KeepStencilOp) data.stencilZPass = this.stencilZPass;
    if (this.stencilWrite == true) data.stencilWrite = this.stencilWrite;
    if (this.rotation != null && this.rotation != 0) data.rotation = this.rotation;
    if (this.polygonOffset == true) data.polygonOffset = true;
    if (this.polygonOffsetFactor != 0) data.polygonOffsetFactor = this.polygonOffsetFactor;
    if (this.polygonOffsetUnits != 0) data.polygonOffsetUnits = this.polygonOffsetUnits;
    if (this.linewidth != null && this.linewidth != 1) data.linewidth = this.linewidth;
    if (this.dashSize != null) data.dashSize = this.dashSize;
    if (this.gapSize != null) data.gapSize = this.gapSize;
    if (this.scale != null) data.scale = this.scale;
    if (this.dithering == true) data.dithering = true;
    if (this.alphaTest > 0) data.alphaTest = this.alphaTest;
    if (this.alphaHash == true) data.alphaHash = true;
    if (this.alphaToCoverage == true) data.alphaToCoverage = true;
    if (this.premultipliedAlpha == true) data.premultipliedAlpha = true;
    if (this.forceSinglePass == true) data.forceSinglePass = true;
    if (this.wireframe == true) data.wireframe = true;
    if (this.wireframeLinewidth > 1) data.wireframeLinewidth = this.wireframeLinewidth;
    if (this.wireframeLinecap != "round") data.wireframeLinecap = this.wireframeLinecap;
    if (this.wireframeLinejoin != "round") data.wireframeLinejoin = this.wireframeLinejoin;
    if (this.flatShading == true) data.flatShading = true;
    if (this.visible == false) data.visible = false;
    if (this.toneMapped == false) data.toneMapped = false;
    if (this.fog == false) data.fog = false;
    if (Reflect.field(this.userData, "length") > 0) data.userData = this.userData;
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
    return cast(new this.constructor(), Material).copy(this);
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
    var dstPlanes:Null<Array<Plane>> = null;
    if (srcPlanes != null) {
      var n = srcPlanes.length;
      dstPlanes = new Array<Plane>(n);
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
    this.userData = js.Json.stringify(source.userData);
    return this;
  }

  public function dispose():Void {
    this.dispatchEvent({ "type": "dispose" });
  }

  public var needsUpdate(get, set):Bool;

  public function get_needsUpdate():Bool {
    return this.version > 0;
  }

  public function set_needsUpdate(value:Bool):Bool {
    if (value == true) this.version++;
    return value;
  }

}

private var _materialId:Int = 0;