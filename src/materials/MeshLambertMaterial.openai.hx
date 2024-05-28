package three.materials;

import three.constants.MultiplyOperation;
import three.constants.TangentSpaceNormalMap;
import three.math.Vector2;
import three.math.Color;
import three.math.Euler;
import three.materials.Material;

class MeshLambertMaterial extends Material {
    public var isMeshLambertMaterial:Bool = true;

    public var type:String = 'MeshLambertMaterial';

    public var color:Color = new Color(0xffffff); // diffuse

    public var map:Dynamic = null;

    public var lightMap:Dynamic = null;
    public var lightMapIntensity:Float = 1.0;

    public var aoMap:Dynamic = null;
    public var aoMapIntensity:Float = 1.0;

    public var emissive:Color = new Color(0x000000);
    public var emissiveIntensity:Float = 1.0;
    public var emissiveMap:Dynamic = null;

    public var bumpMap:Dynamic = null;
    public var bumpScale:Float = 1.0;

    public var normalMap:Dynamic = null;
    public var normalMapType:TangentSpaceNormalMap = TangentSpaceNormalMap;
    public var normalScale:Vector2 = new Vector2(1, 1);

    public var displacementMap:Dynamic = null;
    public var displacementScale:Float = 1.0;
    public var displacementBias:Float = 0.0;

    public var specularMap:Dynamic = null;

    public var alphaMap:Dynamic = null;

    public var envMap:Dynamic = null;
    public var envMapRotation:Euler = new Euler();
    public var combine:MultiplyOperation = MultiplyOperation;
    public var reflectivity:Float = 1.0;
    public var refractionRatio:Float = 0.98;

    public var wireframe:Bool = false;
    public var wireframeLinewidth:Float = 1.0;
    public var wireframeLinecap:String = 'round';
    public var wireframeLinejoin:String = 'round';

    public var flatShading:Bool = false;

    public var fog:Bool = true;

    public function new(parameters:Dynamic) {
        super();
        setValues(parameters);
    }

    public function copy(source:MeshLambertMaterial):MeshLambertMaterial {
        super.copy(source);
        color.copy(source.color);

        map = source.map;

        lightMap = source.lightMap;
        lightMapIntensity = source.lightMapIntensity;

        aoMap = source.aoMap;
        aoMapIntensity = source.aoMapIntensity;

        emissive.copy(source.emissive);
        emissiveMap = source.emissiveMap;
        emissiveIntensity = source.emissiveIntensity;

        bumpMap = source.bumpMap;
        bumpScale = source.bumpScale;

        normalMap = source.normalMap;
        normalMapType = source.normalMapType;
        normalScale.copy(source.normalScale);

        displacementMap = source.displacementMap;
        displacementScale = source.displacementScale;
        displacementBias = source.displacementBias;

        specularMap = source.specularMap;

        alphaMap = source.alphaMap;

        envMap = source.envMap;
        envMapRotation.copy(source.envMapRotation);
        combine = source.combine;
        reflectivity = source.reflectivity;
        refractionRatio = source.refractionRatio;

        wireframe = source.wireframe;
        wireframeLinewidth = source.wireframeLinewidth;
        wireframeLinecap = source.wireframeLinecap;
        wireframeLinejoin = source.wireframeLinejoin;

        flatShading = source.flatShading;

        fog = source.fog;

        return this;
    }
}