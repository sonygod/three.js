package three.shaderlib;

// Note: Haxe's shader syntax is similar to GLSL, so we can keep most of the original code
class BumpmapParsFragment {
    @:glsl
    static function dHdxy_fwd(vBumpMapUv:haxe.ds.Vector2):haxe.ds.Vector2 {
        var dSTdx = new haxe.ds.Vector2(dFdx(vBumpMapUv.x), dFdx(vBumpMapUv.y));
        var dSTdy = new haxe.ds.Vector2(dFdy(vBumpMapUv.x), dFdy(vBumpMapUv.y));

        var Hll = bumpScale * texture2D(bumpMap, vBumpMapUv).x;
        var dBx = bumpScale * texture2D(bumpMap, vBumpMapUv + dSTdx).x - Hll;
        var dBy = bumpScale * texture2D(bumpMap, vBumpMapUv + dSTdy).x - Hll;

        return new haxe.ds.Vector2(dBx, dBy);
    }

    @:glsl
    static function perturbNormalArb(surf_pos:haxe.ds.Vector3, surf_norm:haxe.ds.Vector3, dHdxy:haxe.ds.Vector2, faceDirection:Float):haxe.ds.Vector3 {
        // normalize is done to ensure that the bump map looks the same regardless of the texture's scale
        var vSigmaX = normalize(dFdx(surf_pos));
        var vSigmaY = normalize(dFdy(surf_pos));
        var vN = surf_norm; // normalized

        var R1 = cross(vSigmaY, vN);
        var R2 = cross(vN, vSigmaX);

        var fDet = dot(vSigmaX, R1) * faceDirection;

        var vGrad = sign(fDet) * (dHdxy.x * R1 + dHdxy.y * R2);
        return normalize(abs(fDet) * surf_norm - vGrad);
    }

    static var bumpMap:haxe.ds.Texture2D;
    static var bumpScale:Float;

    // Note: These uniforms are not explicitly defined in the original JavaScript code,
    // but they are implied by the usage in the shader code.
    static var vBumpMapUv:haxe.ds.Vector2;
}