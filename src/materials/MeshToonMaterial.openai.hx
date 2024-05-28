package three.materials;

import three.constants.TangentSpaceNormalMap;
import three.math.Vector2;
import three.math.Color;
import three.materials.Material;

class MeshToonMaterial extends Material {
    public var isMeshToonMaterial:Bool = true;

    public var defines:Dynamic = { 'TOON': '' };

    public var type:String = 'MeshToonMaterial';

    public var color:Color = new Color(0xffffff);

    public var map:Dynamic = null;
    public var gradientMap:Dynamic = null;

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

    public var alphaMap:Dynamic = null;

    public var wireframe:Bool = false;
    public var wireframeLinewidth:Int = 1;
    public var wireframeLinecap:String = 'round';
    public var wireframeLinejoin:String = 'round';

    public var fog:Bool = true;

    public function new(parameters:Dynamic = null) {
        super();
        setValues(parameters);
    }

    public function copy(source:MeshToonMaterial):MeshToonMaterial {
        super.copy(source);

        color.copy(source.color);

        map = source.map;
        gradientMap = source.gradientMap;

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

        alphaMap = source.alphaMap;

        wireframe = source.wireframe;
        wireframeLinewidth = source.wireframeLinewidth;
        wireframeLinecap = source.wireframeLinecap;
        wireframeLinejoin = source.wireframeLinejoin;

        fog = source.fog;

        return this;
    }
}