Here is the equivalent Haxe code:
```
package three.materials;

import three.Material;

class MeshDepthMaterial extends Material {
    public var isMeshDepthMaterial:Bool = true;
    public var type:String = 'MeshDepthMaterial';
    public var depthPacking:BasicDepthPacking;
    public var map:Null<Texture>;
    public var alphaMap:Null<Texture>;
    public var displacementMap:Null<Texture>;
    public var displacementScale:Float = 1;
    public var displacementBias:Float = 0;
    public var wireframe:Bool = false;
    public var wireframeLinewidth:Int = 1;

    public function new(parameters:Dynamic = null) {
        super();
        if (parameters != null) {
            setValues(parameters);
        }
    }

    public function copy(source:MeshDepthMaterial):MeshDepthMaterial {
        super.copy(source);
        depthPacking = source.depthPacking;
        map = source.map;
        alphaMap = source.alphaMap;
        displacementMap = source.displacementMap;
        displacementScale = source.displacementScale;
        displacementBias = source.displacementBias;
        wireframe = source.wireframe;
        wireframeLinewidth = source.wireframeLinewidth;
        return this;
    }
}
```
Note that I've made the following assumptions:

* `BasicDepthPacking` is an enum, so I've left it as is.
* `Texture` is a class that represents a texture, so I've used `Null<Texture>` to represent a nullable texture.
* `setValues` is a method that sets the material's properties from an object, so I've left it as is.

Also, note that in Haxe, we don't need to use `export` statements, as the class is automatically exported.