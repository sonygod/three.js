package three.objects;

import three.math.Vector3;
import three.core.Object3D;

class LOD extends Object3D {

    public var _currentLevel:Int = 0;

    public var levels:Array<Level> = [];

    public var autoUpdate:Bool = true;

    public function new() {
        super();
        this.type = 'LOD';
        Reflect.setField(this, "isLOD", true);
    }

    public function copy(source:LOD):LOD {
        super.copy(source, false);
        for (level in source.levels) {
            addLevel(level.object.clone(), level.distance, level.hysteresis);
        }
        autoUpdate = source.autoUpdate;
        return this;
    }

    public function addLevel(object:Object3D, ?distance:Float = 0, ?hysteresis:Float = 0):LOD {
        distance = Math.abs(distance);
        var levels = this.levels;
        var l = 0;
        while (l < levels.length && distance < levels[l].distance) {
            l++;
        }
        levels.insert(l, { distance: distance, hysteresis: hysteresis, object: object });
        add(object);
        return this;
    }

    public function getCurrentLevel():Int {
        return _currentLevel;
    }

    public function getObjectForDistance(distance:Float):Object3D {
        var levels = this.levels;
        if (levels.length > 0) {
            var i = 1;
            var l = levels.length;
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

    public function raycast(raycaster:Raycaster, intersects:Array<RaycastResult>):Void {
        var levels = this.levels;
        if (levels.length > 0) {
            var v1 = new Vector3();
            v1.setFromMatrixPosition(this.matrixWorld);
            var distance = raycaster.ray.origin.distanceTo(v1);
            getObjectForDistance(distance).raycast(raycaster, intersects);
        }
    }

    public function update(camera:Camera):Void {
        var levels = this.levels;
        if (levels.length > 1) {
            var v1 = new Vector3();
            v1.setFromMatrixPosition(camera.matrixWorld);
            var v2 = new Vector3();
            v2.setFromMatrixPosition(this.matrixWorld);
            var distance = v1.distanceTo(v2) / camera.zoom;
            levels[0].object.visible = true;
            var i = 1;
            var l = levels.length;
            while (i < l) {
                var levelDistance = levels[i].distance;
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
            while (i < l) {
                levels[i].object.visible = false;
                i++;
            }
        }
    }

    public function toJSON(meta:Object):Object {
        var data = super.toJSON(meta);
        if (!autoUpdate) data.object.autoUpdate = false;
        data.object.levels = [];
        var levels = this.levels;
        for (i in 0...levels.length) {
            var level = levels[i];
            data.object.levels.push({
                object: level.object.uuid,
                distance: level.distance,
                hysteresis: level.hysteresis
            });
        }
        return data;
    }
}

typedef Level = {
    var distance:Float;
    var hysteresis:Float;
    var object:Object3D;
}