package three.renderers;

import three.core.Object3D;
import three.core.Scene;
import three.core.Camera;
import three.math.Matrix4;
import three.math.Vector3;
import three.renderers.WebGLRenderer;

class WebGLRenderer_func_part4 {
    public function new() {}

    public function renderObject(object:Object3D, scene:Scene, camera:Camera, geometry:Geometry, material:Material, group:Object3D) {
        object.onBeforeRender(this, scene, camera, geometry, material, group);

        object.modelViewMatrix.multiplyMatrices(camera.matrixWorldInverse, object.matrixWorld);
        object.normalMatrix.getNormalMatrix(object.modelViewMatrix);

        material.onBeforeRender(this, scene, camera, geometry, object, group);

        if (material.transparent && material.side == DoubleSide && !material.forceSinglePass) {
            material.side = BackSide;
            material.needsUpdate = true;
            renderBufferDirect(camera, scene, geometry, material, object, group);

            material.side = FrontSide;
            material.needsUpdate = true;
            renderBufferDirect(camera, scene, geometry, material, object, group);

            material.side = DoubleSide;
        } else {
            renderBufferDirect(camera, scene, geometry, material, object, group);
        }

        object.onAfterRender(this, scene, camera, geometry, material, group);
    }

    public function getProgram(material:Material, scene:Scene, object:Object3D) {
        // ...
    }

    public function getUniformList(materialProperties:MaterialProperties) {
        // ...
    }

    public function updateCommonMaterialProperties(material:Material, parameters:Dynamic) {
        // ...
    }

    public function setProgram(camera:Camera, scene:Scene, geometry:Geometry, material:Material, object:Object3D) {
        // ...
    }
}