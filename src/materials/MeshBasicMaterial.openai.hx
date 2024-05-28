package three.materials;

import three.Material;
import three.constants.MultiplyOperation;
import three.math.Color;
import three.math.Euler;

class MeshBasicMaterial extends Material {

    public var isMeshBasicMaterial:Bool = true;
    public var type:String = 'MeshBasicMaterial';

    public var color:Color = new Color(0xFFFFFF); // emissive

    public var map:Dynamic = null;
    public var lightMap:Dynamic = null;
    public var lightMapIntensity:Float = 1.0;
    public var aoMap:Dynamic = null;
    public var aoMapIntensity:Float = 1.0;
    public var specularMap:Dynamic = null;
    public var alphaMap:Dynamic = null;
    public var envMap:Dynamic = null;
    public var envMapRotation:Euler = new Euler();
    public var combine:MultiplyOperation = MultiplyOperation.MultiplyOperation;
    public var reflectivity:Float = 1.0;
    public var refractionRatio:Float = 0.98;
    public var wireframe:Bool = false;
    public var wireframeLinewidth:Int = 1;
    public var wireframeLinecap:String = 'round';
    public var wireframeLinejoin:String = 'round';
    public var fog:Bool = true;

    public function new(parameters:Dynamic = null) {
        super();
        if (parameters != null) {
            setValues(parameters);
        }
    }

    public function copy(source:MeshBasicMaterial):MeshBasicMaterial {
        super.copy(source);
        color.copy(source.color);
        map = source.map;
        lightMap = source.lightMap;
        lightMapIntensity = source.lightMapIntensity;
        aoMap = source.aoMap;
        aoMapIntensity = source.aoMapIntensity;
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
        fog = source.fog;
        return this;
    }
}