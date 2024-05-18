package three.materials;

import three.constants.MultiplyOperation;
import three.constants.TangentSpaceNormalMap;
import three.math.Color;
import three.math.Euler;
import three.math.Vector2;
import three.materials.Material;

class MeshPhongMaterial extends Material {

    public var isMeshPhongMaterial:Bool = true;

    public var type:String = 'MeshPhongMaterial';

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

    public function new(parameters:Dynamic = null) {
        super();
        color = new Color(0xffffff); // diffuse
        specular = new Color(0x111111);
        shininess = 30;

        map = null;

        lightMap = null;
        lightMapIntensity = 1.0;

        aoMap = null;
        aoMapIntensity = 1.0;

        emissive = new Color(0x000000);
        emissiveIntensity = 1.0;
        emissiveMap = null;

        bumpMap = null;
        bumpScale = 1;

        normalMap = null;
        normalMapType = TangentSpaceNormalMap;
        normalScale = new Vector2(1, 1);

        displacementMap = null;
        displacementScale = 1;
        displacementBias = 0;

        specularMap = null;

        alphaMap = null;

        envMap = null;
        envMapRotation = new Euler();
        combine = MultiplyOperation;
        reflectivity = 1;
        refractionRatio = 0.98;

        wireframe = false;
        wireframeLinewidth = 1;
        wireframeLinecap = 'round';
        wireframeLinejoin = 'round';

        flatShading = false;

        fog = true;

        if (parameters != null) {
            setValues(parameters);
        }
    }

    public function copy(source:MeshPhongMaterial):MeshPhongMaterial {
        super.copy(source);

        color.copy(source.color);
        specular.copy(source.specular);
        shininess = source.shininess;

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