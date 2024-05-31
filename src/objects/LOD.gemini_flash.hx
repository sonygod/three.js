import three.Object3D;
import three.Vector3;

class LOD extends Object3D {

    public var levels : Array<{ distance : Float, hysteresis : Float, object : Object3D }>;
    public var autoUpdate : Bool;

    private var _currentLevel : Int;

    static var _v1 : Vector3 = new Vector3();
    static var _v2 : Vector3 = new Vector3();

    public function new() {
        super();

        this._currentLevel = 0;

        this.type = 'LOD';
        this.levels = [];
        this.autoUpdate = true;
    }

    public function copy(source:LOD,? recursive:Bool = true):LOD {
        super.copy(source, recursive);

        for (i in 0...source.levels.length) {
            var level = source.levels[i];
            this.addLevel(cast level.object.clone(), level.distance, level.hysteresis);
        }

        this.autoUpdate = source.autoUpdate;

        return this;
    }

    public function addLevel(object:Object3D, distance:Float = 0, hysteresis:Float = 0):LOD {
        distance = Math.abs(distance);

        var l:Int = 0;
        for (l in 0...levels.length) {
            if (distance < levels[l].distance) {
                break;
            }
        }

        levels.insert(l, {distance: distance, hysteresis: hysteresis, object: object});
        this.add(object);

        return this;
    }

    public function getCurrentLevel():Int {
        return _currentLevel;
    }

    public function getObjectForDistance(distance:Float):Null<Object3D> {
        if (levels.length > 0) {
            var i:Int = 1;
            var l:Int = levels.length;
            while (i < l) {
                var levelDistance = levels[i].distance;
                if (levels[i].object.visible) {
                    levelDistance -= levelDistance * levels[i].hysteresis;
                }
                if (distance < levelDistance) {
                    break;
                }
                i++;
            }
            return levels[i - 1].object;
        }
        return null;
    }

    override public function raycast(raycaster:three.Raycaster, intersects:Array<Dynamic>):Void {
        if (levels.length > 0) {
            _v1.setFromMatrixPosition(this.matrixWorld);
            var distance = raycaster.ray.origin.distanceTo(_v1);
            getObjectForDistance(distance).raycast(raycaster, intersects);
        }
    }

    public function update(camera:three.Camera):Void {
        if (levels.length > 1) {
            _v1.setFromMatrixPosition(camera.matrixWorld);
            _v2.setFromMatrixPosition(this.matrixWorld);

            var distance = _v1.distanceTo(_v2) / camera.zoom;

            levels[0].object.visible = true;

            var i:Int = 1;
            var l:Int = levels.length;

            while (i < l) {
                var levelDistance:Float = levels[i].distance;
                if (levels[i].object.visible) {
                    levelDistance -= levelDistance * levels[i].hysteresis;
                }
                if (distance >= levelDistance) {
                    levels[i - 1].object.visible = false;
                    levels[i].object.visible = true;
                } else {
                    break;
                }
                i++;
            }

            _currentLevel = i - 1;

            for (j in i...l) {
                levels[j].object.visible = false;
            }
        }
    }

    override public function toJSON(meta:Dynamic):Dynamic {
        var data = super.toJSON(meta);

        if (!this.autoUpdate) {
            data.object.autoUpdate = false;
        }

        data.object.levels = [];

        for (i in 0...this.levels.length) {
            var level = this.levels[i];
            data.object.levels.push({
                object: level.object.uuid,
                distance: level.distance,
                hysteresis: level.hysteresis
            });
        }

        return data;
    }
}