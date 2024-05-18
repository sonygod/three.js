package three.cameras;

import three.constants.WebGLCoordinateSystem;
import three.constants.WebGPUCoordinateSystem;
import three.core.Object3D;
import three.cameras.PerspectiveCamera;

class CubeCamera extends Object3D {
    public var type:String = 'CubeCamera';
    public var renderTarget:Dynamic;
    public var coordinateSystem:Null<Int>;
    public var activeMipmapLevel:Int = 0;

    public function new(near:Float, far:Float, renderTarget:Dynamic) {
        super();
        this.renderTarget = renderTarget;
        this.coordinateSystem = null;
        this.activeMipmapLevel = 0;

        var cameraPX = new PerspectiveCamera(-90, 1, near, far);
        cameraPX.layers = this.layers;
        this.add(cameraPX);

        var cameraNX = new PerspectiveCamera(-90, 1, near, far);
        cameraNX.layers = this.layers;
        this.add(cameraNX);

        var cameraPY = new PerspectiveCamera(-90, 1, near, far);
        cameraPY.layers = this.layers;
        this.add(cameraPY);

        var cameraNY = new PerspectiveCamera(-90, 1, near, far);
        cameraNY.layers = this.layers;
        this.add(cameraNY);

        var cameraPZ = new PerspectiveCamera(-90, 1, near, far);
        cameraPZ.layers = this.layers;
        this.add(cameraPZ);

        var cameraNZ = new PerspectiveCamera(-90, 1, near, far);
        cameraNZ.layers = this.layers;
        this.add(cameraNZ);
    }

    public function updateCoordinateSystem():Void {
        var coordinateSystem:Int = this.coordinateSystem;
        var cameras:Array<PerspectiveCamera> = this.children.copy();

        for (camera in cameras) this.remove(camera);

        if (coordinateSystem == WebGLCoordinateSystem) {
            cameras[0].up.set(0, 1, 0);
            cameras[0].lookAt(1, 0, 0);

            cameras[1].up.set(0, 1, 0);
            cameras[1].lookAt(-1, 0, 0);

            cameras[2].up.set(0, 0, -1);
            cameras[2].lookAt(0, 1, 0);

            cameras[3].up.set(0, 0, 1);
            cameras[3].lookAt(0, -1, 0);

            cameras[4].up.set(0, 1, 0);
            cameras[4].lookAt(0, 0, 1);

            cameras[5].up.set(0, 1, 0);
            cameras[5].lookAt(0, 0, -1);
        } else if (coordinateSystem == WebGPUCoordinateSystem) {
            cameras[0].up.set(0, -1, 0);
            cameras[0].lookAt(-1, 0, 0);

            cameras[1].up.set(0, -1, 0);
            cameras[1].lookAt(1, 0, 0);

            cameras[2].up.set(0, 0, 1);
            cameras[2].lookAt(0, 1, 0);

            cameras[3].up.set(0, 0, -1);
            cameras[3].lookAt(0, -1, 0);

            cameras[4].up.set(0, -1, 0);
            cameras[4].lookAt(0, 0, 1);

            cameras[5].up.set(0, -1, 0);
            cameras[5].lookAt(0, 0, -1);
        } else {
            throw new Error('THREE.CubeCamera.updateCoordinateSystem(): Invalid coordinate system: ' + coordinateSystem);
        }

        for (camera in cameras) {
            this.add(camera);
            camera.updateMatrixWorld();
        }
    }

    public function update(renderer:Dynamic, scene:Dynamic):Void {
        if (this.parent == null) this.updateMatrixWorld();

        var { renderTarget, activeMipmapLevel } = this;

        if (this.coordinateSystem != renderer.coordinateSystem) {
            this.coordinateSystem = renderer.coordinateSystem;
            this.updateCoordinateSystem();
        }

        var cameras:Array<PerspectiveCamera> = this.children.copy();

        var currentRenderTarget:Dynamic = renderer.getRenderTarget();
        var currentActiveCubeFace:Int = renderer.getActiveCubeFace();
        var currentActiveMipmapLevel:Int = renderer.getActiveMipmapLevel();

        var currentXrEnabled:Bool = renderer.xr.enabled;

        renderer.xr.enabled = false;

        var generateMipmaps:Bool = renderTarget.texture.generateMipmaps;

        renderTarget.texture.generateMipmaps = false;

        renderer.setRenderTarget(renderTarget, 0, activeMipmapLevel);
        renderer.render(scene, cameras[0]);

        renderer.setRenderTarget(renderTarget, 1, activeMipmapLevel);
        renderer.render(scene, cameras[1]);

        renderer.setRenderTarget(renderTarget, 2, activeMipmapLevel);
        renderer.render(scene, cameras[2]);

        renderer.setRenderTarget(renderTarget, 3, activeMipmapLevel);
        renderer.render(scene, cameras[3]);

        renderer.setRenderTarget(renderTarget, 4, activeMipmapLevel);
        renderer.render(scene, cameras[4]);

        // mipmaps are generated during the last call of render()
        // at this point, all sides of the cube render target are defined

        renderTarget.texture.generateMipmaps = generateMipmaps;

        renderer.setRenderTarget(renderTarget, 5, activeMipmapLevel);
        renderer.render(scene, cameras[5]);

        renderer.setRenderTarget(currentRenderTarget, currentActiveCubeFace, currentActiveMipmapLevel);

        renderer.xr.enabled = currentXrEnabled;

        renderTarget.texture.needsPMREMUpdate = true;
    }
}