package three.renderers.shaders.ShaderChunk;

@:glsl("normalmap_pars_fragment.glsl")
class NormalmapParsFragment {
    @ifdef(USE_NORMALMAP)
    public var normalMap:Sampler2D;
    public var normalScale:Vec2;

    @ifdef(USE_NORMALMAP_OBJECTSPACE)
    public var normalMatrix:Mat3;

    @if(!(USE_TANGENT) && (USE_NORMALMAP_TANGENTSPACE || USE_CLEARCOAT_NORMALMAP || USE_ANISOTROPY))
    public function getTangentFrame(eyePos:Vec3, surfNorm:Vec3, uv:Vec2):Mat3 {
        var q0:Vec3 = dFdx(eyePos);
        var q1:Vec3 = dFdy(eyePos);
        var st0:Vec2 = dFdx(uv);
        var st1:Vec2 = dFdy(uv);

        var N:Vec3 = surfNorm; // normalized

        var q1perp:Vec3 = cross(q1, N);
        var q0perp:Vec3 = cross(N, q0);

        var T:Vec3 = q1perp * st0.x + q0perp * st1.x;
        var B:Vec3 = q1perp * st0.y + q0perp * st1.y;

        var det:Float = Math.max(dot(T, T), dot(B, B));
        var scale:Float = (det == 0.0) ? 0.0 : 1.0 / Math.sqrt(det);

        return new Mat3(T * scale, B * scale, N);
    }
}