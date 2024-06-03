import three.Vector2;
import three.Vector3;
import three.DirectionalLight;
import three.MathUtils;
import three.ShaderChunk;
import three.Matrix4;
import three.Box3;
import csm.CSMFrustum;
import csm.CSMShader;

class CSMData {
    public var camera: any;
    public var parent: any;
    public var cascades: Int;
    public var maxFar: Float;
    public var mode: String;
    public var shadowMapSize: Int;
    public var shadowBias: Float;
    public var lightDirection: Vector3;
    public var lightIntensity: Float;
    public var lightNear: Float;
    public var lightFar: Float;
    public var lightMargin: Float;
    public var customSplitsCallback: Dynamic;
}

class CSM {

    public var camera: any;
    public var parent: any;
    public var cascades: Int;
    public var maxFar: Float;
    public var mode: String;
    public var shadowMapSize: Int;
    public var shadowBias: Float;
    public var lightDirection: Vector3;
    public var lightIntensity: Float;
    public var lightNear: Float;
    public var lightFar: Float;
    public var lightMargin: Float;
    public var customSplitsCallback: Dynamic;
    public var fade: Bool;
    public var mainFrustum: CSMFrustum;
    public var frustums: Array<CSMFrustum>;
    public var breaks: Array<Float>;
    public var lights: Array<DirectionalLight>;
    public var shaders: Map<any, Dynamic>;

    public function new(data: CSMData) {
        this.camera = data.camera;
        this.parent = data.parent;
        this.cascades = data.cascades != null ? data.cascades : 3;
        this.maxFar = data.maxFar != null ? data.maxFar : 100000.0;
        this.mode = data.mode != null ? data.mode : 'practical';
        this.shadowMapSize = data.shadowMapSize != null ? data.shadowMapSize : 2048;
        this.shadowBias = data.shadowBias != null ? data.shadowBias : 0.000001;
        this.lightDirection = data.lightDirection != null ? data.lightDirection : new Vector3(1, -1, 1).normalize();
        this.lightIntensity = data.lightIntensity != null ? data.lightIntensity : 3.0;
        this.lightNear = data.lightNear != null ? data.lightNear : 1.0;
        this.lightFar = data.lightFar != null ? data.lightFar : 2000.0;
        this.lightMargin = data.lightMargin != null ? data.lightMargin : 200.0;
        this.customSplitsCallback = data.customSplitsCallback;
        this.fade = false;
        this.mainFrustum = new CSMFrustum();
        this.frustums = [];
        this.breaks = [];
        this.lights = [];
        this.shaders = new Map<any, Dynamic>();
        this.createLights();
        this.updateFrustums();
        this.injectInclude();
    }

    public function createLights(): Void {
        for (i in 0...this.cascades) {
            var light = new DirectionalLight(0xffffff, this.lightIntensity);
            light.castShadow = true;
            light.shadow.mapSize.width = this.shadowMapSize;
            light.shadow.mapSize.height = this.shadowMapSize;
            light.shadow.camera.near = this.lightNear;
            light.shadow.camera.far = this.lightFar;
            light.shadow.bias = this.shadowBias;
            this.parent.add(light);
            this.parent.add(light.target);
            this.lights.push(light);
        }
    }

    // Continue the conversion for other methods...
}