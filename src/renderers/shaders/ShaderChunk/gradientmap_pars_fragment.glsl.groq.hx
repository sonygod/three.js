package three.shader;

import openfl.display3D.textures.Texture;
import openfl.display3D.Context3D;

class GradientMapParsFragment {
    #if USE_GRADIENTMAP
    public var gradientMap:Texture;
    #end

    public function getGradientIrradiance(normal:Vector3, lightDirection:Vector3):Vector3 {
        // dotNL will be from -1.0 to 1.0
        var dotNL:Float = normal.dotProduct(lightDirection);
        var coord:Vector2 = new Vector2(dotNL * 0.5 + 0.5, 0.0);

        #if USE_GRADIENTMAP
        return new Vector3(Context3D.textContent2D(gradientMap, coord).r);
        #else
        var fw:Float = fwidth(coord) * 0.5;
        return mix(new Vector3(0.7), new Vector3(1.0), smoothstep(0.7 - fw, 0.7 + fw, coord.x));
        #end
    }

    function fwidth(coord:Vector2):Float {
        // todo: implement fwidth function
        // Note: fwidth is not a built-in Haxe function, you may need to implement it yourself
        throw "fwidth function not implemented";
    }

    function smoothstep(edge0:Float, edge1:Float, x:Float):Float {
        // todo: implement smoothstep function
        // Note: smoothstep is not a built-in Haxe function, you may need to implement it yourself
        throw "smoothstep function not implemented";
    }
}