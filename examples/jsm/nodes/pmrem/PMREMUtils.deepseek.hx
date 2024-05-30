package three.js.examples.jsm.nodes.pmrem;

import three.js.examples.jsm.shadernode.ShaderNode;
import three.js.examples.jsm.math.MathNode;
import three.js.examples.jsm.math.OperatorNode;
import three.js.examples.jsm.math.CondNode;
import three.js.examples.jsm.utils.LoopNode;

class PMREMUtils {

    static var cubeUV_r0:Float = 1.0;
    static var cubeUV_m0:Float = -2.0;
    static var cubeUV_r1:Float = 0.8;
    static var cubeUV_m1:Float = -1.0;
    static var cubeUV_r4:Float = 0.4;
    static var cubeUV_m4:Float = 2.0;
    static var cubeUV_r5:Float = 0.305;
    static var cubeUV_m5:Float = 3.0;
    static var cubeUV_r6:Float = 0.21;
    static var cubeUV_m6:Float = 4.0;

    static var cubeUV_minMipLevel:Float = 4.0;
    static var cubeUV_minTileSize:Float = 16.0;

    static function getFace(direction:Vec3):Float {
        var absDirection:Vec3 = Vec3.abs(direction);
        var face:Float = -1.0;

        if (absDirection.x > absDirection.z) {
            if (absDirection.x > absDirection.y) {
                face = CondNode.cond(direction.x > 0.0, 0.0, 3.0);
            } else {
                face = CondNode.cond(direction.y > 0.0, 1.0, 4.0);
            }
        } else {
            if (absDirection.z > absDirection.y) {
                face = CondNode.cond(direction.z > 0.0, 2.0, 5.0);
            } else {
                face = CondNode.cond(direction.y > 0.0, 1.0, 4.0);
            }
        }

        return face;
    }

    static function getUV(direction:Vec3, face:Float):Vec2 {
        var uv:Vec2 = new Vec2();

        if (face == 0.0) {
            uv = Vec2.div(new Vec2(direction.z, direction.y), MathNode.abs(direction.x));
        } else if (face == 1.0) {
            uv = Vec2.div(new Vec2(-direction.x, -direction.z), MathNode.abs(direction.y));
        } else if (face == 2.0) {
            uv = Vec2.div(new Vec2(-direction.x, direction.y), MathNode.abs(direction.z));
        } else if (face == 3.0) {
            uv = Vec2.div(new Vec2(-direction.z, direction.y), MathNode.abs(direction.x));
        } else if (face == 4.0) {
            uv = Vec2.div(new Vec2(-direction.x, direction.z), MathNode.abs(direction.y));
        } else {
            uv = Vec2.div(new Vec2(direction.x, direction.y), MathNode.abs(direction.z));
        }

        return OperatorNode.mul(0.5, Vec2.add(uv, new Vec2(1.0)));
    }

    static function roughnessToMip(roughness:Float):Float {
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
            mip = -2.0 * MathNode.log2(1.16 * roughness);
        }

        return MathNode.clamp(mip, cubeUV_m0, CUBEUV_MAX_MIP);
    }

    static function getDirection(uv:Vec2, face:Float):Vec3 {
        uv = Vec2.mul(2.0, uv).sub(1.0);
        var direction:Vec3 = new Vec3(uv.x, uv.y, 1.0);

        if (face == 0.0) {
            direction = new Vec3(direction.z, direction.y, direction.x);
        } else if (face == 1.0) {
            direction = new Vec3(-direction.x, 1.0, -direction.z);
        } else if (face == 2.0) {
            direction.x = -direction.x;
        } else if (face == 3.0) {
            direction = new Vec3(-direction.z, direction.y, -direction.x);
        } else if (face == 4.0) {
            direction = new Vec3(-direction.x, -1.0, direction.z);
        } else if (face == 5.0) {
            direction.z = -direction.z;
        }

        return direction;
    }

    static function textureCubeUV(envMap:TextureCube, sampleDir:Vec3, roughness:Float, CUBEUV_TEXEL_WIDTH:Float, CUBEUV_TEXEL_HEIGHT:Float, CUBEUV_MAX_MIP:Float):Vec3 {
        var mip:Float = roughnessToMip(roughness);
        var mipF:Float = MathNode.fract(mip);
        var mipInt:Float = MathNode.floor(mip);
        var color0:Vec3 = bilinearCubeUV(envMap, sampleDir, mipInt, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP);

        if (mipF != 0.0) {
            var color1:Vec3 = bilinearCubeUV(envMap, sampleDir, mipInt + 1.0, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP);
            color0 = OperatorNode.mix(color0, color1, mipF);
        }

        return color0;
    }

    static function bilinearCubeUV(envMap:TextureCube, direction:Vec3, mipInt:Float, CUBEUV_TEXEL_WIDTH:Float, CUBEUV_TEXEL_HEIGHT:Float, CUBEUV_MAX_MIP:Float):Vec3 {
        mipInt = MathNode.max(mipInt, cubeUV_minMipLevel);
        var faceSize:Float = MathNode.exp2(mipInt);
        var uv:Vec2 = getUV(direction, getFace(direction));
        uv = Vec2.mul(uv, faceSize - 2.0).add(new Vec2(1.0));

        if (getFace(direction) > 2.0) {
            uv.y += faceSize;
        }

        uv.x += getFace(direction) * faceSize;
        uv.x += MathNode.max(cubeUV_minMipLevel - mipInt, 0.0) * 3.0 * cubeUV_minTileSize;
        uv.y += 4.0 * (MathNode.exp2(CUBEUV_MAX_MIP) - faceSize);
        uv = Vec2.mul(uv, new Vec2(CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT));

        return envMap.uv(uv).grad(new Vec2(), new Vec2());
    }

    static function getSample(envMap:TextureCube, mipInt:Float, outputDirection:Vec3, theta:Float, axis:Vec3, CUBEUV_TEXEL_WIDTH:Float, CUBEUV_TEXEL_HEIGHT:Float, CUBEUV_MAX_MIP:Float):Vec3 {
        var cosTheta:Float = MathNode.cos(theta);
        var sampleDirection:Vec3 = outputDirection.mul(cosTheta).add(axis.cross(outputDirection).mul(MathNode.sin(theta))).add(axis.mul(axis.dot(outputDirection).mul(cosTheta.oneMinus())));

        return bilinearCubeUV(envMap, sampleDirection, mipInt, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP);
    }

    static function blur(n:Int, latitudinal:Bool, poleAxis:Vec3, outputDirection:Vec3, weights:Array<Float>, samples:Int, dTheta:Float, mipInt:Float, envMap:TextureCube, CUBEUV_TEXEL_WIDTH:Float, CUBEUV_TEXEL_HEIGHT:Float, CUBEUV_MAX_MIP:Float):Vec4 {
        var axis:Vec3 = latitudinal ? poleAxis : Vec3.cross(poleAxis, outputDirection);

        if (axis.equals(new Vec3())) {
            axis = new Vec3(outputDirection.z, 0.0, -outputDirection.x);
        }

        axis = Vec3.normalize(axis);
        var gl_FragColor:Vec3 = weights[0] * getSample(envMap, mipInt, outputDirection, 0.0, axis, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP);

        for (i in LoopNode.loop(0, n)) {
            if (i >= samples) {
                LoopNode.Break();
            }

            var theta:Float = dTheta * i;
            gl_FragColor += weights[i] * getSample(envMap, mipInt, outputDirection, -theta, axis, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP);
            gl_FragColor += weights[i] * getSample(envMap, mipInt, outputDirection, theta, axis, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP);
        }

        return new Vec4(gl_FragColor, 1.0);
    }
}