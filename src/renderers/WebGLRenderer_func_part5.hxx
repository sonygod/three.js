class WebGLRenderer {
    // ...

    public function new() {
        // ...
    }

    public function get coordinateSystem():WebGLCoordinateSystem {
        return WebGLCoordinateSystem;
    }

    public function get outputColorSpace():OutputColorSpace {
        return this._outputColorSpace;
    }

    public function set outputColorSpace(colorSpace:OutputColorSpace):Void {
        this._outputColorSpace = colorSpace;
        var gl = this.getContext();
        gl.drawingBufferColorSpace = colorSpace == DisplayP3ColorSpace ? 'display-p3' : 'srgb';
        gl.unpackColorSpace = ColorManagement.workingColorSpace == LinearDisplayP3ColorSpace ? 'display-p3' : 'srgb';
    }

    public function get useLegacyLights():Bool {
        trace('THREE.WebGLRenderer: The property .useLegacyLights has been deprecated. Migrate your lighting according to the following guide: https://discourse.threejs.org/t/updates-to-lighting-in-three-js-r155/53733.');
        return this._useLegacyLights;
    }

    public function set useLegacyLights(value:Bool):Void {
        trace('THREE.WebGLRenderer: The property .useLegacyLights has been deprecated. Migrate your lighting according to the following guide: https://discourse.threejs.org/t/updates-to-lighting-in-three-js-r155/53733.');
        this._useLegacyLights = value;
    }

    // ...
}