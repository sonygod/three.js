class Object3D {
    static var DEFAULT_UP:Vector3 = new Vector3(0, 1, 0);
    static var DEFAULT_MATRIX_AUTO_UPDATE:Bool = true;
    static var DEFAULT_MATRIX_WORLD_AUTO_UPDATE:Bool = true;

    var children:Array<Object3D>;
    var up:Vector3;
    var position:Vector3;
    var rotation:Quaternion;
    var scale:Vector3;
    var matrix:Matrix4;
    var matrixWorld:Matrix4;
    var matrixAutoUpdate:Bool;
    var matrixWorldAutoUpdate:Bool;
    var matrixWorldNeedsUpdate:Bool;
    var layers:Layers;
    var visible:Bool;
    var castShadow:Bool;
    var receiveShadow:Bool;
    var frustumCulled:Bool;
    var renderOrder:Int;
    var animations:Array<Animation>;
    var userData:Dynamic;

    function traverse(callback:Dynamic->Void) {
        callback(this);
        for (child in children) {
            child.traverse(callback);
        }
    }

    function traverseVisible(callback:Dynamic->Void) {
        if (visible == false) return;
        callback(this);
        for (child in children) {
            child.traverseVisible(callback);
        }
    }

    function traverseAncestors(callback:Dynamic->Void) {
        var parent = this.parent;
        if (parent != null) {
            callback(parent);
            parent.traverseAncestors(callback);
        }
    }

    function updateMatrix() {
        matrix.compose(position, rotation, scale);
        matrixWorldNeedsUpdate = true;
    }

    function updateMatrixWorld(force:Bool) {
        if (matrixAutoUpdate) this.updateMatrix();
        if (matrixWorldNeedsUpdate || force) {
            if (parent == null) {
                matrixWorld.copy(matrix);
            } else {
                matrixWorld.multiplyMatrices(parent.matrixWorld, matrix);
            }
            matrixWorldNeedsUpdate = false;
            force = true;
        }
        for (child in children) {
            if (child.matrixWorldAutoUpdate == true || force == true) {
                child.updateMatrixWorld(force);
            }
        }
    }

    function updateWorldMatrix(updateParents:Bool, updateChildren:Bool) {
        var parent = this.parent;
        if (updateParents == true && parent != null && parent.matrixWorldAutoUpdate == true) {
            parent.updateWorldMatrix(true, false);
        }
        if (matrixAutoUpdate) this.updateMatrix();
        if (parent == null) {
            matrixWorld.copy(matrix);
        } else {
            matrixWorld.multiplyMatrices(parent.matrixWorld, matrix);
        }
        if (updateChildren == true) {
            for (child in children) {
                if (child.matrixWorldAutoUpdate == true) {
                    child.updateWorldMatrix(false, true);
                }
            }
        }
    }

    function toJSON(meta:Dynamic) {
        // 省略...
    }

    function clone(recursive:Bool) {
        return new this.constructor().copy(this, recursive);
    }

    function copy(source:Object3D, recursive:Bool = true) {
        name = source.name;
        up.copy(source.up);
        position.copy(source.position);
        rotation.order = source.rotation.order;
        quaternion.copy(source.quaternion);
        scale.copy(source.scale);
        matrix.copy(source.matrix);
        matrixWorld.copy(source.matrixWorld);
        matrixAutoUpdate = source.matrixAutoUpdate;
        matrixWorldAutoUpdate = source.matrixWorldAutoUpdate;
        matrixWorldNeedsUpdate = source.matrixWorldNeedsUpdate;
        layers.mask = source.layers.mask;
        visible = source.visible;
        castShadow = source.castShadow;
        receiveShadow = source.receiveShadow;
        frustumCulled = source.frustumCulled;
        renderOrder = source.renderOrder;
        animations = source.animations.slice();
        userData = JSON.parse(JSON.stringify(source.userData));
        if (recursive == true) {
            for (child in source.children) {
                this.add(child.clone());
            }
        }
        return this;
    }
}