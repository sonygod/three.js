import three.js.src.math.Color;
import three.js.src.core.EventDispatcher;
import three.js.src.constants.FrontSide;
import three.js.src.constants.NormalBlending;
import three.js.src.constants.LessEqualDepth;
import three.js.src.constants.AddEquation;
import three.js.src.constants.OneMinusSrcAlphaFactor;
import three.js.src.constants.SrcAlphaFactor;
import three.js.src.constants.AlwaysStencilFunc;
import three.js.src.constants.KeepStencilOp;
import three.js.src.math.MathUtils;

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
    public var clippingPlanes:Null<Array<Dynamic>>;
    public var clipIntersection:Bool;
    public var clipShadows:Bool;
    public var shadowSide:Null<Int>;
    public var colorWrite:Bool;
    public var precision:Null<Int>;
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

    public function get alphaTest():Float {
        return _alphaTest;
    }

    public function set alphaTest(value:Float) {
        if (_alphaTest > 0 !== value > 0) {
            version++;
        }
        _alphaTest = value;
    }

    public function onBuild(shaderobject:Dynamic, renderer:Dynamic) {}
    public function onBeforeRender(renderer:Dynamic, scene:Dynamic, camera:Dynamic, geometry:Dynamic, object:Dynamic, group:Dynamic) {}
    public function onBeforeCompile(shaderobject:Dynamic, renderer:Dynamic) {}
    public function customProgramCacheKey():String {
        return onBeforeCompile.toString();
    }

    public function setValues(values:Dynamic) {
        if (values === undefined) return;
        for (key in values) {
            var newValue = values[key];
            if (newValue === undefined) {
                trace('THREE.Material: parameter \'' + key + '\' has value of undefined.');
                continue;
            }
            var currentValue = this[key];
            if (currentValue === undefined) {
                trace('THREE.Material: \'' + key + '\' is not a property of THREE.' + this.type + '.');
                continue;
            }
            if (currentValue && currentValue.isColor) {
                currentValue.set(newValue);
            } else if ((currentValue && currentValue.isVector3) && (newValue && newValue.isVector3)) {
                currentValue.copy(newValue);
            } else {
                this[key] = newValue;
            }
        }
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var isRootObject = (meta === undefined || typeof(meta) === 'String');
        if (isRootObject) {
            meta = {
                textures: {},
                images: {}
            };
        }
        var data = {
            metadata: {
                version: 4.6,
                type: 'Material',
                generator: 'Material.toJSON'
            }
        };
        // standard Material serialization
        data.uuid = this.uuid;
        data.type = this.type;
        if (this.name !== '') data.name = this.name;
        if (this.color && this.color.isColor) data.color = this.color.getHex();
        if (this.roughness !== undefined) data.roughness = this.roughness;
        if (this.metalness !== undefined) data.metalness = this.metalness;
        if (this.sheen !== undefined) data.sheen = this.sheen;
        if (this.sheenColor && this.sheenColor.isColor) data.sheenColor = this.sheenColor.getHex();
        if (this.sheenRoughness !== undefined) data.sheenRoughness = this.sheenRoughness;
        if (this.emissive && this.emissive.isColor) data.emissive = this.emissive.getHex();
        if (this.emissiveIntensity !== undefined && this.emissiveIntensity !== 1) data.emissiveIntensity = this.emissiveIntensity;
        if (this.specular && this.specular.isColor) data.specular = this.specular.getHex();
        if (this.specularIntensity !== undefined) data.specularIntensity = this.specularIntensity;
        if (this.specularColor && this.specularColor.isColor) data.specularColor = this.specularColor.getHex();
        if (this.shininess !== undefined) data.shininess = this.shininess;
        if (this.clearcoat !== undefined) data.clearcoat = this.clearcoat;
        if (this.clearcoatRoughness !== undefined) data.clearcoatRoughness = this.clearcoatRoughness;
        if (this.clearcoatMap && this.clearcoatMap.isTexture) {
            data.clearcoatMap = this.clearcoatMap.toJSON(meta).uuid;
        }
        if (this.clearcoatRoughnessMap && this.clearcoatRoughnessMap.isTexture) {
            data.clearcoatRoughnessMap = this.clearcoatRoughnessMap.toJSON(meta).uuid;
        }
        if (this.clearcoatNormalMap && this.clearcoatNormalMap.isTexture) {
            data.clearcoatNormalMap = this.clearcoatNormalMap.toJSON(meta).uuid;
            data.clearcoatNormalScale = this.clearcoatNormalScale.toArray();
        }
        if (this.dispersion !== undefined) data.dispersion = this.dispersion;
        if (this.iridescence !== undefined) data.iridescence = this.iridescence;
        if (this.iridescenceIOR !== undefined) data.iridescenceIOR = this.iridescenceIOR;
        if (this.iridescenceThicknessRange !== undefined) data.iridescenceThicknessRange = this.iridescenceThicknessRange;
        if (this.iridescenceMap && this.iridescenceMap.isTexture) {
            data.iridescenceMap = this.iridescenceMap.toJSON(meta).uuid;
        }
        if (this.iridescenceThicknessMap && this.iridescenceThicknessMap.isTexture) {
            data.iridescenceThicknessMap = this.iridescenceThicknessMap.toJSON(meta).uuid;
        }
        if (this.anisotropy !== undefined) data.anisotropy = this.anisotropy;
        if (this.anisotropyRotation !== undefined) data.anisotropyRotation = this.anisotropyRotation;
        if (this.anisotropyMap && this.anisotropyMap.isTexture) {
            data.anisotropyMap = this.anisotropyMap.toJSON(meta).uuid;
        }
        if (this.map && this.map.isTexture) data.map = this.map.toJSON(meta).uuid;
        if (this.matcap && this.matcap.isTexture) data.matcap = this.matcap.toJSON(meta).uuid;
        if (this.alphaMap && this.alphaMap.isTexture) data.alphaMap = this.alphaMap.toJSON(meta).uuid;
        if (this.lightMap && this.lightMap.isTexture) {
            data.lightMap = this.lightMap.toJSON(meta).uuid;
            data.lightMapIntensity = this.lightMapIntensity;
        }
        if (this.aoMap && this.aoMap.isTexture) {
            data.aoMap = this.aoMap.toJSON(meta).uuid;
            data.aoMapIntensity = this.aoMapIntensity;
        }
        if (this.bumpMap && this.bumpMap.isTexture) {
            data.bumpMap = this.bumpMap.toJSON(meta).uuid;
            data.bumpScale = this.bumpScale;
        }
        if (this.normalMap && this.normalMap.isTexture) {
            data.normalMap = this.normalMap.toJSON(meta).uuid;
            data.normalMapType = this.normalMapType;
            data.normalScale = this.normalScale.toArray();
        }
        if (this.displacementMap && this.displacementMap.isTexture) {
            data.displacementMap = this.displacementMap.toJSON(meta).uuid;
            data.displacementScale = this.displacementScale;
            data.displacementBias = this.displacementBias;
        }
        if (this.roughnessMap && this.roughnessMap.isTexture) data.roughnessMap = this.roughnessMap.toJSON(meta).uuid;
        if (this.metalnessMap && this.metalnessMap.isTexture) data.metalnessMap = this.metalnessMap.toJSON(meta).uuid;
        if (this.emissiveMap && this.emissiveMap.isTexture) data.emissiveMap = this.emissiveMap.toJSON(meta).uuid;
        if (this.specularMap && this.specularMap.isTexture) data.specularMap = this.specularMap.toJSON(meta).uuid;
        if (this.specularIntensityMap && this.specularIntensityMap.isTexture) data.specularIntensityMap = this.specularIntensityMap.toJSON(meta).uuid;
        if (this.specularColorMap && this.specularColorMap.isTexture) data.specularColorMap = this.specularColorMap.toJSON(meta).uuid;
        if (this.envMap && this.envMap.isTexture) {
            data.envMap = this.envMap.toJSON(meta).uuid;
            if (this.combine !== undefined) data.combine = this.combine;
        }
        if (this.envMapRotation !== undefined) data.envMapRotation = this.envMapRotation.toArray();
        if (this.envMapIntensity !== undefined) data.envMapIntensity = this.envMapIntensity;
        if (this.reflectivity !== undefined) data.reflectivity = this.reflectivity;
        if (this.refractionRatio !== undefined) data.refractionRatio = this.refractionRatio;
        if (this.gradientMap && this.gradientMap.isTexture) {
            data.gradientMap = this.gradientMap.toJSON(meta).uuid;
        }
        if (this.transmission !== undefined) data.transmission = this.transmission;
        if (this.transmissionMap && this.transmissionMap.isTexture) data.transmissionMap = this.transmissionMap.toJSON(meta).uuid;
        if (this.thickness !== undefined) data.thickness = this.thickness;
        if (this.thicknessMap && this.thicknessMap.isTexture) data.thicknessMap = this.thicknessMap.toJSON(meta).uuid;
        if (this.attenuationDistance !== undefined && this.attenuationDistance !== Infinity) data.attenuationDistance = this.attenuationDistance;
        if (this.attenuationColor !== undefined) data.attenuationColor = this.attenuationColor.getHex();
        if (this.size !== undefined) data.size = this.size;
        if (this.shadowSide !== null) data.shadowSide = this.shadowSide;
        if (this.sizeAttenuation !== undefined) data.sizeAttenuation = this.sizeAttenuation;
        if (this.blending !== NormalBlending) data.blending = this.blending;
        if (this.side !== FrontSide) data.side = this.side;
        if (this.vertexColors === true) data.vertexColors = true;
        if (this.opacity < 1) data.opacity = this.opacity;
        if (this.transparent === true) data.transparent = true;
        if (this.blendSrc !== SrcAlphaFactor) data.blendSrc = this.blendSrc;
        if (this.blendDst !== OneMinusSrcAlphaFactor) data.blendDst = this.blendDst;
        if (this.blendEquation !== AddEquation) data.blendEquation = this.blendEquation;
        if (this.blendSrcAlpha !== null) data.blendSrcAlpha = this.blendSrcAlpha;
        if (this.blendDstAlpha !== null) data.blendDstAlpha = this.blendDstAlpha;
        if (this.blendEquationAlpha !== null) data.blendEquationAlpha = this.blendEquationAlpha;
        if (this.blendColor && this.blendColor.isColor) data.blendColor = this.blendColor.getHex();
        if (this.blendAlpha !== 0) data.blendAlpha = this.blendAlpha;
        if (this.depthFunc !== LessEqualDepth) data.depthFunc = this.depthFunc;
        if (this.depthTest === false) data.depthTest = this.depthTest;
        if (this.depthWrite === false) data.depthWrite = this.depthWrite;
        if (this.colorWrite === false) data.colorWrite = this.colorWrite;
        if (this.stencilWriteMask !== 0xff) data.stencilWriteMask = this.stencilWriteMask;
        if (this.stencilFunc !== AlwaysStencilFunc) data.stencilFunc = this.stencilFunc;
        if (this.stencilRef !== 0) data.stencilRef = this.stencilRef;
        if (this.stencilFuncMask !== 0xff) data.stencilFuncMask = this.stencilFuncMask;
        if (this.stencilFail !== KeepStencilOp) data.stencilFail = this.stencilFail;
        if (this.stencilZFail !== KeepStencilOp) data.stencilZFail = this.stencilZFail;
        if (this.stencilZPass !== KeepStencilOp) data.stencilZPass = this.stencilZPass;
        if (this.stencilWrite === true) data.stencilWrite = this.stencilWrite;
        // rotation (SpriteMaterial)
        if (this.rotation !== undefined && this.rotation !== 0) data.rotation = this.rotation;
        if (this.polygonOffset === true) data.polygonOffset = true;
        if (this.polygonOffsetFactor !== 0) data.polygonOffsetFactor = this.polygonOffsetFactor;
        if (this.polygonOffsetUnits !== 0) data.polygonOffsetUnits = this.polygonOffsetUnits;
        if (this.linewidth !== undefined && this.linewidth !== 1) data.linewidth = this.linewidth;
        if (this.dashSize !== undefined) data.dashSize = this.dashSize;
        if (this.gapSize !== undefined) data.gapSize = this.gapSize;
        if (this.scale !== undefined) data.scale = this.scale;
        if (this.dithering === true) data.dithering = true;
        if (this.alphaTest > 0) data.alphaTest = this.alphaTest;
        if (this.alphaHash === true) data.alphaHash = true;
        if (this.alphaToCoverage === true) data.alphaToCoverage = this.alphaToCoverage;
        if (this.premultipliedAlpha === true) data.premultipliedAlpha = this.premultipliedAlpha;
        if (this.forceSinglePass === true) data.forceSinglePass = this.forceSinglePass;
        if (this.wireframe === true) data.wireframe = true;
        if (this.wireframeLinewidth > 1) data.wireframeLinewidth = this.wireframeLinewidth;
        if (this.wireframeLinecap !== 'round') data.wireframeLinecap = this.wireframeLinecap;
        if (this.wireframeLinejoin !== 'round') data.wireframeLinejoin = this.wireframeLinejoin;
        if (this.flatShading === true) data.flatShading = this.flatShading;
        if (this.visible === false) data.visible = false;
        if (this.toneMapped === false) data.toneMapped = false;
        if (this.fog === false) data.fog = false;
        if (Reflect.fields(this.userData).length > 0) data.userData = this.userData;
        // TODO: Copied from Object3D.toJSON
        function extractFromCache(cache) {
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
        return new Material().copy(this);
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
        var dstPlanes:Null<Array<Dynamic>> = null;
        if (srcPlanes !== null) {
            var n = srcPlanes.length;
            dstPlanes = new Array<Dynamic>(n);
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
        this.userData = Reflect.copy(source.userData);
        return this;
    }

    public function dispose() {
        this.dispatchEvent({ type: 'dispose' });
    }

    public function set needsUpdate(value:Bool) {
        if (value === true) this.version++;
    }
}