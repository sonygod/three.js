package three.js.src.objects;

class BatchedMesh {
    // ... (other variables and functions)

    public function setInstanceCountAt(id:Int, instanceCount:Int):Int {
        if (this._multiDrawInstances == null) {
            this._multiDrawInstances = new Int32Array(this._maxGeometryCount);
            this._multiDrawInstances.fill(1);
        }
        this._multiDrawInstances[id] = instanceCount;
        return id;
    }

    public function getBoundingBoxAt(id:Int, target:Object3D):Object3D {
        if (!this._active[id]) {
            return null;
        }
        var bound:Object3D = this._bounds[id];
        var box:Object3D = bound.box;
        var geometry:Geometry = this.geometry;
        if (!bound.boxInitialized) {
            box.makeEmpty();
            var index:ArrayBufferView = geometry.index;
            var position:BufferAttribute = geometry.attributes.position;
            var drawRange:Object = this._drawRanges[id];
            for (var i:Int = drawRange.start, l:Int = drawRange.start + drawRange.count; i < l; i++) {
                var iv:Int = i;
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

    public function getBoundingSphereAt(id:Int, target:Object3D):Object3D {
        if (!this._active[id]) {
            return null;
        }
        var bound:Object3D = this._bounds[id];
        var sphere:Object3D = bound.sphere;
        var geometry:Geometry = this.geometry;
        if (!bound.sphereInitialized) {
            sphere.makeEmpty();
            this.getBoundingBoxAt(id, _box);
            _box.getCenter(sphere.center);
            var index:ArrayBufferView = geometry.index;
            var position:BufferAttribute = geometry.attributes.position;
            var drawRange:Object = this._drawRanges[id];
            var maxRadiusSq:Float = 0;
            for (var i:Int = drawRange.start, l:Int = drawRange.start + drawRange.count; i < l; i++) {
                var iv:Int = i;
                if (index != null) {
                    iv = index.getX(iv);
                }
                _vector.fromBufferAttribute(position, iv);
                maxRadiusSq = Math.max(maxRadiusSq, sphere.center.distanceToSquared(_vector));
            }
            sphere.radius = Math.sqrt(maxRadiusSq);
            bound.sphereInitialized = true;
        }
        target.copy(sphere);
        return target;
    }

    public function setMatrixAt(geometryId:Int, matrix:Matrix4):BatchedMesh {
        if (geometryId >= this._geometryCount || !this._active[geometryId]) {
            return this;
        }
        matrix.toArray(this._matricesTexture.image.data, geometryId * 16);
        this._matricesTexture.needsUpdate = true;
        return this;
    }

    public function getMatrixAt(geometryId:Int, matrix:Matrix4):Matrix4 {
        if (geometryId >= this._geometryCount || !this._active[geometryId]) {
            return null;
        }
        return matrix.fromArray(this._matricesTexture.image.data, geometryId * 16);
    }

    public function setColorAt(geometryId:Int, color:Color):BatchedMesh {
        if (this._colorsTexture == null) {
            this._initColorsTexture();
        }
        if (geometryId >= this._geometryCount || !this._active[geometryId]) {
            return this;
        }
        color.toArray(this._colorsTexture.image.data, geometryId * 4);
        this._colorsTexture.needsUpdate = true;
        return this;
    }

    public function getColorAt(geometryId:Int, color:Color):Color {
        if (geometryId >= this._geometryCount || !this._active[geometryId]) {
            return null;
        }
        return color.fromArray(this._colorsTexture.image.data, geometryId * 4);
    }

    public function setVisibleAt(geometryId:Int, value:Bool):BatchedMesh {
        if (geometryId >= this._geometryCount || !this._active[geometryId]) {
            return this;
        }
        this._visibility[geometryId] = value;
        this._visibilityChanged = true;
        return this;
    }

    public function getVisibleAt(geometryId:Int):Bool {
        if (geometryId >= this._geometryCount || !this._active[geometryId]) {
            return false;
        }
        return this._visibility[geometryId];
    }

    public function raycast(raycaster:Raycaster, intersects:Array<RaycastHit>):Void {
        // ...
    }

    public function copy(source:BatchedMesh):BatchedMesh {
        super.copy(source);
        this.geometry = source.geometry.clone();
        this.perObjectFrustumCulled = source.perObjectFrustumCulled;
        this.sortObjects = source.sortObjects;
        this.boundingBox = source.boundingBox != null ? source.boundingBox.clone() : null;
        this.boundingSphere = source.boundingSphere != null ? source.boundingSphere.clone() : null;
        // ...
        return this;
    }

    public function dispose():Void {
        this.geometry.dispose();
        this._matricesTexture.dispose();
        this._matricesTexture = null;
        if (this._colorsTexture != null) {
            this._colorsTexture.dispose();
            this._colorsTexture = null;
        }
    }

    public function onBeforeRender(renderer:WebGLRenderer, scene:Scene, camera:Camera, geometry:Geometry, material:Material/*, group:Object3D*/):Void {
        // ...
    }

    public function onBeforeShadow(renderer:WebGLRenderer, object:Object3D, camera:Camera, shadowCamera:Camera, geometry:Geometry, depthMaterial:Material/*, group:Object3D*/):Void {
        this.onBeforeRender(renderer, null, shadowCamera, geometry, depthMaterial);
    }
}