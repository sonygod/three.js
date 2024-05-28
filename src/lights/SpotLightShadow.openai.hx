package three.js.lights;

import three.js.lights.LightShadow;
import three.js.math.MathUtils;
import three.js.cameras.PerspectiveCamera;

class SpotLightShadow extends LightShadow {
    
    public var isSpotLightShadow:Bool;
    public var focus:Float;

    public function new() {
        super(new PerspectiveCamera(50, 1, 0.5, 500));
        this.isSpotLightShadow = true;
        this.focus = 1;
    }

    public function updateMatrices(light:Any) {
        var camera = this.camera;
        var fov = MathUtils.RAD2DEG * 2 * light.angle * this.focus;
        var aspect = this.mapSize.width / this.mapSize.height;
        var far = light.distance != null ? light.distance : camera.far;

        if (fov != camera.fov || aspect != camera.aspect || far != camera.far) {
            camera.fov = fov;
            camera.aspect = aspect;
            camera.far = far;
            camera.updateProjectionMatrix();
        }

        super.updateMatrices(light);
    }

    public function copy(source:Any) {
        super.copy(source);
        this.focus = source.focus;
        return this;
    }
}