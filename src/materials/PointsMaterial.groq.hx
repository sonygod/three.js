Here is the equivalent Haxe code:
```
package three.js.src.materials;

import three.js.src.materials.Material;
import three.js.src.math.Color;

class PointsMaterial extends Material {
    
    public var isPointsMaterial:Bool = true;
    public var type:String = 'PointsMaterial';
    public var color:Color;
    public var map:Dynamic;
    public var alphaMap:Dynamic;
    public var size:Float = 1;
    public var sizeAttenuation:Bool = true;
    public var fog:Bool = true;

    public function new(parameters: Dynamic = null) {
        super();
        color = new Color(0xffffff);
        if (parameters != null) {
            setValues(parameters);
        }
    }

    public function copy(source:PointsMaterial):PointsMaterial {
        super.copy(source);
        color.copy(source.color);
        map = source.map;
        alphaMap = source.alphaMap;
        size = source.size;
        sizeAttenuation = source.sizeAttenuation;
        fog = source.fog;
        return this;
    }
}
```
Note that I've used the `Dynamic` type for `map` and `alphaMap` since they are not explicitly typed in the JavaScript code. If you know the specific type of these variables, you can replace `Dynamic` with the correct type.

Also, I've used the `Bool` type for `isPointsMaterial`, `sizeAttenuation`, and `fog` since they are boolean values.

The `setValues` method is not defined in the provided JavaScript code, so I assumed it's defined elsewhere in the codebase. If that's not the case, you'll need to implement it accordingly.

Finally, I've removed the `export` statement since Haxe uses a different module system. You can use the `@:expose` metadata to make the class accessible from outside the package.