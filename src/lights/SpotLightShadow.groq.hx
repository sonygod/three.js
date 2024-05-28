package three.js.src.lights;

import three.js.src.lights.LightShadow;
import three.js.src.math.MathUtils;
import three.js.src.cameras.PerspectiveCamera;

class SpotLightShadow extends LightShadow {
    public var isSpotLightShadow:Bool = true;
    public var focus:Float = 1.0;

    public function new() {
        super(new PerspectiveCamera(50, 1, 0.5, 500));
    }

    public function updateMatrices(light:Any):Void {
        var camera:PerspectiveCamera = this.camera;
        var fov:Float = MathUtils.RAD2DEG * 2 * light.angle * this.focus;
        var aspect:Float = this.mapSize.width / this.mapSize.height;
        var far:Float = light.distance != null ? light.distance : camera.far;

        if (fov != camera.fov || aspect != camera.aspect || far != camera.far) {
            camera.fov = fov;
            camera.aspect = aspect;
            camera.far = far;
            camera.updateProjectionMatrix();
        }

        super.updateMatrices(light);
    }

    public function copy(source:SpotLightShadow):SpotLightShadow {
        super.copy(source);
        this.focus = source.focus;
        return this;
    }
}