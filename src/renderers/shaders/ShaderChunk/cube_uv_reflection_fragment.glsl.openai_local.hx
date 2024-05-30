package shaders;

#if ENVMAP_TYPE_CUBE_UV

class CubeUVReflectionFragment {
    public static inline var cubeUV_minMipLevel = 4.0;
    public static inline var cubeUV_minTileSize = 16.0;

    // These shader functions convert between the UV coordinates of a single face of
    // a cubemap, the 0-5 integer index of a cube face, and the direction vector for
    // sampling a textureCube (not generally normalized).

    public static function getFace(direction:Vec3):Float {
        var absDirection = abs(direction);
        var face = -1.0;

        if (absDirection.x > absDirection.z) {
            if (absDirection.x > absDirection.y)
                face = direction.x > 0.0 ? 0.0 : 3.0;
            else
                face = direction.y > 0.0 ? 1.0 : 4.0;
        } else {
            if (absDirection.z > absDirection.y)
                face = direction.z > 0.0 ? 2.0 : 5.0;
            else
                face = direction.y > 0.0 ? 1.0 : 4.0;
        }

        return face;
    }

    // RH coordinate system; PMREM face-indexing convention
    public static function getUV(direction:Vec3, face:Float):Vec2 {
        var uv:Vec2;

        if (face == 0.0) {
            uv = direction.z, direction.y / abs(direction.x); // pos x
        } else if (face == 1.0) {
            uv = -direction.x, -direction.z / abs(direction.y); // pos y
        } else if (face == 2.0) {
            uv = -direction.x, direction.y / abs(direction.z); // pos z
        } else if (face == 3.0) {
            uv = -direction.z, direction.y / abs(direction.x); // neg x
        } else if (face == 4.0) {
            uv = -direction.x, direction.z / abs(direction.y); // neg y
        } else {
            uv = direction.x, direction.y / abs(direction.z); // neg z
        }

        return 0.5 * (uv + 1.0);
    }

    public static function bilinearCubeUV(envMap:Sampler2D, direction:Vec3, mipInt:Float):Vec3 {
        var face = getFace(direction);
        var filterInt = Math.max(cubeUV_minMipLevel - mipInt, 0.0);
        mipInt = Math.max(mipInt, cubeUV_minMipLevel);
        var faceSize = Math.pow(2, mipInt);
        var uv = getUV(direction, face) * (faceSize - 2.0) + 1.0; // #25071

        if (face > 2.0) {
            uv.y += faceSize;
            face -= 3.0;
        }

        uv.x += face * faceSize;
        uv.x += filterInt * 3.0 * cubeUV_minTileSize;
        uv.y += 4.0 * (Math.pow(2, CUBEUV_MAX_MIP) - faceSize);
        uv.x *= CUBEUV_TEXEL_WIDTH;
        uv.y *= CUBEUV_TEXEL_HEIGHT;

        #if texture2DGradEXT
            return texture2DGradEXT(envMap, uv, Vec2(0.0), Vec2(0.0)).rgb; // disable anisotropic filtering
        #else
            return texture2D(envMap, uv).rgb;
        #end
    }

    // These defines must match with PMREMGenerator
    public static inline var cubeUV_r0 = 1.0;
    public static inline var cubeUV_m0 = -2.0;
    public static inline var cubeUV_r1 = 0.8;
    public static inline var cubeUV_m1 = -1.0;
    public static inline var cubeUV_r4 = 0.4;
    public static inline var cubeUV_m4 = 2.0;
    public static inline var cubeUV_r5 = 0.305;
    public static inline var cubeUV_m5 = 3.0;
    public static inline var cubeUV_r6 = 0.21;
    public static inline var cubeUV_m6 = 4.0;

    public static function roughnessToMip(roughness:Float):Float {
        var mip = 0.0;

        if (roughness >= cubeUV_r1) {
            mip = (cubeUV_r0 - roughness) * (cubeUV_m1 - cubeUV_m0) / (cubeUV_r0 - cubeUV_r1) + cubeUV_m0;
        } else if (roughness >= cubeUV_r4) {
            mip = (cubeUV_r1 - roughness) * (cubeUV_m4 - cubeUV_m1) / (cubeUV_r1 - cubeUV_r4) + cubeUV_m1;
        } else if (roughness >= cubeUV_r5) {
            mip = (cubeUV_r4 - roughness) * (cubeUV_m5 - cubeUV_m4) / (cubeUV_r4 - cubeUV_r5) + cubeUV_m4;
        } else if (roughness >= cubeUV_r6) {
            mip = (cubeUV_r5 - roughness) * (cubeUV_m6 - cubeUV_m5) / (cubeUV_r5 - cubeUV_r6) + cubeUV_m5;
        } else {
            mip = -2.0 * Math.log2(1.16 * roughness); // 1.16 = 1.79^0.25
        }

        return mip;
    }

    public static function textureCubeUV(envMap:Sampler2D, sampleDir:Vec3, roughness:Float):Vec4 {
        var mip = Math.clamp(roughnessToMip(roughness), cubeUV_m0, CUBEUV_MAX_MIP);
        var mipF = mip - Math.floor(mip);
        var mipInt = Math.floor(mip);
        var color0 = bilinearCubeUV(envMap, sampleDir, mipInt);

        if (mipF == 0.0) {
            return Vec4(color0, 1.0);
        } else {
            var color1 = bilinearCubeUV(envMap, sampleDir, mipInt + 1.0);
            return Vec4(Math.mix(color0, color1, mipF), 1.0);
        }
    }
}

#end