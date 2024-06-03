import three.constants.WebGLCoordinateSystem;
import three.constants.WebGPUCoordinateSystem;
import three.core.Object3D;
import three.cameras.PerspectiveCamera;

class CubeCamera extends Object3D {
    public var renderTarget:any;
    public var coordinateSystem:String;
    public var activeMipmapLevel:Int;

    public function new(near:Float, far:Float, renderTarget:any) {
        super();
        this.type = 'CubeCamera';
        this.renderTarget = renderTarget;
        this.coordinateSystem = null;
        this.activeMipmapLevel = 0;

        var fov:Float = -90;
        var aspect:Float = 1;

        var cameraPX:PerspectiveCamera = new PerspectiveCamera(fov, aspect, near, far);
        cameraPX.layers = this.layers;
        this.add(cameraPX);

        var cameraNX:PerspectiveCamera = new PerspectiveCamera(fov, aspect, near, far);
        cameraNX.layers = this.layers;
        this.add(cameraNX);

        var cameraPY:PerspectiveCamera = new PerspectiveCamera(fov, aspect, near, far);
        cameraPY.layers = this.layers;
        this.add(cameraPY);

        var cameraNY:PerspectiveCamera = new PerspectiveCamera(fov, aspect, near, far);
        cameraNY.layers = this.layers;
        this.add(cameraNY);

        var cameraPZ:PerspectiveCamera = new PerspectiveCamera(fov, aspect, near, far);
        cameraPZ.layers = this.layers;
        this.add(cameraPZ);

        var cameraNZ:PerspectiveCamera = new PerspectiveCamera(fov, aspect, near, far);
        cameraNZ.layers = this.layers;
        this.add(cameraNZ);
    }

    public function updateCoordinateSystem():Void {
        var coordinateSystem:String = this.coordinateSystem;
        var cameras:Array<PerspectiveCamera> = this.children.concat();
        var cameraPX:PerspectiveCamera = cameras[0];
        var cameraNX:PerspectiveCamera = cameras[1];
        var cameraPY:PerspectiveCamera = cameras[2];
        var cameraNY:PerspectiveCamera = cameras[3];
        var cameraPZ:PerspectiveCamera = cameras[4];
        var cameraNZ:PerspectiveCamera = cameras[5];

        for (camera in cameras) this.remove(camera);

        if (coordinateSystem == WebGLCoordinateSystem) {
            cameraPX.up.set(0, 1, 0);
            cameraPX.lookAt(1, 0, 0);

            cameraNX.up.set(0, 1, 0);
            cameraNX.lookAt(-1, 0, 0);

            cameraPY.up.set(0, 0, -1);
            cameraPY.lookAt(0, 1, 0);

            cameraNY.up.set(0, 0, 1);
            cameraNY.lookAt(0, -1, 0);

            cameraPZ.up.set(0, 1, 0);
            cameraPZ.lookAt(0, 0, 1);

            cameraNZ.up.set(0, 1, 0);
            cameraNZ.lookAt(0, 0, -1);
        } else if (coordinateSystem == WebGPUCoordinateSystem) {
            cameraPX.up.set(0, -1, 0);
            cameraPX.lookAt(-1, 0, 0);

            cameraNX.up.set(0, -1, 0);
            cameraNX.lookAt(1, 0, 0);

            cameraPY.up.set(0, 0, 1);
            cameraPY.lookAt(0, 1, 0);

            cameraNY.up.set(0, 0, -1);
            cameraNY.lookAt(0, -1, 0);

            cameraPZ.up.set(0, -1, 0);
            cameraPZ.lookAt(0, 0, 1);

            cameraNZ.up.set(0, -1, 0);
            cameraNZ.lookAt(0, 0, -1);
        } else {
            throw new Error('THREE.CubeCamera.updateCoordinateSystem(): Invalid coordinate system: ' + coordinateSystem);
        }

        for (camera in cameras) {
            this.add(camera);
            camera.updateMatrixWorld();
        }
    }

    public function update(renderer:any, scene:any):Void {
        if (this.parent == null) this.updateMatrixWorld();

        var renderTarget:any = this.renderTarget;
        var activeMipmapLevel:Int = this.activeMipmapLevel;

        if (this.coordinateSystem != renderer.coordinateSystem) {
            this.coordinateSystem = renderer.coordinateSystem;
            this.updateCoordinateSystem();
        }

        var cameraPX:PerspectiveCamera = this.children[0] as PerspectiveCamera;
        var cameraNX:PerspectiveCamera = this.children[1] as PerspectiveCamera;
        var cameraPY:PerspectiveCamera = this.children[2] as PerspectiveCamera;
        var cameraNY:PerspectiveCamera = this.children[3] as PerspectiveCamera;
        var cameraPZ:PerspectiveCamera = this.children[4] as PerspectiveCamera;
        var cameraNZ:PerspectiveCamera = this.children[5] as PerspectiveCamera;

        var currentRenderTarget:any = renderer.getRenderTarget();
        var currentActiveCubeFace:Int = renderer.getActiveCubeFace();
        var currentActiveMipmapLevel:Int = renderer.getActiveMipmapLevel();
        var currentXrEnabled:Bool = renderer.xr.enabled;

        renderer.xr.enabled = false;

        var generateMipmaps:Bool = renderTarget.texture.generateMipmaps;
        renderTarget.texture.generateMipmaps = false;

        renderer.setRenderTarget(renderTarget, 0, activeMipmapLevel);
        renderer.render(scene, cameraPX);

        renderer.setRenderTarget(renderTarget, 1, activeMipmapLevel);
        renderer.render(scene, cameraNX);

        renderer.setRenderTarget(renderTarget, 2, activeMipmapLevel);
        renderer.render(scene, cameraPY);

        renderer.setRenderTarget(renderTarget, 3, activeMipmapLevel);
        renderer.render(scene, cameraNY);

        renderer.setRenderTarget(renderTarget, 4, activeMipmapLevel);
        renderer.render(scene, cameraPZ);

        renderTarget.texture.generateMipmaps = generateMipmaps;

        renderer.setRenderTarget(renderTarget, 5, activeMipmapLevel);
        renderer.render(scene, cameraNZ);

        renderer.setRenderTarget(currentRenderTarget, currentActiveCubeFace, currentActiveMipmapLevel);

        renderer.xr.enabled = currentXrEnabled;

        renderTarget.texture.needsPMREMUpdate = true;
    }
}