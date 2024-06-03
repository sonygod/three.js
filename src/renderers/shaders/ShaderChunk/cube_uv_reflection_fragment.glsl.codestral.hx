class CubeUVReflectionFragment {

    public static function getFace(direction:Float3):Float {
        var absDirection = direction.abs();
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

    public static function getUV(direction:Float3, face:Float):Float3 {
        var uv:Float3;

        if (face == 0.0) {
            uv = new Float3(direction.z, direction.y) / Math.abs(direction.x);
        } else if (face == 1.0) {
            uv = new Float3(-direction.x, -direction.z) / Math.abs(direction.y);
        } else if (face == 2.0) {
            uv = new Float3(-direction.x, direction.y) / Math.abs(direction.z);
        } else if (face == 3.0) {
            uv = new Float3(-direction.z, direction.y) / Math.abs(direction.x);
        } else if (face == 4.0) {
            uv = new Float3(-direction.x, direction.z) / Math.abs(direction.y);
        } else {
            uv = new Float3(direction.x, direction.y) / Math.abs(direction.z);
        }

        return 0.5 * (uv + 1.0);
    }

    public static function bilinearCubeUV(envMap:Texture, direction:Float3, mipInt:Float):Float3 {
        var face = getFace(direction);
        var filterInt = Math.max(4.0 - mipInt, 0.0);
        mipInt = Math.max(mipInt, 4.0);
        var faceSize = Math.pow(2, mipInt);
        var uv = getUV(direction, face) * (faceSize - 2.0) + 1.0;

        if (face > 2.0) {
            uv.y += faceSize;
            face -= 3.0;
        }

        uv.x += face * faceSize;
        uv.x += filterInt * 3.0 * 16.0;
        uv.y += 4.0 * (Math.pow(2, 8) - faceSize);
        uv.x *= CUBEUV_TEXEL_WIDTH;
        uv.y *= CUBEUV_TEXEL_HEIGHT;

        // For simplicity, we're assuming texture2D is available
        return envMap.getPixel(uv.x, uv.y); // disable anisotropic filtering
    }

    public static function roughnessToMip(roughness:Float):Float {
        var mip = 0.0;

        if (roughness >= 0.8) {
            mip = (1.0 - roughness) * (-1.0 - (-2.0)) / (1.0 - 0.8) + -2.0;
        } else if (roughness >= 0.4) {
            mip = (0.8 - roughness) * (2.0 - (-1.0)) / (0.8 - 0.4) + -1.0;
        } else if (roughness >= 0.305) {
            mip = (0.4 - roughness) * (3.0 - 2.0) / (0.4 - 0.305) + 2.0;
        } else if (roughness >= 0.21) {
            mip = (0.305 - roughness) * (4.0 - 3.0) / (0.305 - 0.21) + 3.0;
        } else {
            mip = -2.0 * Math.log2(1.16 * roughness);
        }

        return mip;
    }

    public static function textureCubeUV(envMap:Texture, sampleDir:Float3, roughness:Float):Float4 {
        var mip = Math.min(Math.max(roughnessToMip(roughness), -2.0), 8);
        var mipF = mip % 1;
        var mipInt = Math.floor(mip);
        var color0 = bilinearCubeUV(envMap, sampleDir, mipInt);

        if (mipF == 0.0) {
            return new Float4(color0, 1.0);
        } else {
            var color1 = bilinearCubeUV(envMap, sampleDir, mipInt + 1.0);
            return new Float4(color0.lerp(color1, mipF), 1.0);
        }
    }
}