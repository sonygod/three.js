import three.math.Color;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;
import three.math.Matrix3;
import three.math.Matrix4;
import three.loaders.FileLoader;
import three.loaders.Loader;
import three.materials.ShadowMaterial;
import three.materials.SpriteMaterial;
import three.materials.RawShaderMaterial;
import three.materials.ShaderMaterial;
import three.materials.PointsMaterial;
import three.materials.MeshPhysicalMaterial;
import three.materials.MeshStandardMaterial;
import three.materials.MeshPhongMaterial;
import three.materials.MeshToonMaterial;
import three.materials.MeshNormalMaterial;
import three.materials.MeshLambertMaterial;
import three.materials.MeshDepthMaterial;
import three.materials.MeshDistanceMaterial;
import three.materials.MeshBasicMaterial;
import three.materials.MeshMatcapMaterial;
import three.materials.LineDashedMaterial;
import three.materials.LineBasicMaterial;
import three.materials.Material;

class MaterialLoader extends Loader {
    public var textures:haxe.ds.StringMap<Texture>;

    public function new(manager:Loader.Manager) {
        super(manager);
        this.textures = new haxe.ds.StringMap();
    }

    public function load(url:String, onLoad:(material:Material) -> Void, onProgress:(event:ProgressEvent) -> Void, onError:(event:ErrorEvent) -> Void) {
        var loader:FileLoader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);

        loader.load(url, function(text:String) {
            try {
                onLoad(this.parse(haxe.Json.parse(text)));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                this.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(json:Dynamic):Material {
        var getTexture = function(name:String):Texture {
            if (this.textures.exists(name) == false) {
                trace("THREE.MaterialLoader: Undefined texture " + name);
            }
            return this.textures.get(name);
        };

        var material = MaterialLoader.createMaterialFromType(Std.string(json.type));

        if (json.uuid != null) material.uuid = Std.string(json.uuid);
        if (json.name != null) material.name = Std.string(json.name);
        if (json.color != null && material.color != null) material.color.setHex(json.color);
        if (json.roughness != null) material.roughness = json.roughness;
        if (json.metalness != null) material.metalness = json.metalness;
        if (json.sheen != null) material.sheen = json.sheen;
        if (json.sheenColor != null) material.sheenColor = new Color().setHex(json.sheenColor);
        if (json.sheenRoughness != null) material.sheenRoughness = json.sheenRoughness;
        if (json.emissive != null && material.emissive != null) material.emissive.setHex(json.emissive);
        if (json.specular != null && material.specular != null) material.specular.setHex(json.specular);
        if (json.specularIntensity != null) material.specularIntensity = json.specularIntensity;
        if (json.specularColor != null && material.specularColor != null) material.specularColor.setHex(json.specularColor);
        if (json.shininess != null) material.shininess = json.shininess;
        if (json.clearcoat != null) material.clearcoat = json.clearcoat;
        if (json.clearcoatRoughness != null) material.clearcoatRoughness = json.clearcoatRoughness;
        if (json.dispersion != null) material.dispersion = json.dispersion;
        if (json.iridescence != null) material.iridescence = json.iridescence;
        if (json.iridescenceIOR != null) material.iridescenceIOR = json.iridescenceIOR;
        if (json.iridescenceThicknessRange != null) material.iridescenceThicknessRange = json.iridescenceThicknessRange;
        if (json.transmission != null) material.transmission = json.transmission;
        if (json.thickness != null) material.thickness = json.thickness;
        if (json.attenuationDistance != null) material.attenuationDistance = json.attenuationDistance;
        if (json.attenuationColor != null && material.attenuationColor != null) material.attenuationColor.setHex(json.attenuationColor);
        if (json.anisotropy != null) material.anisotropy = json.anisotropy;
        if (json.anisotropyRotation != null) material.anisotropyRotation = json.anisotropyRotation;
        if (json.fog != null) material.fog = json.fog;
        if (json.flatShading != null) material.flatShading = json.flatShading;
        if (json.blending != null) material.blending = Std.string(json.blending);
        if (json.combine != null) material.combine = Std.string(json.combine);
        if (json.side != null) material.side = Std.string(json.side);
        if (json.shadowSide != null) material.shadowSide = Std.string(json.shadowSide);
        if (json.opacity != null) material.opacity = json.opacity;
        if (json.transparent != null) material.transparent = json.transparent;
        if (json.alphaTest != null) material.alphaTest = json.alphaTest;
        if (json.alphaHash != null) material.alphaHash = json.alphaHash;
        if (json.depthFunc != null) material.depthFunc = Std.string(json.depthFunc);
        if (json.depthTest != null) material.depthTest = json.depthTest;
        if (json.depthWrite != null) material.depthWrite = json.depthWrite;
        if (json.colorWrite != null) material.colorWrite = json.colorWrite;
        if (json.blendSrc != null) material.blendSrc = Std.string(json.blendSrc);
        if (json.blendDst != null) material.blendDst = Std.string(json.blendDst);
        if (json.blendEquation != null) material.blendEquation = Std.string(json.blendEquation);
        if (json.blendSrcAlpha != null) material.blendSrcAlpha = Std.string(json.blendSrcAlpha);
        if (json.blendDstAlpha != null) material.blendDstAlpha = Std.string(json.blendDstAlpha);
        if (json.blendEquationAlpha != null) material.blendEquationAlpha = Std.string(json.blendEquationAlpha);
        if (json.blendColor != null && material.blendColor != null) material.blendColor.setHex(json.blendColor);
        if (json.blendAlpha != null) material.blendAlpha = json.blendAlpha;
        if (json.stencilWriteMask != null) material.stencilWriteMask = json.stencilWriteMask;
        if (json.stencilFunc != null) material.stencilFunc = Std.string(json.stencilFunc);
        if (json.stencilRef != null) material.stencilRef = json.stencilRef;
        if (json.stencilFuncMask != null) material.stencilFuncMask = json.stencilFuncMask;
        if (json.stencilFail != null) material.stencilFail = Std.string(json.stencilFail);
        if (json.stencilZFail != null) material.stencilZFail = Std.string(json.stencilZFail);
        if (json.stencilZPass != null) material.stencilZPass = Std.string(json.stencilZPass);
        if (json.stencilWrite != null) material.stencilWrite = json.stencilWrite;

        if (json.wireframe != null) material.wireframe = json.wireframe;
        if (json.wireframeLinewidth != null) material.wireframeLinewidth = json.wireframeLinewidth;
        if (json.wireframeLinecap != null) material.wireframeLinecap = Std.string(json.wireframeLinecap);
        if (json.wireframeLinejoin != null) material.wireframeLinejoin = Std.string(json.wireframeLinejoin);

        if (json.rotation != null) material.rotation = json.rotation;

        if (json.linewidth != null) material.linewidth = json.linewidth;
        if (json.dashSize != null) material.dashSize = json.dashSize;
        if (json.gapSize != null) material.gapSize = json.gapSize;
        if (json.scale != null) material.scale = json.scale;

        if (json.polygonOffset != null) material.polygonOffset = json.polygonOffset;
        if (json.polygonOffsetFactor != null) material.polygonOffsetFactor = json.polygonOffsetFactor;
        if (json.polygonOffsetUnits != null) material.polygonOffsetUnits = json.polygonOffsetUnits;

        if (json.dithering != null) material.dithering = json.dithering;

        if (json.alphaToCoverage != null) material.alphaToCoverage = json.alphaToCoverage;
        if (json.premultipliedAlpha != null) material.premultipliedAlpha = json.premultipliedAlpha;
        if (json.forceSinglePass != null) material.forceSinglePass = json.forceSinglePass;

        if (json.visible != null) material.visible = json.visible;

        if (json.toneMapped != null) material.toneMapped = json.toneMapped;

        if (json.userData != null) material.userData = json.userData;

        if (json.vertexColors != null) {
            if (Std.isInt(json.vertexColors)) {
                material.vertexColors = (json.vertexColors > 0) ? true : false;
            } else {
                material.vertexColors = Std.string(json.vertexColors);
            }
        }

        if (json.uniforms != null) {
            for (name in json.uniforms.keys()) {
                var uniform = json.uniforms[name];

                material.uniforms[name] = {};

                switch (Std.string(uniform.type)) {
                    case "t":
                        material.uniforms[name].value = getTexture(Std.string(uniform.value));
                        break;
                    case "c":
                        material.uniforms[name].value = new Color().setHex(uniform.value);
                        break;
                    case "v2":
                        material.uniforms[name].value = new Vector2().fromArray(uniform.value);
                        break;
                    case "v3":
                        material.uniforms[name].value = new Vector3().fromArray(uniform.value);
                        break;
                    case "v4":
                        material.uniforms[name].value = new Vector4().fromArray(uniform.value);
                        break;
                    case "m3":
                        material.uniforms[name].value = new Matrix3().fromArray(uniform.value);
                        break;
                    case "m4":
                        material.uniforms[name].value = new Matrix4().fromArray(uniform.value);
                        break;
                    default:
                        material.uniforms[name].value = uniform.value;
                }
            }
        }

        if (json.defines != null) material.defines = json.defines;
        if (json.vertexShader != null) material.vertexShader = Std.string(json.vertexShader);
        if (json.fragmentShader != null) material.fragmentShader = Std.string(json.fragmentShader);
        if (json.glslVersion != null) material.glslVersion = Std.string(json.glslVersion);

        if (json.extensions != null) {
            for (key in json.extensions.keys()) {
                material.extensions[key] = json.extensions[key];
            }
        }

        if (json.lights != null) material.lights = json.lights;
        if (json.clipping != null) material.clipping = json.clipping;

        if (json.size != null) material.size = json.size;
        if (json.sizeAttenuation != null) material.sizeAttenuation = json.sizeAttenuation;

        if (json.map != null) material.map = getTexture(Std.string(json.map));
        if (json.matcap != null) material.matcap = getTexture(Std.string(json.matcap));

        if (json.alphaMap != null) material.alphaMap = getTexture(Std.string(json.alphaMap));

        if (json.bumpMap != null) material.bumpMap = getTexture(Std.string(json.bumpMap));
        if (json.bumpScale != null) material.bumpScale = json.bumpScale;

        if (json.normalMap != null) material.normalMap = getTexture(Std.string(json.normalMap));
        if (json.normalMapType != null) material.normalMapType = Std.string(json.normalMapType);
        if (json.normalScale != null) {
            var normalScale = json.normalScale;
            if (Std.is(normalScale, Array<Float>).not()) {
                normalScale = [normalScale, normalScale];
            }
            material.normalScale = new Vector2().fromArray(normalScale);
        }

        if (json.displacementMap != null) material.displacementMap = getTexture(Std.string(json.displacementMap));
        if (json.displacementScale != null) material.displacementScale = json.displacementScale;
        if (json.displacementBias != null) material.displacementBias = json.displacementBias;

        if (json.roughnessMap != null) material.roughnessMap = getTexture(Std.string(json.roughnessMap));
        if (json.metalnessMap != null) material.metalnessMap = getTexture(Std.string(json.metalnessMap));

        if (json.emissiveMap != null) material.emissiveMap = getTexture(Std.string(json.emissiveMap));
        if (json.emissiveIntensity != null) material.emissiveIntensity = json.emissiveIntensity;

        if (json.specularMap != null) material.specularMap = getTexture(Std.string(json.specularMap));
        if (json.specularIntensityMap != null) material.specularIntensityMap = getTexture(Std.string(json.specularIntensityMap));
        if (json.specularColorMap != null) material.specularColorMap = getTexture(Std.string(json.specularColorMap));

        if (json.envMap != null) material.envMap = getTexture(Std.string(json.envMap));
        if (json.envMapRotation != null) material.envMapRotation.fromArray(json.envMapRotation);
        if (json.envMapIntensity != null) material.envMapIntensity = json.envMapIntensity;

        if (json.reflectivity != null) material.reflectivity = json.reflectivity;
        if (json.refractionRatio != null) material.refractionRatio = json.refractionRatio;

        if (json.lightMap != null) material.lightMap = getTexture(Std.string(json.lightMap));
        if (json.lightMapIntensity != null) material.lightMapIntensity = json.lightMapIntensity;

        if (json.aoMap != null) material.aoMap = getTexture(Std.string(json.aoMap));
        if (json.aoMapIntensity != null) material.aoMapIntensity = json.aoMapIntensity;

        if (json.gradientMap != null) material.gradientMap = getTexture(Std.string(json.gradientMap));

        if (json.clearcoatMap != null) material.clearcoatMap = getTexture(Std.string(json.clearcoatMap));
        if (json.clearcoatRoughnessMap != null) material.clearcoatRoughnessMap = getTexture(Std.string(json.clearcoatRoughnessMap));
        if (json.clearcoatNormalMap != null) material.clearcoatNormalMap = getTexture(Std.string(json.clearcoatNormalMap));
        if (json.clearcoatNormalScale != null) material.clearcoatNormalScale = new Vector2().fromArray(json.clearcoatNormalScale);

        if (json.iridescenceMap != null) material.iridescenceMap = getTexture(Std.string(json.iridescenceMap));
        if (json.iridescenceThicknessMap != null) material.iridescenceThicknessMap = getTexture(Std.string(json.iridescenceThicknessMap));

        if (json.transmissionMap != null) material.transmissionMap = getTexture(Std.string(json.transmissionMap));
        if (json.thicknessMap != null) material.thicknessMap = getTexture(Std.string(json.thicknessMap));

        if (json.anisotropyMap != null) material.anisotropyMap = getTexture(Std.string(json.anisotropyMap));

        if (json.sheenColorMap != null) material.sheenColorMap = getTexture(Std.string(json.sheenColorMap));
        if (json.sheenRoughnessMap != null) material.sheenRoughnessMap = getTexture(Std.string(json.sheenRoughnessMap));

        return material;
    }

    public function setTextures(value:haxe.ds.StringMap<Texture>):MaterialLoader {
        this.textures = value;
        return this;
    }

    public static function createMaterialFromType(type:String):Material {
        switch (type) {
            case "ShadowMaterial":
                return new ShadowMaterial();
            case "SpriteMaterial":
                return new SpriteMaterial();
            case "RawShaderMaterial":
                return new RawShaderMaterial();
            case "ShaderMaterial":
                return new ShaderMaterial();
            case "PointsMaterial":
                return new PointsMaterial();
            case "MeshPhysicalMaterial":
                return new MeshPhysicalMaterial();
            case "MeshStandardMaterial":
                return new MeshStandardMaterial();
            case "MeshPhongMaterial":
                return new MeshPhongMaterial();
            case "MeshToonMaterial":
                return new MeshToonMaterial();
            case "MeshNormalMaterial":
                return new MeshNormalMaterial();
            case "MeshLambertMaterial":
                return new MeshLambertMaterial();
            case "MeshDepthMaterial":
                return new MeshDepthMaterial();
            case "MeshDistanceMaterial":
                return new MeshDistanceMaterial();
            case "MeshBasicMaterial":
                return new MeshBasicMaterial();
            case "MeshMatcapMaterial":
                return new MeshMatcapMaterial();
            case "LineDashedMaterial":
                return new LineDashedMaterial();
            case "LineBasicMaterial":
                return new LineBasicMaterial();
            case "Material":
                return new Material();
            default:
                throw "Unknown material type: " + type;
        }
    }
}