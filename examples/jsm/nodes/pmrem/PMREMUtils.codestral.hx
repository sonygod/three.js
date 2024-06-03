import shadernode.ShaderNode;
import math.MathNode;
import math.OperatorNode;
import math.CondNode;
import utils.LoopNode;

// These defines must match with PMREMGenerator
static var cubeUV_r0 = 1.0;
static var cubeUV_m0 = -2.0;
static var cubeUV_r1 = 0.8;
static var cubeUV_m1 = -1.0;
static var cubeUV_r4 = 0.4;
static var cubeUV_m4 = 2.0;
static var cubeUV_r5 = 0.305;
static var cubeUV_m5 = 3.0;
static var cubeUV_r6 = 0.21;
static var cubeUV_m6 = 4.0;

static var cubeUV_minMipLevel = 4.0;
static var cubeUV_minTileSize = 16.0;

// These shader functions convert between the UV coordinates of a single face of
// a cubemap, the 0-5 integer index of a cube face, and the direction vector for
// sampling a textureCube (not generally normalized ).

static function getFace(direction:Array<Float>):Float {
    var absDirection = new Array<Float>(Math.abs(direction[0]), Math.abs(direction[1]), Math.abs(direction[2]));
    var face = -1.0;

    if(absDirection[0] > absDirection[2]) {
        if(absDirection[0] > absDirection[1]) {
            face = direction[0] > 0.0 ? 0.0 : 3.0;
        } else {
            face = direction[1] > 0.0 ? 1.0 : 4.0;
        }
    } else {
        if(absDirection[2] > absDirection[1]) {
            face = direction[2] > 0.0 ? 2.0 : 5.0;
        } else {
            face = direction[1] > 0.0 ? 1.0 : 4.0;
        }
    }

    return face;
}

// RH coordinate system; PMREM face-indexing convention
static function getUV(direction:Array<Float>, face:Float):Array<Float> {
    var uv = new Array<Float>(0.0, 0.0);

    if(face == 0.0) {
        uv = [direction[2] / Math.abs(direction[0]), direction[1] / Math.abs(direction[0])];
    } else if(face == 1.0) {
        uv = [-direction[0] / Math.abs(direction[1]), -direction[2] / Math.abs(direction[1])];
    } else if(face == 2.0) {
        uv = [-direction[0] / Math.abs(direction[2]), direction[1] / Math.abs(direction[2])];
    } else if(face == 3.0) {
        uv = [-direction[2] / Math.abs(direction[0]), direction[1] / Math.abs(direction[0])];
    } else if(face == 4.0) {
        uv = [-direction[0] / Math.abs(direction[1]), direction[2] / Math.abs(direction[1])];
    } else {
        uv = [direction[0] / Math.abs(direction[2]), direction[1] / Math.abs(direction[2])];
    }

    return [0.5 * (uv[0] + 1.0), 0.5 * (uv[1] + 1.0)];
}

static function roughnessToMip(roughness:Float):Float {
    var mip = 0.0;

    if(roughness >= cubeUV_r1) {
        mip = (cubeUV_r0 - roughness) * (cubeUV_m1 - cubeUV_m0) / (cubeUV_r0 - cubeUV_r1) + cubeUV_m0;
    } else if(roughness >= cubeUV_r4) {
        mip = (cubeUV_r1 - roughness) * (cubeUV_m4 - cubeUV_m1) / (cubeUV_r1 - cubeUV_r4) + cubeUV_m1;
    } else if(roughness >= cubeUV_r5) {
        mip = (cubeUV_r4 - roughness) * (cubeUV_m5 - cubeUV_m4) / (cubeUV_r4 - cubeUV_r5) + cubeUV_m4;
    } else if(roughness >= cubeUV_r6) {
        mip = (cubeUV_r5 - roughness) * (cubeUV_m6 - cubeUV_m5) / (cubeUV_r5 - cubeUV_r6) + cubeUV_m5;
    } else {
        mip = -2.0 * Math.log2(1.16 * roughness); // 1.16 = 1.79^0.25
    }

    return mip;
}

// RH coordinate system; PMREM face-indexing convention
static function getDirection(uv:Array<Float>, face:Float):Array<Float> {
    uv = [2.0 * uv[0] - 1.0, 2.0 * uv[1] - 1.0];
    var direction = [uv[0], uv[1], 1.0];

    if(face == 0.0) {
        direction = [direction[2], direction[1], direction[0]]; // ( 1, v, u ) pos x
    } else if(face == 1.0) {
        direction = [direction[0], direction[2], direction[1]];
        direction[0] *= -1.0; direction[2] *= -1.0; // ( -u, 1, -v ) pos y
    } else if(face == 2.0) {
        direction[0] *= -1.0; // ( -u, v, 1 ) pos z
    } else if(face == 3.0) {
        direction = [direction[2], direction[1], direction[0]];
        direction[0] *= -1.0; direction[2] *= -1.0; // ( -1, v, -u ) neg x
    } else if(face == 4.0) {
        direction = [direction[0], direction[2], direction[1]];
        direction[0] *= -1.0; direction[1] *= -1.0; // ( -u, -1, v ) neg y
    } else if(face == 5.0) {
        direction[2] *= -1.0; // ( u, v, -1 ) neg zS
    }

    return direction;
}

//

static function textureCubeUV(envMap:Dynamic, sampleDir:Array<Float>, roughness:Float, CUBEUV_TEXEL_WIDTH:Float, CUBEUV_TEXEL_HEIGHT:Float, CUBEUV_MAX_MIP:Float):Array<Float> {
    var mip = Math.min(Math.max(roughnessToMip(roughness), cubeUV_m0), CUBEUV_MAX_MIP);
    var mipF = mip % 1.0;
    var mipInt = Math.floor(mip);
    var color0 = bilinearCubeUV(envMap, sampleDir, mipInt, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP);

    if(mipF != 0.0) {
        var color1 = bilinearCubeUV(envMap, sampleDir, mipInt + 1.0, CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP);

        color0 = [color0[0] * (1.0 - mipF) + color1[0] * mipF, color0[1] * (1.0 - mipF) + color1[1] * mipF, color0[2] * (1.0 - mipF) + color1[2] * mipF];
    }

    return color0;
}

static function bilinearCubeUV(envMap:Dynamic, direction:Array<Float>, mipInt:Float, CUBEUV_TEXEL_WIDTH:Float, CUBEUV_TEXEL_HEIGHT:Float, CUBEUV_MAX_MIP:Float):Array<Float> {
    var filterInt = Math.max(cubeUV_minMipLevel - mipInt, 0.0);
    mipInt = Math.max(mipInt, cubeUV_minMipLevel);
    var faceSize = Math.pow(2.0, mipInt);
    var uv = getUV(direction, getFace(direction));
    uv = [uv[0] * (faceSize - 2.0) + 1.0, uv[1] * (faceSize - 2.0) + 1.0];

    if(getFace(direction) > 2.0) {
        uv[1] += faceSize;
        getFace(direction) -= 3.0;
    }

    uv[0] += getFace(direction) * faceSize;
    uv[0] += filterInt * 3.0 * cubeUV_minTileSize;
    uv[1] += 4.0 * (Math.pow(2.0, CUBEUV_MAX_MIP) - faceSize);
    uv[0] *= CUBEUV_TEXEL_WIDTH;
    uv[1] *= CUBEUV_TEXEL_HEIGHT;

    return envMap.uv(uv); // disable anisotropic filtering
}

static function getSample(params:Dynamic):Array<Float> {
    var cosTheta = Math.cos(params.theta);

    // Rodrigues' axis-angle rotation
    var sampleDirection = [
        params.outputDirection[0] * cosTheta + (params.axis[1] * params.outputDirection[2] - params.axis[2] * params.outputDirection[1]) * Math.sin(params.theta) + params.axis[0] * params.axis.dot(params.outputDirection) * (1.0 - cosTheta),
        params.outputDirection[1] * cosTheta + (params.axis[2] * params.outputDirection[0] - params.axis[0] * params.outputDirection[2]) * Math.sin(params.theta) + params.axis[1] * params.axis.dot(params.outputDirection) * (1.0 - cosTheta),
        params.outputDirection[2] * cosTheta + (params.axis[0] * params.outputDirection[1] - params.axis[1] * params.outputDirection[0]) * Math.sin(params.theta) + params.axis[2] * params.axis.dot(params.outputDirection) * (1.0 - cosTheta)
    ];

    return bilinearCubeUV(params.envMap, sampleDirection, params.mipInt, params.CUBEUV_TEXEL_WIDTH, params.CUBEUV_TEXEL_HEIGHT, params.CUBEUV_MAX_MIP);
}

static function blur(params:Dynamic):Array<Float> {
    var axis = params.latitudinal ? params.poleAxis : [
        params.poleAxis[1] * params.outputDirection[2] - params.poleAxis[2] * params.outputDirection[1],
        params.poleAxis[2] * params.outputDirection[0] - params.poleAxis[0] * params.outputDirection[2],
        params.poleAxis[0] * params.outputDirection[1] - params.poleAxis[1] * params.outputDirection[0]
    ];

    if(axis[0] == 0.0 && axis[1] == 0.0 && axis[2] == 0.0) {
        axis = [params.outputDirection[2], 0.0, -params.outputDirection[0]];
    }

    var length = Math.sqrt(axis[0] * axis[0] + axis[1] * axis[1] + axis[2] * axis[2]);
    axis = [axis[0] / length, axis[1] / length, axis[2] / length];

    var gl_FragColor = [0.0, 0.0, 0.0];
    var sampleColor = getSample({theta: 0.0, axis: axis, outputDirection: params.outputDirection, mipInt: params.mipInt, envMap: params.envMap, CUBEUV_TEXEL_WIDTH: params.CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT: params.CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP: params.CUBEUV_MAX_MIP});
    gl_FragColor = [gl_FragColor[0] + params.weights[0] * sampleColor[0], gl_FragColor[1] + params.weights[0] * sampleColor[1], gl_FragColor[2] + params.weights[0] * sampleColor[2]];

    for(var i = 1; i <= params.n; i++) {
        if(i >= params.samples) {
            break;
        }

        var theta = params.dTheta * i;
        sampleColor = getSample({theta: -theta, axis: axis, outputDirection: params.outputDirection, mipInt: params.mipInt, envMap: params.envMap, CUBEUV_TEXEL_WIDTH: params.CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT: params.CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP: params.CUBEUV_MAX_MIP});
        gl_FragColor = [gl_FragColor[0] + params.weights[i] * sampleColor[0], gl_FragColor[1] + params.weights[i] * sampleColor[1], gl_FragColor[2] + params.weights[i] * sampleColor[2]];

        sampleColor = getSample({theta: theta, axis: axis, outputDirection: params.outputDirection, mipInt: params.mipInt, envMap: params.envMap, CUBEUV_TEXEL_WIDTH: params.CUBEUV_TEXEL_WIDTH, CUBEUV_TEXEL_HEIGHT: params.CUBEUV_TEXEL_HEIGHT, CUBEUV_MAX_MIP: params.CUBEUV_MAX_MIP});
        gl_FragColor = [gl_FragColor[0] + params.weights[i] * sampleColor[0], gl_FragColor[1] + params.weights[i] * sampleColor[1], gl_FragColor[2] + params.weights[i] * sampleColor[2]];
    }

    return [gl_FragColor[0], gl_FragColor[1], gl_FragColor[2], 1.0];
}