import three.constants.MultiplyOperation;
import three.constants.TangentSpaceNormalMap;
import three.materials.Material;
import three.math.Vector2;
import three.math.Color;
import three.math.Euler;

class MeshPhongMaterial extends Material {

    public var isMeshPhongMaterial:Bool;
    public var type:String;

    public var color:Color;
    public var specular:Color;
    public var shininess:Float;

    public var map:Dynamic;

    public var lightMap:Dynamic;
    public var lightMapIntensity:Float;

    public var aoMap:Dynamic;
    public var aoMapIntensity:Float;

    public var emissive:Color;
    public var emissiveIntensity:Float;
    public var emissiveMap:Dynamic;

    public var bumpMap:Dynamic;
    public var bumpScale:Float;

    public var normalMap:Dynamic;
    public var normalMapType:Int;
    public var normalScale:Vector2;

    public var displacementMap:Dynamic;
    public var displacementScale:Float;
    public var displacementBias:Float;

    public var specularMap:Dynamic;

    public var alphaMap:Dynamic;

    public var envMap:Dynamic;
    public var envMapRotation:Euler;
    public var combine:Int;
    public var reflectivity:Float;
    public var refractionRatio:Float;

    public var wireframe:Bool;
    public var wireframeLinewidth:Float;
    public var wireframeLinecap:String;
    public var wireframeLinejoin:String;

    public var flatShading:Bool;

    public var fog:Bool;

    public function new(parameters:Dynamic) {
        super();

        this.isMeshPhongMaterial = true;

        this.type = 'MeshPhongMaterial';

        this.color = new Color(0xffffff); // diffuse
        this.specular = new Color(0x111111);
        this.shininess = 30;

        this.map = null;

        this.lightMap = null;
        this.lightMapIntensity = 1.0;

        this.aoMap = null;
        this.aoMapIntensity = 1.0;

        this.emissive = new Color(0x000000);
        this.emissiveIntensity = 1.0;
        this.emissiveMap = null;

        this.bumpMap = null;
        this.bumpScale = 1;

        this.normalMap = null;
        this.normalMapType = TangentSpaceNormalMap;
        this.normalScale = new Vector2(1, 1);

        this.displacementMap = null;
        this.displacementScale = 1;
        this.displacementBias = 0;

        this.specularMap = null;

        this.alphaMap = null;

        this.envMap = null;
        this.envMapRotation = new Euler();
        this.combine = MultiplyOperation;
        this.reflectivity = 1;
        this.refractionRatio = 0.98;

        this.wireframe = false;
        this.wireframeLinewidth = 1;
        this.wireframeLinecap = 'round';
        this.wireframeLinejoin = 'round';

        this.flatShading = false;

        this.fog = true;

        this.setValues(parameters);
    }

    public override function copy(source:Material):MeshPhongMaterial {
        super.copy(source);

        var src = cast(source, MeshPhongMaterial);

        this.color.copy(src.color);
        this.specular.copy(src.specular);
        this.shininess = src.shininess;

        this.map = src.map;

        this.lightMap = src.lightMap;
        this.lightMapIntensity = src.lightMapIntensity;

        this.aoMap = src.aoMap;
        this.aoMapIntensity = src.aoMapIntensity;

        this.emissive.copy(src.emissive);
        this.emissiveMap = src.emissiveMap;
        this.emissiveIntensity = src.emissiveIntensity;

        this.bumpMap = src.bumpMap;
        this.bumpScale = src.bumpScale;

        this.normalMap = src.normalMap;
        this.normalMapType = src.normalMapType;
        this.normalScale.copy(src.normalScale);

        this.displacementMap = src.displacementMap;
        this.displacementScale = src.displacementScale;
        this.displacementBias = src.displacementBias;

        this.specularMap = src.specularMap;

        this.alphaMap = src.alphaMap;

        this.envMap = src.envMap;
        this.envMapRotation.copy(src.envMapRotation);
        this.combine = src.combine;
        this.reflectivity = src.reflectivity;
        this.refractionRatio = src.refractionRatio;

        this.wireframe = src.wireframe;
        this.wireframeLinewidth = src.wireframeLinewidth;
        this.wireframeLinecap = src.wireframeLinecap;
        this.wireframeLinejoin = src.wireframeLinejoin;

        this.flatShading = src.flatShading;

        this.fog = src.fog;

        return this;
    }
}