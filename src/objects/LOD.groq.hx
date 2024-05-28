Here is the converted Haxe code:
```
package three.objects;

import three.math.Vector3;
import three.core.Object3D;

class LOD extends Object3D {
    var _currentLevel:Int = 0;

    public var levels:Array<Dynamic> = [];

    public var autoUpdate:Bool = true;

    public function new() {
        super();
        this.type = 'LOD';
        untyped __defineGetter__(this, 'levels', function() return levels);
        untyped __defineGetter__(this, 'isLOD', function() return true);
    }

    public function copy(source:LOD):LOD {
        super.copy(source, false);
        for (level in source.levels) {
            addLevel(level.object.clone(), level.distance, level.hysteresis);
        }
        autoUpdate = source.autoUpdate;
        return this;
    }

    public function addLevel(object:Object3D, distance:Float = 0, hysteresis:Float = 0):LOD {
        distance = Math.abs(distance);
        var levels:Array<Dynamic> = this.levels;
        var l:Int = 0;
        for (l in 0...levels.length) {
            if (distance < levels[l].distance) {
                break;
            }
        }
        levels.insert(l, { distance: distance, hysteresis: hysteresis, object: object });
        add(object);
        return this;
    }

    public function getCurrentLevel():Int {
        return _currentLevel;
    }

    public function getObjectForDistance(distance:Float):Object3D {
        var levels:Array<Dynamic> = this.levels;
        if (levels.length > 0) {
            var i:Int = 1;
            var l:Int = levels.length;
            for (i in 1...l) {
                var levelDistance:Float = levels[i].distance;
                if (levels[i].object.visible) {
                    levelDistance -= levelDistance * levels[i].hysteresis;
                }
                if (distance < levelDistance) {
                    break;
                }
            }
            return levels[i - 1].object;
        }
        return null;
    }

    public function raycast(raycaster:Dynamic, intersects:Array<Dynamic>):Void {
        var levels:Array<Dynamic> = this.levels;
        if (levels.length > 0) {
            var v1:Vector3 = new Vector3();
            v1.setFromMatrixPosition(matrixWorld);
            var distance:Float = raycaster.ray.origin.distanceTo(v1);
            getObjectForDistance(distance).raycast(raycaster, intersects);
        }
    }

    public function update(camera:Object3D):Void {
        var levels:Array<Dynamic> = this.levels;
        if (levels.length > 1) {
            var v1:Vector3 = new Vector3();
            v1.setFromMatrixPosition(camera.matrixWorld);
            var v2:Vector3 = new Vector3();
            v2.setFromMatrixPosition(matrixWorld);
            var distance:Float = v1.distanceTo(v2) / camera.zoom;
            levels[0].object.visible = true;
            var i:Int = 1;
            var l:Int = levels.length;
            for (i in 1...l) {
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
            }
            _currentLevel = i - 1;
            for (i in i...l) {
                levels[i].object.visible = false;
            }
        }
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var data:Dynamic = super.toJSON(meta);
        if (!autoUpdate) data.object.autoUpdate = false;
        data.object.levels = [];
        var levels:Array<Dynamic> = this.levels;
        for (i in 0...levels.length) {
            var level:Dynamic = levels[i];
            data.object.levels.push({
                object: level.object.uuid,
                distance: level.distance,
                hysteresis: level.hysteresis
            });
        }
        return data;
    }
}
```
Note that I had to make some assumptions about the Haxe types and syntax, as Haxe is a statically-typed language and the original JavaScript code is dynamically-typed. I also had to remove the `/*@__PURE__*/` annotations, as they are not valid in Haxe.