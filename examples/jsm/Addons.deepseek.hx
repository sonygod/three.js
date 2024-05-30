// 默认导出
import three.WebGL from './capabilities/WebGL.js';

// 命名导出
import three.AnimationClipCreator from './animation/AnimationClipCreator.js';
import three.CCDIKSolver from './animation/CCDIKSolver.js';
// ... 其他命名导出

// 命名空间导出
import three.Curves from './curves/CurveExtras.js';
import three.NURBSUtils from './curves/NURBSUtils.js';
// ... 其他命名空间导出

// 默认导出
@:native("default") class IESSpotLight extends three.Light {
    // ...
}

// 命名导出
import three.Lensflare from './objects/Lensflare.js';
import three.MarchingCubes from './objects/MarchingCubes.js';
// ... 其他命名导出

// 命名空间导出
import three.BufferGeometryUtils from './utils/BufferGeometryUtils.js';
import three.CameraUtils from './utils/CameraUtils.js';
// ... 其他命名空间导出

// ... 其他导出