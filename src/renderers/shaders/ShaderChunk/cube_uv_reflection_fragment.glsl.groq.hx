package three.shader;

class ShaderChunk {
    static public var cubeUV_minMipLevel:Float = 4.0;
    static public var cubeUV_minTileSize:Float = 16.0;

    static public function getFace(direction:Vec3):Float {
        var absDirection:Vec3 = abs(direction);
        var face:Float = -1.0;

        if (absDirection.x > absDirection.z) {
            if (absDirection.x > absDirection.y) {
                face = direction.x > 0.0 ? 0.0 : 3.0;
            } else {
                face = direction.y > 0.0 ? 1.0 : 4.0;
            }
        } else {
            if (absDirection.z > absDirection.y) {
                face = direction.z > 0.0 ? 2.0 : 5.0;
            } else {
                face = direction.y > 0.0 ? 1.0 : 4.0;
            }
        }

        return face;
    }

    static public function getUV(direction:Vec3, face:Float):Vec2 {
        var uv:Vec2 = Vec2.zero();

        if (face == 0.0) {
            uv = new Vec2(direction.z, direction.y) / abs(direction.x); // pos x
        } else if (face == 1.0) {
            uv = new Vec2(-direction.x, -direction.z) / abs(direction.y); // pos y
        } else if (face == 2.0) {
            uv = new Vec2(-direction.x, direction.y) / abs(direction.z); // pos z
        } else if (face == 3.0) {
            uv = new Vec2(-direction.z, direction.y) / abs(direction.x); // neg x
        } else if (face == 4.0) {
            uv = new Vec2(-direction.x, direction.z) / abs(direction.y); // neg y
        } else {
            uv = new Vec2(direction.x, direction.y) / abs(direction.z); // neg z
        }

        return 0.5 * (uv + 1.0);
    }

    static public function bilinearCubeUV(envMap:Texture, direction:Vec3, mipInt:Float):Vec3 {
        var face:Float = getFace(direction);
        var filterInt:Float = Math.max(cubeUV_minMipLevel - mipInt, 0.0);
        mipInt = Math.max(mipInt, cubeUV_minMipLevel);

        var faceSize:Float = Math.exp2(mipInt);
        var uv:Vec2 = getUV(direction, face) * (faceSize - 2.0) + 1.0; // #25071

        if (face > 2.0) {
            uv.y += faceSize;
            face -= 3.0;
        }

        uv.x += face * faceSize;
        uv.x += filterInt * 3.0 * cubeUV_minTileSize;
        uv.y += 4.0 * (Math.exp2(CUBEUV_MAX_MIP) - faceSize);

        uv.x *= CUBEUV_TEXEL_WIDTH;
        uv.y *= CUBEUV_TEXEL_HEIGHT;

        #ifdef texture2DGradEXT
            return texture2DGradEXT(envMap, uv, Vec2.zero(), Vec2.zero()).rgb; // disable anisotropic filtering
        #else
            return texture2D(envMap, uv).rgb;
        #end
    }

    static public function roughnessToMip(roughness:Float):Float {
        var mip:Float = 0.0;

        if (roughness >= cubeUV_r1) {
            mip = (cubeUV_r0 - roughness) * (cubeUV_m1 - cubeUV_m0) / (cubeUV_r0 - cubeUV_r1) + cubeUV_m0;
        } else if (roughness >= cubeUV_r4) {
            mip = (cubeUV_r1 - roughness) * (cubeUV_m4 - cubeUV_m1) / (cubeUV_r1 - cubeUV_r4) + cubeUV_m1;
        } else if (roughness >= cubeUV_r5) {
            mip = (cubeUV_r4 - roughness) * (cubeUV_m5 - cubeUV_m4) / (cubeUV_r4 - cubeUV_r5) + cubeUV_m4;
        } else if (roughness >= cubeUV_r6) {
            mip = (cubeUV_r5 - roughness) * (cubeUV_m6 - cubeUV_m5) / (cubeUV_r5 - cubeUV_r6) + cubeUV_m5;
        } else {
            mip = -2.0 * Math.log(1.16 * roughness) / Math.log(2.0); // 1.16 = 1.79^0.25
        }

        return mip;
    }

    static public function textureCubeUV(envMap:Texture, sampleDir:Vec3, roughness:Float):Vec4 {
        var mip:Float = Math.clamp(roughnessToMip(roughness), cubeUV_m0, CUBEUV_MAX_MIP);
        var mipF:Float = mip - Math.floor(mip);
        var mipInt:Float = Math.floor(mip);

        var color0:Vec3 = bilinearCubeUV(envMap, sampleDir, mipInt);

        if (mipF == 0.0) {
            return new Vec4(color0, 1.0);
        } else {
            var color1:Vec3 = bilinearCubeUV(envMap, sampleDir, mipInt + 1.0);
            return new Vec4(mix(color0, color1, mipF), 1.0);
        }
    }
}