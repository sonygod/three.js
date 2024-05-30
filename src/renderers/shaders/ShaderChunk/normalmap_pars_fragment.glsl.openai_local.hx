// File path: three.js/src/renderers/shaders/ShaderChunk/normalmap_pars_fragment.glsl.hx

@:glsl
class NormalMapParsFragment {
    #if USE_NORMALMAP
    @:glsl
    uniform var normalMap:Sampler2D;
    @:glsl
    uniform var normalScale:Vec2;
    #end

    #if USE_NORMALMAP_OBJECTSPACE
    @:glsl
    uniform var normalMatrix:Mat3;
    #end

    #if !defined(USE_TANGENT) && (defined(USE_NORMALMAP_TANGENTSPACE) || defined(USE_CLEARCOAT_NORMALMAP) || defined(USE_ANISOTROPY))
    // Normal Mapping Without Precomputed Tangents
    // http://www.thetenthplanet.de/archives/1180

    @:glsl
    function getTangentFrame(eye_pos:Vec3, surf_norm:Vec3, uv:Vec2):Mat3 {
        var q0:Vec3 = dFdx(eye_pos.xyz);
        var q1:Vec3 = dFdy(eye_pos.xyz);
        var st0:Vec2 = dFdx(uv.st);
        var st1:Vec2 = dFdy(uv.st);

        var N:Vec3 = surf_norm; // normalized

        var q1perp:Vec3 = cross(q1, N);
        var q0perp:Vec3 = cross(N, q0);

        var T:Vec3 = q1perp * st0.x + q0perp * st1.x;
        var B:Vec3 = q1perp * st0.y + q0perp * st1.y;

        var det:Float = max(dot(T, T), dot(B, B));
        var scale:Float = (det == 0.0) ? 0.0 : inversesqrt(det);

        return mat3(T * scale, B * scale, N);
    }
    #end
}