import three.core.Object3D;
import three.math.Euler;

class Scene extends Object3D {
    public var isScene:Bool = true;
    public var type:String = "Scene";
    public var background:Dynamic = null;
    public var environment:Dynamic = null;
    public var fog:Dynamic = null;
    public var backgroundBlurriness:Float = 0;
    public var backgroundIntensity:Float = 1;
    public var backgroundRotation:Euler = new Euler();
    public var environmentIntensity:Float = 1;
    public var environmentRotation:Euler = new Euler();
    public var overrideMaterial:Dynamic = null;

    public function new() {
        super();

        if (js.Browser.window.hasOwnProperty("__THREE_DEVTOOLS__")) {
            js.Browser.window["__THREE_DEVTOOLS__"].dispatchEvent(new js.html.Event("observe", { detail: this }));
        }
    }

    public function copy(source:Scene, recursive:Bool):Scene {
        super.copy(source, recursive);

        if (source.background != null) this.background = source.background.clone();
        if (source.environment != null) this.environment = source.environment.clone();
        if (source.fog != null) this.fog = source.fog.clone();

        this.backgroundBlurriness = source.backgroundBlurriness;
        this.backgroundIntensity = source.backgroundIntensity;
        this.backgroundRotation.copy(source.backgroundRotation);

        this.environmentIntensity = source.environmentIntensity;
        this.environmentRotation.copy(source.environmentRotation);

        if (source.overrideMaterial != null) this.overrideMaterial = source.overrideMaterial.clone();

        this.matrixAutoUpdate = source.matrixAutoUpdate;

        return this;
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var data = super.toJSON(meta);

        if (this.fog != null) data.object.fog = this.fog.toJSON();

        if (this.backgroundBlurriness > 0) data.object.backgroundBlurriness = this.backgroundBlurriness;
        if (this.backgroundIntensity != 1) data.object.backgroundIntensity = this.backgroundIntensity;
        data.object.backgroundRotation = this.backgroundRotation.toArray();

        if (this.environmentIntensity != 1) data.object.environmentIntensity = this.environmentIntensity;
        data.object.environmentRotation = this.environmentRotation.toArray();

        return data;
    }
}