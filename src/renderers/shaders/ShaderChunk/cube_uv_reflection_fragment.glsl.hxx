class ShaderChunk {
    static var cubeUV_minMipLevel:Float = 4.0;
    static var cubeUV_minTileSize:Float = 16.0;

    static function getFace(direction:Float3):Float {
        var absDirection = Math.abs(direction);
        var face:Float = -1.0;
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

    static function getUV(direction:Float3, face:Float):Float2 {
        var uv:Float2;
        if (face == 0.0) {
            uv = new Float2(direction.z, direction.y) / Math.abs(direction.x); // pos x
        } else if (face == 1.0) {
            uv = new Float2(-direction.x, -direction.z) / Math.abs(direction.y); // pos y
        } else if (face == 2.0) {
            uv = new Float2(-direction.x, direction.y) / Math.abs(direction.z); // pos z
        } else if (face == 3.0) {
            uv = new Float2(-direction.z, direction.y) / Math.abs(direction.x); // neg x
        } else if (face == 4.0) {
            uv = new Float2(-direction.x, direction.z) / Math.abs(direction.y); // neg y
        } else {
            uv = new Float2(direction.x, direction.y) / Math.abs(direction.z); // neg z
        }
        return 0.5 * (uv + 1.0);
    }

    static function bilinearCubeUV(envMap:Texture2D, direction:Float3, mipInt:Float):Float3 {
        var face = getFace(direction);
        var filterInt = Math.max(cubeUV_minMipLevel - mipInt, 0.0);
        mipInt = Math.max(mipInt, cubeUV_minMipLevel);
        var faceSize = Math.exp2(mipInt);
        var uv = getUV(direction, face) * (faceSize - 2.0) + 1.0; // #25071
        if (face > 2.0) {
            uv.y += faceSize;
            face -= 3.0;
        }
        uv.x += face * faceSize;
        uv.x += filterInt * 3.0 * cubeUV_minTileSize;
        uv.y += 4.0 * (Math.exp2(CUBEUV_MAX_MIP) - faceSize);
        uv.x *= CUBEUV_TEXEL_WIDTH;
        uv.y *= CUBEUV_TEXEL_HEIGHT;
        // Here you need to implement texture sampling
        // return texture2D(envMap, uv).rgb;
        return new Float3(0, 0, 0);
    }

    static function roughnessToMip(roughness:Float):Float {
        // Implement the conversion from roughness to mip level
        return 0.0;
    }

    static function textureCubeUV(envMap:Texture2D, sampleDir:Float3, roughness:Float):Float4 {
        var mip = Math.clamp(roughnessToMip(roughness), cubeUV_m0, CUBEUV_MAX_MIP);
        var mipF = mip % 1.0;
        var mipInt = Math.floor(mip);
        var color0 = bilinearCubeUV(envMap, sampleDir, mipInt);
        if (mipF == 0.0) {
            return new Float4(color0, 1.0);
        } else {
            var color1 = bilinearCubeUV(envMap, sampleDir, mipInt + 1.0);
            return new Float4(Math.mix(color0, color1, mipF), 1.0);
        }
    }
}