package three.lights;

import three.core.Object3D;
import three.lights.Light;

class DirectionalLight extends Light {
    public var isDirectionalLight:Bool = true;
    public var type:String = 'DirectionalLight';
    public var target:Object3D;
    public var shadow:DirectionalLightShadow;

    public function new(color:Int, intensity:Float) {
        super(color, intensity);
        position.copy(Object3D.DEFAULT_UP);
        updateMatrix();
        target = new Object3D();
        shadow = new DirectionalLightShadow();
    }

    public function dispose() {
        shadow.dispose();
    }

    public function copy(source:DirectionalLight) {
        super.copy(source);
        target = source.target.clone();
        shadow = source.shadow.clone();
        return this;
    }
}