package three.shader;

class GradientMapParsFragment {

    #if USE_GRADIENTMAP

    public var gradientMap:Texture;

    #end

    public function getGradientIrradiance(normal:Vec3, lightDirection:Vec3):Vec3 {
        // dotNL will be from -1.0 to 1.0
        var dotNL:Float = normal.dot(lightDirection);
        var coord:Vec2 = new Vec2(dotNL * 0.5 + 0.5, 0.0);

        #if USE_GRADIENTMAP

        return new Vec3(texture2D(gradientMap, coord).r, 0, 0);

        #else

        var fw:Vec2 = new Vec2(fwidth(coord) * 0.5);
        return mix(new Vec3(0.7, 0.7, 0.7), new Vec3(1.0, 1.0, 1.0), smoothstep(0.7 - fw.x, 0.7 + fw.x, coord.x));

        #end
    }

}