import three.math.Vector3;
import three.core.Object3D;

class LOD extends Object3D {

    var _currentLevel:Int = 0;
    var _v1:Vector3 = new Vector3();
    var _v2:Vector3 = new Vector3();
    var levels:Array<Dynamic> = [];
    var autoUpdate:Bool = true;

    public function new() {
        super();

        this.type = 'LOD';
        this.isLOD = true;
    }

    public function copy(source:LOD):LOD {
        super.copy(source, false);

        for (level in source.levels) {
            this.addLevel(level.object.clone(), level.distance, level.hysteresis);
        }

        this.autoUpdate = source.autoUpdate;

        return this;
    }

    public function addLevel(object:Object3D, distance:Float = 0, hysteresis:Float = 0):LOD {
        distance = Math.abs(distance);

        var l:Int;
        for (l in 0...this.levels.length) {
            if (distance < this.levels[l].distance) {
                break;
            }
        }

        this.levels.splice(l, 0, { distance: distance, hysteresis: hysteresis, object: object });
        this.add(object);

        return this;
    }

    public function getCurrentLevel():Int {
        return this._currentLevel;
    }

    public function getObjectForDistance(distance:Float):Object3D {
        if (this.levels.length > 0) {
            for (i in 1...this.levels.length) {
                var levelDistance = this.levels[i].distance;

                if (this.levels[i].object.visible) {
                    levelDistance -= levelDistance * this.levels[i].hysteresis;
                }

                if (distance < levelDistance) {
                    break;
                }
            }

            return this.levels[i - 1].object;
        }

        return null;
    }

    public function raycast(raycaster:Raycaster, intersects:Array<Intersection>) {
        if (this.levels.length > 0) {
            this._v1.setFromMatrixPosition(this.matrixWorld);
            var distance = raycaster.ray.origin.distanceTo(this._v1);
            this.getObjectForDistance(distance).raycast(raycaster, intersects);
        }
    }

    public function update(camera:Camera) {
        if (this.levels.length > 1) {
            this._v1.setFromMatrixPosition(camera.matrixWorld);
            this._v2.setFromMatrixPosition(this.matrixWorld);

            var distance = this._v1.distanceTo(this._v2) / camera.zoom;

            this.levels[0].object.visible = true;

            for (i in 1...this.levels.length) {
                var levelDistance = this.levels[i].distance;

                if (this.levels[i].object.visible) {
                    levelDistance -= levelDistance * this.levels[i].hysteresis;
                }

                if (distance >= levelDistance) {
                    this.levels[i - 1].object.visible = false;
                    this.levels[i].object.visible = true;
                } else {
                    break;
                }
            }

            this._currentLevel = i - 1;

            for (; i < this.levels.length; i++) {
                this.levels[i].object.visible = false;
            }
        }
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var data = super.toJSON(meta);

        if (this.autoUpdate === false) data.object.autoUpdate = false;

        data.object.levels = [];

        for (level in this.levels) {
            data.object.levels.push({
                object: level.object.uuid,
                distance: level.distance,
                hysteresis: level.hysteresis
            });
        }

        return data;
    }

}