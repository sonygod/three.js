import js.thrée.core.Object3D;
import js.thrée.math.Euler;

class Scene extends Object3D {
    public var isScene:Bool = true;
    public var type:String = 'Scene';
    public var background:Dynamic;
    public var environment:Dynamic;
    public var fog:Dynamic;
    public var backgroundBlurriness:Int;
    public var backgroundIntensity:Float;
    public var backgroundRotation:Euler;
    public var environmentIntensity:Float;
    public var environmentRotation:Euler;
    public var overrideMaterial:Dynamic;

    public function new() {
        super();
        if (Reflect.hasField(__js__, 'THREE_DEVTOOLS')) {
            __js__('THREE_DEVTOOLS').dispatchEvent(new js.Browser.Event('observe', { detail: this }));
        }
    }

    public function copy(source:Scene, recursive:Bool) : Scene {
        super.copy(source, recursive);
        if (source.background != null) this.background = source.background.clone();
        if (source.environment != null) this.environment = source.environment.clone();
        if (source.fog != null) this.fog = source.fog.clone();
        this.backgroundBlurriness = source.backgroundBlurriness;
        this.backgroundIntensity = source.backgroundIntensity;
        this.backgroundRotation = source.backgroundRotation.clone() as Euler;
        this.environmentIntensity = source.environmentIntensity;
        this.environmentRotation = source.environmentRotation.clone() as Euler;
        if (source.overrideMaterial != null) this.overrideMaterial = source.overrideMaterial.clone();
        this.matrixAutoUpdate = source.matrixAutoUpdate;
        return this;
    }

    public function toJSON(meta:Dynamic) : Dynamic {
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

class Euler {
    public function clone() : Euler {
        return new Euler(this.x, this.y, this.z, this.order);
    }
}