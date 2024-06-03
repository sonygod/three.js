package three.js.src.renderers.shaders;

import three.js.math.Color;
import three.js.math.Vector2;
import three.js.math.Matrix3;

class UniformsLib {

    public static var common:haxe.ds.StringMap = new haxe.ds.StringMap();
    static {
        common.set("diffuse", { value: new Color( 0xffffff ) });
        common.set("opacity", { value: 1.0 });
        common.set("map", { value: null });
        common.set("mapTransform", { value: new Matrix3() });
        common.set("alphaMap", { value: null });
        common.set("alphaMapTransform", { value: new Matrix3() });
        common.set("alphaTest", { value: 0 });
    }

    public static var specularmap:haxe.ds.StringMap = new haxe.ds.StringMap();
    static {
        specularmap.set("specularMap", { value: null });
        specularmap.set("specularMapTransform", { value: new Matrix3() });
    }

    // ... continue this pattern for the rest of the properties

}