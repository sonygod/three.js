import Vector3 from '../math/Vector3.hx';
import Object3D from '../core/Object3D.hx';

class LOD extends Object3D {
    public _currentLevel: Int;
    public levels: Array<Object>;
    public isLOD: Bool;
    public autoUpdate: Bool;

    public function new() {
        super();
        this._currentLevel = 0;
        this.type = 'LOD';
        this.levels = [];
        this.isLOD = true;
        this.autoUpdate = true;
    }

    public function copy(source: LOD): LOD {
        super.copy(source, false);
        for (i in 0...source.levels.length) {
            let level = source.levels[i];
            this.addLevel(level.object.clone(), level.distance, level.hysteresis);
        }
        this.autoUpdate = source.autoUpdate;
        return this;
    }

    public function addLevel(object: Object3D, distance: Float = 0.0, hysteresis: Float = 0.0): LOD {
        distance = Math.abs(distance);
        let levels = this.levels;
        let l: Int;
        for (l in 0...levels.length) {
            if (distance < levels[l].distance) {
                break;
            }
        }
        levels.insert(l, { distance: distance, hysteresis: hysteresis, object: object });
        this.add(object);
        return this;
    }

    public function getCurrentLevel(): Int {
        return this._currentLevel;
    }

    public function getObjectForDistance(distance: Float): Object3D {
        let levels = this.levels;
        if (levels.length > 0) {
            for (i in 1...levels.length) {
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

    public function raycast(raycaster: Raycaster, intersects: Array<Intersect>) {
        let levels = this.levels;
        if (levels.length > 0) {
            let _v1 = Vector3.fromMatrixPosition(this.matrixWorld);
            let distance = raycaster.ray.origin.distanceTo(_v1);
            this.getObjectForDistance(distance).raycast(raycaster, intersects);
        }
    }

    public function update(camera: Object3D) {
        let levels = this.levels;
        if (levels.length > 1) {
            let _v1 = Vector3.fromMatrixPosition(camera.matrixWorld);
            let _v2 = Vector3.fromMatrixPosition(this.matrixWorld);
            let distance = (_v1.distanceTo(_v2) / camera.zoom);
            levels[0].object.visible = true;
            for (i in 1...levels.length) {
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
            for (; i < levels.length; i++) {
                levels[i].object.visible = false;
            }
        }
    }

    public function toJSON(meta: Bool): Object {
        let data = super.toJSON(meta);
        if (this.autoUpdate == false) data.object.autoUpdate = false;
        data.object.levels = [];
        let levels = this.levels;
        for (i in 0...levels.length) {
            let level = levels[i];
            data.object.levels.push({
                object: level.object.uuid,
                distance: level.distance,
                hysteresis: level.hysteresis
            });
        }
        return data;
    }
}

class Raycaster {
}

class Intersect {
}