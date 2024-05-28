Here is the equivalent Haxe code:
```
package three.materials;

import three.constants.TangentSpaceNormalMap;
import three.materials.Material;
import three.math.Vector2;
import three.math.Color;

class MeshMatcapMaterial extends Material {

    public var isMeshMatcapMaterial:Bool = true;

    public var defines:Dynamic = { 'MATCAP': '' };

    public var type:String = 'MeshMatcapMaterial';

    public var color:Color;

    public var matcap:Dynamic;

    public var map:Dynamic;

    public var bumpMap:Dynamic;
    public var bumpScale:Float = 1;

    public var normalMap:Dynamic;
    public var normalMapType:TangentSpaceNormalMap;
    public var normalScale:Vector2;

    public var displacementMap:Dynamic;
    public var displacementScale:Float = 1;
    public var displacementBias:Float = 0;

    public var alphaMap:Dynamic;

    public var flatShading:Bool = false;

    public var fog:Bool = true;

    public function new(parameters:Dynamic = null) {
        super();
        color = new Color(0xffffff); // diffuse
        setValues(parameters);
    }

    public function copy(source:MeshMatcapMaterial):MeshMatcapMaterial {
        super.copy(source);
        defines = { 'MATCAP': '' };
        color.copy(source.color);
        matcap = source.matcap;
        map = source.map;
        bumpMap = source.bumpMap;
        bumpScale = source.bumpScale;
        normalMap = source.normalMap;
        normalMapType = source.normalMapType;
        normalScale.copy(source.normalScale);
        displacementMap = source.displacementMap;
        displacementScale = source.displacementScale;
        displacementBias = source.displacementBias;
        alphaMap = source.alphaMap;
        flatShading = source.flatShading;
        fog = source.fog;
        return this;
    }

}

// Note: In Haxe, we don't need to use the `export` keyword to make the class available for use.
```
Please note that I've made the following assumptions:

* `Dynamic` is used to represent the types of `matcap`, `map`, `bumpMap`, `normalMap`, `displacementMap`, and `alphaMap` since they are not explicitly typed in the JavaScript code.
* `Float` is used to represent the types of `bumpScale`, `displacementScale`, and `displacementBias` since they are numeric values.
* `Bool` is used to represent the types of `flatShading` and `fog` since they are boolean values.

Also, I've kept the same naming conventions and coding style as the original JavaScript code to make it easier to read and maintain.