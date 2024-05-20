class ShaderChunk {
    static var gradientMap:Null<Texture>;

    static function getGradientIrradiance(normal:Vec3, lightDirection:Vec3):Vec3 {
        var dotNL:Float = normal.dot(lightDirection);
        var coord:Vec2 = new Vec2(dotNL * 0.5 + 0.5, 0.0);

        if (gradientMap != null) {
            var color:Vec4 = gradientMap.getPixel(coord.x, coord.y);
            return new Vec3(color.r);
        } else {
            var fw:Vec2 = coord.fwidth() * 0.5;
            var x:Float = Math.smoothstep(0.7 - fw.x, 0.7 + fw.x, coord.x);
            return Vec3.lerp(new Vec3(0.7), new Vec3(1.0), x);
        }
    }
}