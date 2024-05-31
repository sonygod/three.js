将 JavaScript 代码转换为 Haxe 代码需要对语法进行相应的调整，并将模块导入和类定义转换为 Haxe 的形式。以下是转换后的 Haxe 代码：

```haxe
import three.math.Color;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;
import three.math.Matrix3;
import three.math.Matrix4;
import three.loaders.FileLoader;
import three.loaders.Loader;
import three.materials.Material;
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

class MaterialLoader extends Loader {

    public var textures:Map<String, Dynamic>;

    public function new(manager:Dynamic) {
        super(manager);
        this.textures = new Map();
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var scope = this;
        var loader = new FileLoader(scope.manager);
        loader.setPath(scope.path);
        loader.setRequestHeader(scope.requestHeader);
        loader.setWithCredentials(scope.withCredentials);
        loader.load(url, function(text:String) {
            try {
                onLoad(scope.parse(haxe.Json.parse(text)));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(json:Dynamic):Material {
        var textures = this.textures;

        function getTexture(name:String):Dynamic {
            if (!textures.exists(name)) {
                trace('THREE.MaterialLoader: Undefined texture ${name}');
            }
            return textures.get(name);
        }

        var material = MaterialLoader.createMaterialFromType(json.type);

        if (json.uuid != null) material.uuid = json.uuid;
        if (json.name != null) material.name = json.name;
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
        if (json.blending != null) material.blending = json.blending;
        if (json.combine != null) material.combine = json.combine;
        if (json.side != null) material.side = json.side;
        if (json.shadowSide != null) material.shadowSide = json.shadowSide;
        if (json.opacity != null) material.opacity = json.opacity;
        if (json.transparent != null) material.transparent = json.transparent;
        if (json.alphaTest != null) material.alphaTest = json.alphaTest;
        if (json.alphaHash != null) material.alphaHash = json.alphaHash;
        if (json.depthFunc != null) material.depthFunc = json.depthFunc;
        if (json.depthTest != null) material.depthTest = json.depthTest;
        if (json.depthWrite != null) material.depthWrite = json.depthWrite;
        if (json.colorWrite != null) material.colorWrite = json.colorWrite;
        if (json.blendSrc != null) material.blendSrc = json.blendSrc;
        if (json.blendDst != null) material.blendDst = json.blendDst;
        if (json.blendEquation != null) material.blendEquation = json.blendEquation;
        if (json.blendSrcAlpha != null) material.blendSrcAlpha = json.blendSrcAlpha;
        if (json.blendDstAlpha != null) material.blendDstAlpha = json.blendDstAlpha;
        if (json.blendEquationAlpha != null) material.blendEquationAlpha = json.blendEquationAlpha;
        if (json.blendColor != null && material.blendColor != null) material.blendColor.setHex(json.blendColor);
        if (json.blendAlpha != null) material.blendAlpha = json.blendAlpha;
        if (json.stencilWriteMask != null) material.stencilWriteMask = json.stencilWriteMask;
        if (json.stencilFunc != null) material.stencilFunc = json.stencilFunc;
        if (json.stencilRef != null) material.stencilRef = json.stencilRef;
        if (json.stencilFuncMask != null) material.stencilFuncMask = json.stencilFuncMask;
        if (json.stencilFail != null) material.stencilFail = json.stencilFail;
        if (json.stencilZFail != null) material.stencilZFail = json.stencilZFail;
        if (json.stencilZPass != null) material.stencilZPass = json.stencilZPass;
        if (json.stencilWrite != null) material.stencilWrite = json.stencilWrite;
        if (json.wireframe != null) material.wireframe = json.wireframe;
        if (json.wireframeLinewidth != null) material.wireframeLinewidth = json.wireframeLinewidth;
        if (json.wireframeLinecap != null) material.wireframeLinecap = json.wireframeLinecap;
        if (json.wireframeLinejoin != null) material.wireframeLinejoin = json.wireframeLinejoin;
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
            if (Std.is(json.vertexColors, Int)) {
                material.vertexColors = (json.vertexColors > 0);
            } else {
                material.vertexColors = json.vertexColors;
            }
        }

        if (json.uniforms != null) material.uniforms = json.uniforms;
        if (json.vertexShader != null) material.vertexShader = json.vertexShader;
        if (json.fragmentShader != null) material.fragmentShader = json.fragmentShader;
        if (json.glslVersion != null) material.glslVersion = json.glslVersion;
        if (json.extensions != null) material.extensions = json.extensions;
        if (json.defines != null) material.defines = json.defines;

        if (json.map != null && material.map != null) material.map = getTexture(json.map);
        if (json.matcap != null && material.matcap != null) material.matcap = getTexture(json.matcap);
        if (json.alphaMap != null && material.alphaMap != null) material.alphaMap = getTexture(json.alphaMap);
        if (json.bumpMap != null && material.bumpMap != null) material.bumpMap = getTexture(json.bumpMap);
        if (json.bumpScale != null) material.bumpScale = json.bumpScale;
        if (json.normalMap != null && material.normalMap != null) material.normalMap = getTexture(json.normalMap);
        if (json.normalMapType != null) material.normalMapType = json.normalMapType;
        if (json.normalScale != null) material.normalScale = new Vector2().fromArray(json.normalScale);
        if (json.displacementMap != null && material.displacementMap != null) material.displacementMap = getTexture(json.displacementMap);
        if (json.displacementScale != null) material.displacementScale = json.displacementScale;
        if (json.displacementBias != null) material.displacementBias = json.displacementBias;
        if (json.roughnessMap != null && material.roughnessMap != null) material.roughnessMap = getTexture(json.roughnessMap);
        if (json.metalnessMap != null && material.metalnessMap != null) material.metalnessMap = getTexture(json.metalnessMap);
        if (json.emissiveMap != null && material.emissiveMap != null) material.emissiveMap = getTexture(json.emissiveMap);
        if (json.emissiveIntensity != null) material.emissiveIntensity = json.emissiveIntensity;
        if (json.specularMap != null && material.specularMap != null) material.specularMap = getTexture(json.specularMap);
        if (json.specularIntensityMap != null && material.specularIntensityMap != null) material.specularIntensityMap = getTexture(json.specularIntensityMap);
        if (json.specularColorMap != null && material.specularColorMap != null) material.specularColorMap = getTexture(json.specularColorMap);
        if (json.envMap != null && material.envMap != null) material.envMap = getTexture(json.envMap);
        if (json.reflectivity != null) material.reflectivity = json.reflectivity;
        if (json.ior != null) material.ior = json.ior;
        if (json.refractionRatio != null) material.refractionRatio = json.refractionRatio;
        if (json.lightMap != null && material.lightMap != null) material.lightMap = getTexture(json.lightMap);
        if (json.lightMapIntensity != null) material.lightMapIntensity = json.lightMapIntensity;
        if (json.aoMap != null && material.aoMap != null) material.aoMap = getTexture(json.aoMap);
        if (json.aoMapIntensity != null) material.aoMapIntensity = json.aoMapIntensity;
        if (json.gradientMap != null && material.gradientMap != null) material.gradientMap = getTexture(json.gradientMap);
        if (json.clearcoatMap != null && material.clearcoatMap != null) material.clearcoatMap = getTexture(json.clearcoatMap);
        if (json.clearcoatRoughnessMap != null && material.clearcoatRoughnessMap != null) material.clearcoatRoughnessMap = getTexture(json.clearcoatRoughnessMap);
        if (json.clearcoatNormalMap != null && material.clearcoatNormalMap != null) material.clearcoatNormalMap = getTexture(json.clearcoatNormalMap);
        if (json.iridescenceMap != null && material.iridescenceMap != null) material.iridescenceMap = getTexture(json.iridescenceMap);
        if (json.iridescenceThicknessMap != null && material.iridescenceThicknessMap != null) material.iridescenceThicknessMap = getTexture(json.iridescenceThicknessMap);
        if (json.transmissionMap != null && material.transmissionMap != null) material.transmissionMap = getTexture(json.transmissionMap);
        if (json.thicknessMap != null && material.thicknessMap != null) material.thicknessMap = getTexture(json.thicknessMap);
        if (json.sheenColorMap != null && material.sheenColorMap != null) material.sheenColorMap = getTexture(json.sheenColorMap);
        if (json.sheenRoughnessMap != null && material.sheenRoughnessMap != null) material.sheenRoughnessMap = getTexture(json.sheenRoughnessMap);
        if (json.anisotropyMap != null && material.anisotropyMap != null) material.anisotropyMap = getTexture(json.anisotropyMap);
        if (json.mapEncoding != null && material.map != null) material.map.encoding = json.mapEncoding;
        if (json.matcapEncoding != null && material.matcap != null) material.matcap.encoding = json.matcapEncoding;
        if (json.alphaMapEncoding != null && material.alphaMap != null) material.alphaMap.encoding = json.alphaMapEncoding;
        if (json.bumpMapEncoding != null && material.bumpMap != null) material.bumpMap.encoding = json.bumpMapEncoding;
        if (json.normalMapEncoding != null && material.normalMap != null) material.normalMap.encoding = json.normalMapEncoding;
        if (json.displacementMapEncoding != null && material.displacementMap != null) material.displacementMap.encoding = json.displacementMapEncoding;
        if (json.roughnessMapEncoding != null && material.roughnessMap != null) material.roughnessMap.encoding = json.roughnessMapEncoding;
        if (json.metalnessMapEncoding != null && material.metalnessMap != null) material.metalnessMap.encoding = json.metalnessMapEncoding;
        if (json.emissiveMapEncoding != null && material.emissiveMap != null) material.emissiveMap.encoding = json.emissiveMapEncoding;
        if (json.specularMapEncoding != null && material.specularMap != null) material.specularMap.encoding = json.specularMapEncoding;
        if (json.specularIntensityMapEncoding != null && material.specularIntensityMap != null) material.specularIntensityMap.encoding = json.specularIntensityMapEncoding;
        if (json.specularColorMapEncoding != null && material.specularColorMap != null) material.specularColorMap.encoding = json.specularColorMapEncoding;
        if (json.envMapEncoding != null && material.envMap != null) material.envMap.encoding = json.envMapEncoding;
        if (json.lightMapEncoding != null && material.lightMap != null) material.lightMap.encoding = json.lightMapEncoding;
        if (json.aoMapEncoding != null && material.aoMap != null) material.aoMap.encoding = json.aoMapEncoding;
        if (json.gradientMapEncoding != null && material.gradientMap != null) material.gradientMap.encoding = json.gradientMapEncoding;
        if (json.clearcoatMapEncoding != null && material.clearcoatMap != null) material.clearcoatMap.encoding = json.clearcoatMapEncoding;
        if (json.clearcoatRoughnessMapEncoding != null && material.clearcoatRoughnessMap != null) material.clearcoatRoughnessMap.encoding = json.clearcoatRoughnessMapEncoding;
        if (json.clearcoatNormalMapEncoding != null && material.clearcoatNormalMap != null) material.clearcoatNormalMap.encoding = json.clearcoatNormalMapEncoding;
        if (json.iridescenceMapEncoding != null && material.iridescenceMap != null) material.iridescenceMap.encoding = json.iridescenceMapEncoding;
        if (json.iridescenceThicknessMapEncoding != null && material.iridescenceThicknessMap != null) material.iridescenceThicknessMap.encoding = json.iridescenceThicknessMapEncoding;
        if (json.transmissionMapEncoding != null && material.transmissionMap != null) material.transmissionMap.encoding = json.transmissionMapEncoding;
        if (json.thicknessMapEncoding != null && material.thicknessMap != null) material.thicknessMap.encoding = json.thicknessMapEncoding;
        if (json.sheenColorMapEncoding != null && material.sheenColorMap != null) material.sheenColorMap.encoding = json.sheenColorMapEncoding;
        if (json.sheenRoughnessMapEncoding != null && material.sheenRoughnessMap != null) material.sheenRoughnessMap.encoding = json.sheenRoughnessMapEncoding;
        if (json.anisotropyMapEncoding != null && material.anisotropyMap != null) material.anisotropyMap.encoding = json.anisotropyMapEncoding;

        return material;
    }

    static public function createMaterialFromType(type:String):Material {
        switch (type) {
            case 'ShadowMaterial': return new ShadowMaterial();
            case 'SpriteMaterial': return new SpriteMaterial();
            case 'RawShaderMaterial': return new RawShaderMaterial();
            case 'ShaderMaterial': return new ShaderMaterial();
            case 'PointsMaterial': return new PointsMaterial();
            case 'MeshPhysicalMaterial': return new MeshPhysicalMaterial();
            case 'MeshStandardMaterial': return new MeshStandardMaterial();
            case