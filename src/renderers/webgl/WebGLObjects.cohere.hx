class WebGLObjects {
    public var updateMap:WeakMap;
    public function new(gl:WebGLRenderer, geometries:Geometries, attributes:Attributes, info:WebGLInfo) {
        updateMap = new WeakMap();
    }
    public function update(object:Object3D):BufferGeometry {
        var frame = info.render.frame;
        var geometry = object.geometry;
        var buffergeometry = geometries.get(object, geometry);
        if (updateMap.get(buffergeometry) != frame) {
            geometries.update(buffergeometry);
            updateMap.set(buffergeometry, frame);
        }
        if (Std.is(object, InstancedMesh)) {
            if (!object.hasEventListener(Event.DISPOSE, onInstancedMeshDispose)) {
                object.addEventListener(Event.DISPOSE, onInstancedMeshDispose);
            }
            if (updateMap.get(object) != frame) {
                attributes.update(object.instanceMatrix, gl.ARRAY_BUFFER);
                if (object.instanceColor != null) {
                    attributes.update(object.instanceColor, gl.ARRAY_BUFFER);
                }
                updateMap.set(object, frame);
            }
        }
        if (Std.is(object, SkinnedMesh)) {
            var skeleton = object.skeleton;
            if (updateMap.get(skeleton) != frame) {
                skeleton.update();
                updateMap.set(skeleton, frame);
            }
        }
        return buffergeometry;
    }
    public function dispose():Void {
        updateMap = new WeakMap();
    }
    public function onInstancedMeshDispose(event:Event):Void {
        var instancedMesh = cast(event.target, InstancedMesh);
        instancedMesh.removeEventListener(Event.DISPOSE, onInstancedMeshDispose);
        attributes.remove(instancedMesh.instanceMatrix);
        if (instancedMesh.instanceColor != null) attributes.remove(instancedMesh.instanceColor);
    }
    static public function getInstance():WebGLObjects {
        if (instance == null) instance = new WebGLObjects(null, null, null, null);
        return instance;
    }
    static private var instance:WebGLObjects;
}