package three.materials;

import three.constants.MultiplyOperation;
import three.constants.TangentSpaceNormalMap;
import three.materials.Material;
import three.math.Vector2;
import three.math.Color;
import three.math.Euler;

class MeshLambertMaterial extends Material {

    public var isMeshLambertMaterial:Bool = true;

    public var type:String = 'MeshLambertMaterial';

    public var color:Color;

    public var map:Dynamic;

    public var lightMap:Dynamic;
    public var lightMapIntensity:Float = 1.0;

    public var aoMap:Dynamic;
    public var aoMapIntensity:Float = 1.0;

    public var emissive:Color;
    public var emissiveIntensity:Float = 1.0;
    public var emissiveMap:Dynamic;

    public var bumpMap:Dynamic;
    public var bumpScale:Float = 1.0;

    public var normalMap:Dynamic;
    public var normalMapType:Int = TangentSpaceNormalMap;
    public var normalScale:Vector2;

    public var displacementMap:Dynamic;
    public var displacementScale:Float = 1.0;
    public var displacementBias:Float = 0.0;

    public var specularMap:Dynamic;

    public var alphaMap:Dynamic;

    public var envMap:Dynamic;
    public var envMapRotation:Euler;
    public var combine:Int = MultiplyOperation;
    public var reflectivity:Float = 1.0;
    public var refractionRatio:Float = 0.98;

    public var wireframe:Bool = false;
    public var wireframeLinewidth:Int = 1;
    public var wireframeLinecap:String = 'round';
    public var wireframeLinejoin:String = 'round';

    public var flatShading:Bool = false;

    public var fog:Bool = true;

    public function new(parameters:Dynamic = null) {
        super();

        color = new Color(0xffffff); // diffuse

        if (parameters != null) {
            setValues(parameters);
        }
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