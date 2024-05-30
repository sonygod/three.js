import js.three.constants.MultiplyOperation;
import js.three.constants.TangentSpaceNormalMap;
import js.three.materials.Material;
import js.three.math.Vector2;
import js.three.math.Color;
import js.three.math.Euler;

class MeshLambertMaterial extends Material {
    public var color: Color;
    public var map: Null<Color>;
    public var lightMap: Null<Color>;
    public var lightMapIntensity: Float;
    public var aoMap: Null<Color>;
    public var aoMapIntensity: Float;
    public var emissive: Color;
    public var emissiveIntensity: Float;
    public var emissiveMap: Null<Color>;
    public var bumpMap: Null<Color>;
    public var bumpScale: Float;
    public var normalMap: Null<Color>;
    public var normalMapType: Null<TangentSpaceNormalMap>;
    public var normalScale: Vector2;
    public var displacementMap: Null<Color>;
    public var displacementScale: Float;
    public var displacementBias: Float;
    public var specularMap: Null<Color>;
    public var alphaMap: Null<Color>;
    public var envMap: Null<Color>;
    public var envMapRotation: Euler;
    public var combine: MultiplyOperation;
    public var reflectivity: Float;
    public var refractionRatio: Float;
    public var wireframe: Bool;
    public var wireframeLinewidth: Int;
    public var wireframeLinecap: String;
    public var wireframeLinejoin: String;
    public var flatShading: Bool;
    public var fog: Bool;

    public function new(parameters: Dynamic) {
        super();

        this.isMeshLambertMaterial = true;
        this.type = 'MeshLambertMaterial';
        this.color = new Color(0xffffff);
        this.lightMapIntensity = 1.0;
        this.aoMapIntensity = 1.0;
        this.emissive = new Color(0x000000);
        this.emissiveIntensity = 1.0;
        this.bumpScale = 1.0;
        this.normalMapType = TangentSpaceNormalMap;
        this.normalScale = new Vector2(1, 1);
        this.displacementScale = 1.0;
        this.reflectivity = 1.0;
        this.refractionRatio = 0.98;
        this.wireframeLinewidth = 1;
        this.wireframeLinecap = 'round';
        this.wireframeLinejoin = 'round';
        this.fog = true;

        this.setValues(parameters);
    }

    public function copy(source: MeshLambertMaterial): MeshLambertMaterial {
        super.copy(source);

        this.color.copy(source.color);
        this.map = source.map;
        this.lightMap = source.lightMap;
        this.lightMapIntensity = source.lightMapIntensity;
        this.aoMap = source.aoMap;
        this.aoMapIntensity = source.aoMapIntensity;
        this.emissive.copy(source.emissive);
        this.emissiveMap = source.emissiveMap;
        this.emissiveIntensity = source.emissiveIntensity;
        this.bumpMap = source.bumpMap;
        this.bumpScale = source.bumpScale;
        this.normalMap = source.normalMap;
        this.normalMapType = source.normalMapType;
        this.normalScale.copy(source.normalScale);
        this.displacementMap = source.displacementMap;
        this.displacementScale = source.displacementScale;
        this.displacementBias = source.displacementBias;
        this.specularMap = source.specularMap;
        this.alphaMap = source.alphaMap;
        this.envMap = source.envMap;
        this.envMapRotation.copy(source.envMapRotation);
        this.combine = source.combine;
        this.reflectivity = source.reflectivity;
        this.refractionRatio = source.refractionRatio;
        this.wireframe = source.wireframe;
        this.wireframeLinewidth = source.wireframeLinewidth;
        this.wireframeLinecap = source.wireframeLinecap;
        this.wireframeLinejoin = source.wireframeLinejoin;
        this.flatShading = source.flatShading;
        this.fog = source.fog;

        return this;
    }
}