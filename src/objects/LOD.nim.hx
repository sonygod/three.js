import Vector3 from '../math/Vector3';
import Object3D from '../core/Object3D';

class LOD extends Object3D {
    private var _currentLevel:Int;
    private var levels:Array<Dynamic>;
    private var isLOD:Bool;

    public function new() {
        super();

        this._currentLevel = 0;

        this.type = 'LOD';

        this.levels = [];
        this.isLOD = true;

        this.autoUpdate = true;
    }

    public function copy(source:LOD):LOD {
        super.copy(source, false);

        const levels = source.levels;

        for (i in 0...levels.length) {
            const level = levels[i];

            this.addLevel(level.object.clone(), level.distance, level.hysteresis);
        }

        this.autoUpdate = source.autoUpdate;

        return this;
    }

    public function addLevel(object:Dynamic, distance:Float = 0, hysteresis:Float = 0):LOD {
        distance = Math.abs(distance);

        const levels = this.levels;

        var l:Int;

        for (l in 0...levels.length) {
            if (distance < levels[l].distance) {
                break;
            }
        }

        levels.splice(l, 0, { distance: distance, hysteresis: hysteresis, object: object });

        this.add(object);

        return this;
    }

    public function getCurrentLevel():Int {
        return this._currentLevel;
    }

    public function getObjectForDistance(distance:Float):Dynamic {
        const levels = this.levels;

        if (levels.length > 0) {
            var i:Int, l:Int;

            for (i = 1, l = levels.length; i < l; i++) {
                let levelDistance = levels[i].distance;

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

    public function raycast(raycaster:Dynamic, intersects:Dynamic):Void {
        const levels = this.levels;

        if (levels.length > 0) {
            var v1:Vector3 = new Vector3();
            v1.setFromMatrixPosition(this.matrixWorld);

            const distance = raycaster.ray.origin.distanceTo(v1);

            this.getObjectForDistance(distance).raycast(raycaster, intersects);
        }
    }

    public function update(camera:Dynamic):Void {
        const levels = this.levels;

        if (levels.length > 1) {
            var v1:Vector3 = new Vector3();
            v1.setFromMatrixPosition(camera.matrixWorld);
            var v2:Vector3 = new Vector3();
            v2.setFromMatrixPosition(this.matrixWorld);

            const distance = v1.distanceTo(v2) / camera.zoom;

            levels[0].object.visible = true;

            var i:Int, l:Int;

            for (i = 1, l = levels.length; i < l; i++) {
                let levelDistance = levels[i].distance;

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

            this._currentLevel = i - 1;

            for (; i < l; i++) {
                levels[i].object.visible = false;
            }
        }
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var data = super.toJSON(meta);

        if (this.autoUpdate === false) data.object.autoUpdate = false;

        data.object.levels = [];

        const levels = this.levels;

        for (i in 0...levels.length) {
            const level = levels[i];

            data.object.levels.push({
                object: level.object.uuid,
                distance: level.distance,
                hysteresis: level.hysteresis
            });
        }

        return data;
    }
}