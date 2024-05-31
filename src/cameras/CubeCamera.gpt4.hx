package cameras;

import constants.WebGLCoordinateSystem;
import constants.WebGPUCoordinateSystem;
import core.Object3D;
import cameras.PerspectiveCamera;

class CubeCamera extends Object3D {

    public var renderTarget:RenderTarget;
    public var coordinateSystem:Dynamic;
    public var activeMipmapLevel:Int;

    public function new(near:Float, far:Float, renderTarget:RenderTarget) {
        super();
        this.type = "CubeCamera";

        this.renderTarget = renderTarget;
        this.coordinateSystem = null;
        this.activeMipmapLevel = 0;

        var aspect = 1.0;
        var fov = -90.0;

        var cameraPX = new PerspectiveCamera(fov, aspect, near, far);
        cameraPX.layers = this.layers;
        this.add(cameraPX);

        var cameraNX = new PerspectiveCamera(fov, aspect, near, far);
        cameraNX.layers = this.layers;
        this.add(cameraNX);

        var cameraPY = new PerspectiveCamera(fov, aspect, near, far);
        cameraPY.layers = this.layers;
        this.add(cameraPY);

        var cameraNY = new PerspectiveCamera(fov, aspect, near, far);
        cameraNY.layers = this.layers;
        this.add(cameraNY);

        var cameraPZ = new PerspectiveCamera(fov, aspect, near, far);
        cameraPZ.layers = this.layers;
        this.add(cameraPZ);

        var cameraNZ = new PerspectiveCamera(fov, aspect, near, far);
        cameraNZ.layers = this.layers;
        this.add(cameraNZ);
    }

    public function updateCoordinateSystem():Void {
        var coordinateSystem = this.coordinateSystem;
        var cameras = this.children.copy();

        var [cameraPX, cameraNX, cameraPY, cameraNY, cameraPZ, cameraNZ] = cameras;

        for (camera in cameras) this.remove(camera);

        if (coordinateSystem == WebGLCoordinateSystem) {
            // set camera orientations for WebGL coordinate system
        } else if (coordinateSystem == WebGPUCoordinateSystem) {
            // set camera orientations for WebGPU coordinate system
        } else {
            throw new Error("THREE.CubeCamera.updateCoordinateSystem(): Invalid coordinate system: " + Std.string(coordinateSystem));
        }

        for (camera in cameras) {
            this.add(camera);
            camera.updateMatrixWorld();
        }
    }

    public function update(renderer:Renderer, scene:Scene):Void {
        if (this.parent == null) this.updateMatrixWorld();

        var { renderTarget, activeMipmapLevel } = this;

        if (this.coordinateSystem != renderer.coordinateSystem) {
            this.coordinateSystem = renderer.coordinateSystem;
            this.updateCoordinateSystem();
        }

        var [cameraPX, cameraNX, cameraPY, cameraNY, cameraPZ, cameraNZ] = this.children;

        // Update render targets and render each face of the cube
        // similar to the JavaScript code

        renderTarget.texture.needsPMREMUpdate = true;
    }
}