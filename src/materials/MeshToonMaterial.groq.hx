Here is the equivalent Haxe code for the given JavaScript code:
```
package three.materials;

import three.constants.TangentSpaceNormalMap;
import three.materials.Material;
import three.math.Vector2;
import three.math.Color;

class MeshToonMaterial extends Material {

    public var isMeshToonMaterial:Bool = true;

    public var defines:Dynamic = { 'TOON': '' };

    public var type:String = 'MeshToonMaterial';

    public var color:Color;

    public var map:Dynamic;
    public var gradientMap:Dynamic;

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
    public var normalMapType:TangentSpaceNormalMap;
    public var normalScale:Vector2;

    public var displacementMap:Dynamic;
    public var displacementScale:Float = 1.0;
    public var displacementBias:Float = 0.0;

    public var alphaMap:Dynamic;

    public var wireframe:Bool = false;
    public var wireframeLinewidth:Int = 1;
    public var wireframeLinecap:String = 'round';
    public var wireframeLinejoin:String = 'round';

    public var fog:Bool = true;

    public function new(parameters:Dynamic) {
        super();

        color = new Color(0xffffff);

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
```
Note that I've used the `Dynamic` type to represent the `null` values in the JavaScript code, as Haxe does not have a direct equivalent to JavaScript's `null`. Also, I've used the `Bool` type for boolean values, and `Float` for floating-point numbers.