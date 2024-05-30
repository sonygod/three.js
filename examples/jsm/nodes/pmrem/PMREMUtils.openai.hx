package three.js.examples.jsm.nodes.pmrem;

import three.js.shadernode.ShaderNode;
import three.js.math.MathNode;
import three.js.math.OperatorNode;
import three.js.utils.LoopNode;

class PMREMUtils {
    // Defines must match with PMREMGenerator
    static inline var cubeUV_r0 = 1.0;
    static inline var cubeUV_m0 = -2.0;
    static inline var cubeUV_r1 = 0.8;
    static inline var cubeUV_m1 = -1.0;
    static inline var cubeUV_r4 = 0.4;
    static inline var cubeUV_m4 = 2.0;
    static inline var cubeUV_r5 = 0.305;
    static inline var cubeUV_m5 = 3.0;
    static inline var cubeUV_r6 = 0.21;
    static inline var cubeUV_m6 = 4.0;

    static inline var cubeUV_minMipLevel = 4.0;
    static inline var cubeUV_minTileSize = 16.0;

    // Shader functions
    static var getFace = ShaderNode.tslFn((direction) -> {
        var absDirection = MathNode.abs(direction).toVar();
        var face = ShaderNode.float(-1.0).toVar();

        If(absDirection.x > absDirection.z, () -> {
            If(absDirection.x > absDirection.y, () -> {
                face.assign(ShaderNode.cond(direction.x > 0, 0.0, 3.0));
            }).else(() -> {
                face.assign(ShaderNode.cond(direction.y > 0, 1.0, 4.0));
            });
        }).else(() -> {
            If(absDirection.z > absDirection.y, () -> {
                face.assign(ShaderNode.cond(direction.z > 0, 2.0, 5.0));
            }).else(() -> {
                face.assign(ShaderNode.cond(direction.y > 0, 1.0, 4.0));
            });
        });

        return face;
    }).setLayout({
        name: 'getFace',
        type: 'float',
        inputs: [
            { name: 'direction', type: 'vec3' }
        ]
    });

    static var getUV = ShaderNode.tslFn((direction, face) -> {
        var uv = ShaderNode.vec2().toVar();

        If(face == 0.0, () -> {
            uv.assign(MathNode.vec2(direction.z, direction.y).div(MathNode.abs(direction.x)));
        }).elseif(face == 1.0, () -> {
            uv.assign(MathNode.vec2(direction.x.negate(), direction.z.negate()).div(MathNode.abs(direction.y)));
        }).elseif(face == 2.0, () -> {
            uv.assign(MathNode.vec2(direction.x.negate(), direction.y).div(MathNode.abs(direction.z)));
        }).elseif(face == 3.0, () -> {
            uv.assign(MathNode.vec2(direction.z.negate(), direction.y).div(MathNode.abs(direction.x)));
        }).elseif(face == 4.0, () -> {
            uv.assign(MathNode.vec2(direction.x.negate(), direction.z).div(MathNode.abs(direction.y)));
        }).else(() -> {
            uv.assign(MathNode.vec2(direction.x, direction.y).div(MathNode.abs(direction.z)));
        });

        return MathNode.mul(0.5, uv.add(1.0));
    }).setLayout({
        name: 'getUV',
        type: 'vec2',
        inputs: [
            { name: 'direction', type: 'vec3' },
            { name: 'face', type: 'float' }
        ]
    });

    static var roughnessToMip = ShaderNode.tslFn((roughness) -> {
        var mip = ShaderNode.float(0.0).toVar();

        If(roughness >= cubeUV_r1, () -> {
            mip.assign(cubeUV_r0 - roughness * (cubeUV_m1 - cubeUV_m0) / (cubeUV_r0 - cubeUV_r1) + cubeUV_m0);
        }).elseif(roughness >= cubeUV_r4, () -> {
            mip.assign(cubeUV_r1 - roughness * (cubeUV_m4 - cubeUV_m1) / (cubeUV_r1 - cubeUV_r4) + cubeUV_m1);
        }).elseif(roughness >= cubeUV_r5, () -> {
            mip.assign(cubeUV_r4 - roughness * (cubeUV_m5 - cubeUV_m4) / (cubeUV_r4 - cubeUV_r5) + cubeUV_m4);
        }).elseif(roughness >= cubeUV_r6, () -> {
            mip.assign(cubeUV_r5 - roughness * (cubeUV_m6 - cubeUV_m5) / (cubeUV_r5 - cubeUV_r6) + cubeUV_m5);
        }).else(() -> {
            mip.assign(-2.0 * MathNode.log2(1.16 * roughness));
        });

        return mip;
    }).setLayout({
        name: 'roughnessToMip',
        type: 'float',
        inputs: [
            { name: 'roughness', type: 'float' }
        ]
    });

    static var getDirection = ShaderNode.tslFn((uv_immutable, face) -> {
        var uv = uv_immutable.toVar();
        uv.assign(MathNode.mul(2.0, uv).sub(1.0));
        var direction = MathNode.vec3(uv, 1.0).toVar();

        If(face == 0.0, () -> {
            direction.assign(MathNode.vec3(uv, 1.0));
        }).elseif(face == 1.0, () -> {
            direction.assign(MathNode.vec3(uv.x, -uv.y, 1.0));
        }).elseif(face == 2.0, () -> {
            direction.assign(MathNode.vec3(uv.x, 1.0, uv.y));
        }).elseif(face == 3.0, () -> {
            direction.assign(MathNode.vec3(-uv.x, uv.y, 1.0));
        }).elseif(face == 4.0, () -> {
            direction.assign(MathNode.vec3(uv.x, -1.0, uv.y));
        }).elseif(face == 5.0, () -> {
            direction.assign(MathNode.vec3(uv.x, uv.y, -1.0));
        });

        return direction;
    }).setLayout({
        name: 'getDirection',
        type: 'vec3',
        inputs: [
            { name: 'uv', type: 'vec2' },
            { name: 'face', type: 'float' }
        ]
    });

    static var textureCubeUV = ShaderNode.tslFn((envMap, sampleDir_immutable, roughness_immutable, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP) -> {
        var roughness = ShaderNode.float(roughness_immutable);
        var sampleDir = MathNode.vec3(sampleDir_immutable);

        var mip = ShaderNode.clamp(roughnessToMip(roughness), cubeUV_m0, CUBEUV_MAX_MIP);
        var mipF = MathNode.fract(mip);
        var mipInt = MathNode.floor(mip);
        var color0 = MathNode.vec3(bilinearCubeUV(envMap, sampleDir, mipInt, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP)).toVar();

        If(mipF != 0.0, () -> {
            var color1 = MathNode.vec3(bilinearCubeUV(envMap, sampleDir, mipInt + 1.0, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP)).toVar();

            color0.assign(MathNode.mix(color0, color1, mipF));
        });

        return color0;
    });

    static var bilinearCubeUV = ShaderNode.tslFn((envMap, direction_immutable, mipInt_immutable, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP) -> {
        var mipInt = ShaderNode.float(mipInt_immutable).toVar();
        var direction = MathNode.vec3(direction_immutable);
        var face = ShaderNode.float(getFace(direction)).toVar();
        var filterInt = ShaderNode.float(MathNode.max(cubeUV_minMipLevel - mipInt, 0.0)).toVar();
        mipInt.assign(MathNode.max(mipInt, cubeUV_minMipLevel));
        var faceSize = ShaderNode.float(MathNode.exp2(mipInt)).toVar();
        var uv = MathNode.vec2(getUV(direction, face).mul(faceSize - 2.0).add(1.0)).toVar();

        If(face > 2.0, () -> {
            uv.y.addAssign(faceSize);
            face.subAssign(3.0);
        });

        uv.x.addAssign(face * faceSize);
        uv.x.addAssign(filterInt * 3.0 * cubeUV_minTileSize);
        uv.y.addAssign(4.0 * (MathNode.exp2(CUBEUV_MAX_MIP) - faceSize));
        uv.x.mulAssign(CUBEUV_TEXEL_WIDTH);
        uv.y.mulAssign(CUBEUV_TEXEL_HEIGHT);

        return envMap.uv(uv);
    });

    static var getSample = ShaderNode.tslFn((envMap, mipInt, outputDirection, theta, axis, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP) -> {
        var cosTheta = MathNode.cos(theta);

        // Rodrigues' axis-angle rotation
        var sampleDirection = outputDirection.mul(cosTheta)
            .add(axis.cross(outputDirection).mul(MathNode.sin(theta)))
            .add(axis.mul(axis.dot(outputDirection) * (1.0 - cosTheta)));

        return bilinearCubeUV(envMap, sampleDirection, mipInt, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP);
    });

    static var blur = ShaderNode.tslFn((n, latitudinal, poleAxis, outputDirection, weights, samples, dTheta, mipInt, envMap, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP) -> {
        var axis = MathNode.vec3(cond(latitudinal, poleAxis, MathNode.cross(poleAxis, outputDirection))).toVar();

        If(axis.equals(MathNode.vec3(0.0)), () -> {
            axis.assign(MathNode.vec3(outputDirection.z, 0.0, -outputDirection.x));
        });

        axis.assign(MathNode.normalize(axis));

        var gl_FragColor = MathNode.vec3().toVar();
        gl_FragColor.addAssign(weights.element(0) * getSample({ theta: 0.0, axis, outputDirection, mipInt, envMap, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP }));

        LoopNode.loop({ start: 1, end: n }, (i) -> {
            If(i >= samples, () -> {
                LoopNode.Break();
            });

            var theta = MathNode.float(dTheta * i).toVar();
            gl_FragColor.addAssign(weights.element(i) * getSample({ theta: -theta, axis, outputDirection, mipInt, envMap, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP }));
            gl_FragColor.addAssign(weights.element(i) * getSample({ theta, axis, outputDirection, mipInt, envMap, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP }));
        });

        return MathNode.vec4(gl_FragColor, 1.0);
    });
}