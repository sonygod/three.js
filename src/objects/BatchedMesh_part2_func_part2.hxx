class BatchedMesh {
    // ...

    public function setInstanceCountAt(id:Int, instanceCount:Int):Int {
        if (this._multiDrawInstances == null) {
            this._multiDrawInstances = new Int32Array(this._maxGeometryCount).fill(1);
        }
        this._multiDrawInstances[id] = instanceCount;
        return id;
    }

    public function getBoundingBoxAt(id:Int, target:Box3):Box3 {
        var active = this._active;
        if (active[id] == false) {
            return null;
        }
        var bound = this._bounds[id];
        var box = bound.box;
        var geometry = this.geometry;
        if (bound.boxInitialized == false) {
            box.makeEmpty();
            var index = geometry.index;
            var position = geometry.attributes.position;
            var drawRange = this._drawRanges[id];
            for (i in drawRange.start...drawRange.start + drawRange.count) {
                var iv = i;
                if (index != null) {
                    iv = index.getX(iv);
                }
                box.expandByPoint(_vector.fromBufferAttribute(position, iv));
            }
            bound.boxInitialized = true;
        }
        target.copy(box);
        return target;
    }

    // ...

    public function copy(source:BatchedMesh):BatchedMesh {
        super.copy(source);
        // ...
        return this;
    }

    public function dispose():BatchedMesh {
        // ...
        return this;
    }

    public function onBeforeRender(renderer:Renderer, scene:Scene, camera:Camera, geometry:Geometry, material:Material/*, _group*/):Void {
        // ...
    }

    public function onBeforeShadow(renderer:Renderer, object:Object3D, camera:Camera, shadowCamera:Camera, geometry:Geometry, depthMaterial:Material/* , group */):Void {
        // ...
    }
}