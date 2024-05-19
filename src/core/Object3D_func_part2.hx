Here is the converted Haxe code:
```
package three.js.src.core;

class Object3D {
    // ...

    public function traverse(callback:Void->Void) {
        callback(this);
        var children:Array<Object3D> = this.children;
        for (i in 0...children.length) {
            children[i].traverse(callback);
        }
    }

    public function traverseVisible(callback:Void->Void) {
        if (!this.visible) return;
        callback(this);
        var children:Array<Object3D> = this.children;
        for (i in 0...children.length) {
            children[i].traverseVisible(callback);
        }
    }

    public function traverseAncestors(callback:Void->Void) {
        var parent:Object3D = this.parent;
        if (parent != null) {
            callback(parent);
            parent.traverseAncestors(callback);
        }
    }

    public function updateMatrix() {
        this.matrix.compose(this.position, this.quaternion, this.scale);
        this.matrixWorldNeedsUpdate = true;
    }

    public function updateMatrixWorld(force:Bool = false) {
        if (this.matrixAutoUpdate) this.updateMatrix();
        if (this.matrixWorldNeedsUpdate || force) {
            if (this.parent == null) {
                this.matrixWorld.copy(this.matrix);
            } else {
                this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
            }
            this.matrixWorldNeedsUpdate = false;
            force = true;
        }
        // update children
        var children:Array<Object3D> = this.children;
        for (i in 0...children.length) {
            var child:Object3D = children[i];
            if (child.matrixWorldAutoUpdate || force) {
                child.updateMatrixWorld(force);
            }
        }
    }

    public function updateWorldMatrix(updateParents:Bool, updateChildren:Bool) {
        var parent:Object3D = this.parent;
        if (updateParents && parent != null && parent.matrixWorldAutoUpdate) {
            parent.updateWorldMatrix(true, false);
        }
        if (this.matrixAutoUpdate) this.updateMatrix();
        if (this.parent == null) {
            this.matrixWorld.copy(this.matrix);
        } else {
            this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
        }
        // update children
        if (updateChildren) {
            var children:Array<Object3D> = this.children;
            for (i in 0...children.length) {
                var child:Object3D = children[i];
                if (child.matrixWorldAutoUpdate) {
                    child.updateWorldMatrix(false, true);
                }
            }
        }
    }

    public function toJSON(meta:Dynamic = null):Dynamic {
        // ...
    }

    public function clone(recursive:Bool = true):Object3D {
        return new Object3D().copy(this, recursive);
    }

    public function copy(source:Object3D, recursive:Bool = true):Object3D {
        // ...
        return this;
    }
}

class Vector3 {
    public var x:Float;
    public var y:Float;
    public var z:Float;

    public function new(x:Float = 0, y:Float = 0, z:Float = 0) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public function copy(v:Vector3) {
        this.x = v.x;
        this.y = v.y;
        this.z = v.z;
    }

    public function toArray():Array<Float> {
        return [x, y, z];
    }
}

class Object3DSingleton {
    public static var DEFAULT_UP:Vector3 = new Vector3(0, 1, 0);
    public static var DEFAULT_MATRIX_AUTO_UPDATE:Bool = true;
    public static var DEFAULT_MATRIX_WORLD_AUTO_UPDATE:Bool = true;
}
```
Note that I had to create a new `Vector3` class to match the JavaScript `Vector3` class. I also created a `Object3DSingleton` class to hold the static variables.

Please note that this is a manual conversion, and it's not guaranteed to be 100% correct. You may need to test and adjust the code to fit your specific use case.