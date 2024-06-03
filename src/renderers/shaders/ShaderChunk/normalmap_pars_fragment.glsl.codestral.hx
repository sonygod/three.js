#ifdef USE_NORMALMAP

var normalMap:sampler2D;
var normalScale:Vec2;

#end

#ifdef USE_NORMALMAP_OBJECTSPACE

var normalMatrix:Mat3;

#end

#if !defined(USE_TANGENT) && (defined(USE_NORMALMAP_TANGENTSPACE) || defined(USE_CLEARCOAT_NORMALMAP) || defined(USE_ANISOTROPY))

// Normal Mapping Without Precomputed Tangents
// http://www.thetenthplanet.de/archives/1180

function getTangentFrame(eye_pos:Vec3, surf_norm:Vec3, uv:Vec2):Mat3 {

    var q0:Vec3 = dFdx(eye_pos);
    var q1:Vec3 = dFdy(eye_pos);
    var st0:Vec2 = dFdx(uv);
    var st1:Vec2 = dFdy(uv);

    var N:Vec3 = surf_norm; // normalized

    var q1perp:Vec3 = cross(q1, N);
    var q0perp:Vec3 = cross(N, q0);

    var T:Vec3 = q1perp * st0.x + q0perp * st1.x;
    var B:Vec3 = q1perp * st0.y + q0perp * st1.y;

    var det:Float = Math.max(dot(T, T), dot(B, B));
    var scale:Float = (det == 0.0) ? 0.0 : 1.0 / Math.sqrt(det);

    return new Mat3(T * scale, B * scale, N);

}

#end