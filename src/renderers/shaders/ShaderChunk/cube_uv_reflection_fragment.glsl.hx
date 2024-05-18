package three.shaderlib;

// ShaderChunk: cube_uv_reflection_fragment.glsl

#if ENVMAP_TYPE_CUBE_UV

// Constants
@:constant var cubeUV_minMipLevel = 4.0;
@:constant var cubeUV_minTileSize = 16.0;

// Functions
function getFace(direction:Vec3):Float {
    var absDirection = new Vec3(Math.abs(direction.x), Math.abs(direction.y), Math.abs(direction.z));
    var face = -1.0;

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

function getUV(direction:Vec3, face:Float):Vec2 {
    var uv:Vec2;

    if (face == 0.0) {
        uv = new Vec2(direction.z, direction.y) / Math.abs(direction.x); // pos x
    } else if (face == 1.0) {
        uv = new Vec2(-direction.x, -direction.z) / Math.abs(direction.y); // pos y
    } else if (face == 2.0) {
        uv = new Vec2(-direction.x, direction.y) / Math.abs(direction.z); // pos z
    } else if (face == 3.0) {
        uv = new Vec2(-direction.z, direction.y) / Math.abs(direction.x); // neg x
    } else if (face == 4.0) {
        uv = new Vec2(-direction.x, direction.z) / Math.abs(direction.y); // neg y
    } else {
        uv = new Vec2(direction.x, direction.y) / Math.abs(direction.z); // neg z
    }

    return new Vec2(0.5 * (uv.x + 1.0), 0.5 * (uv.y + 1.0));
}

function bilinearCubeUV(envMap:Texture, direction:Vec3, mipInt:Float):Vec3 {
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
    return texture2DGradEXT(envMap, uv, new Vec2(0.0), new Vec2(0.0)).rgb; // disable anisotropic filtering
    #else
    return texture2D(envMap, uv).rgb;
    #end
}

// Defines
@:constant var cubeUV_r0 = 1.0;
@:constant var cubeUV_m0 = -2.0;
@:constant var cubeUV_r1 = 0.8;
@:constant var cubeUV_m1 = -1.0;
@:constant var cubeUV_r4 = 0.4;
@:constant var cubeUV_m4 = 2.0;
@:constant var cubeUV_r5 = 0.305;
@:constant var cubeUV_m5 = 3.0;
@:constant var cubeUV_r6 = 0.21;
@:constant var cubeUV_m6 = 4.0;

function roughnessToMip(roughness:Float):Float {
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
        mip = -2.0 * Math.log(1.16 * roughness) / Math.log(2); // 1.16 = 1.79^0.25
    }

    return mip;
}

function textureCubeUV(envMap:Texture, sampleDir:Vec3, roughness:Float):Vec4 {
    var mip = Math.clamp(roughnessToMip(roughness), cubeUV_m0, CUBEUV_MAX_MIP);
    var mipF = mip - Math.floor(mip);
    var mipInt = Math.floor(mip);

    var color0 = bilinearCubeUV(envMap, sampleDir, mipInt);

    if (mipF == 0.0) {
        return new Vec4(color0, 1.0);
    } else {
        var color1 = bilinearCubeUV(envMap, sampleDir, mipInt + 1.0);
        return new Vec4(mix(color0, color1, mipF), 1.0);
    }
}

#end