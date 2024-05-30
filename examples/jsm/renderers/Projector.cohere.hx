import h3d.Vector3;
import h3d.Vector4;
import h3d.Matrix4;
import h3d.Frustum;
import h3d.Box;

class RenderableObject {
    public var id:Int;
    public var object:Dynamic;
    public var z:Float;
    public var renderOrder:Int;

    public function new() {
        id = 0;
        object = null;
        z = 0;
        renderOrder = 0;
    }
}

class RenderableFace {
    public var id:Int;
    public var v1:RenderableVertex;
    public var v2:RenderableVertex;
    public var v3:RenderableVertex;
    public var normalModel:Vector3;
    public var vertexNormalsModel:Array<Vector3>;
    public var vertexNormalsLength:Int;
    public var color:Float32Array;
    public var material:Dynamic;
    public var uvs:Array<Float32Array>;
    public var z:Float;
    public var renderOrder:Int;

    public function new() {
        id = 0;
        v1 = new RenderableVertex();
        v2 = new RenderableVertex();
        v3 = new RenderableVertex();
        normalModel = new Vector3();
        vertexNormalsModel = [new Vector3(), new Vector3(), new Vector3()];
        vertexNormalsLength = 0;
        color = new Float32Array();
        material = null;
        uvs = [new Float32Array(), new Float32Array(), new Float32Array()];
        z = 0;
        renderOrder = 0;
    }
}

class RenderableVertex {
    public var position:Vector3;
    public var positionWorld:Vector3;
    public var positionScreen:Vector4;
    public var visible:Bool;

    public function new() {
        position = new Vector3();
        positionWorld = new Vector3();
        positionScreen = new Vector4();
        visible = true;
    }

    public function copy(vertex:RenderableVertex):Void {
        positionWorld.copy(vertex.positionWorld);
        positionScreen.copy(vertex.positionScreen);
    }
}

class RenderableLine {
    public var id:Int;
    public var v1:RenderableVertex;
    public var v2:RenderableVertex;
    public var vertexColors:Array<Float32Array>;
    public var material:Dynamic;
    public var z:Float;
    public var renderOrder:Int;

    public function new() {
        id = 0;
        v1 = new RenderableVertex();
        v2 = new RenderableVertex();
        vertexColors = [new Float32Array(), new Float32Array()];
        material = null;
        z = 0;
        renderOrder = 0;
    }
}

class RenderableSprite {
    public var id:Int;
    public var object:Dynamic;
    public var x:Float;
    public var y:Float;
    public var z:Float;
    public var rotation:Float;
    public var scale:Float32Array;
    public var material:Dynamic;
    public var renderOrder:Int;

    public function new() {
        id = 0;
        object = null;
        x = 0;
        y = 0;
        z = 0;
        rotation = 0;
        scale = new Float32Array();
        material = null;
        renderOrder = 0;
    }
}

class Projector {
    private var _object:Dynamic;
    private var _objectCount:Int;
    private var _objectPoolLength:Int;
    private var _vertex:Dynamic;
    private var _vertexCount:Int;
    private var _vertexPoolLength:Int;
    private var _face:Dynamic;
    private var _faceCount:Int;
    private var _facePoolLength:Int;
    private var _line:Dynamic;
    private var _lineCount:Int;
    private var _linePoolLength:Int;
    private var _sprite:Dynamic;
    private var _spriteCount:Int;
    private var _spritePoolLength:Int;
    private var _modelMatrix:Dynamic;

    private var _renderData:Dynamic;
    private var _vector3:Vector3;
    private var _vector4:Vector4;
    private var _clipBox:Box;
    private var _boundingBox:Box;
    private var _points3:Array<Vector3>;
    private var _viewMatrix:Matrix4;
    private var _viewProjectionMatrix:Matrix4;
    private var _modelViewProjectionMatrix:Matrix4;
    private var _frustum:Frustum;
    private var _objectPool:Array<Dynamic>;
    private var _vertexPool:Array<Dynamic>;
    private var _facePool:Array<Dynamic>;
    private var _linePool:Array<Dynamic>;
    private var _spritePool:Array<Dynamic>;

    private function RenderList() : Dynamic {
        var normals:Array<Float> = [];
        var colors:Array<Float> = [];
        var uvs:Array<Float> = [];
        var object:Dynamic = null;
        var normalMatrix:Dynamic = new h3d.Matrix3();

        function setObject(value:Dynamic) : Void {
            object = value;
            normalMatrix.getNormalMatrix(object.matrixWorld);
            normals.length = 0;
            colors.length = 0;
            uvs.length = 0;
        }

        function projectVertex(vertex:Dynamic) : Void {
            var position:Dynamic = vertex.position;
            var positionWorld:Dynamic = vertex.positionWorld;
            var positionScreen:Dynamic = vertex.positionScreen;
            positionWorld.copy(position).applyMatrix4(_modelMatrix);
            positionScreen.copy(positionWorld).applyMatrix4(_viewProjectionMatrix);
            var invW:Float = 1 / positionScreen.w;
            positionScreen.x *= invW;
            positionScreen.y *= invW;
            positionScreen.z *= invW;
            vertex.visible = (positionScreen.x >= -1 && positionScreen.x <= 1) &&
                           (positionScreen.y >= -1 && positionScreen.y <= 1) &&
                           (positionScreen.z >= -1 && positionScreen.z <= 1);
        }

        function pushVertex(x:Float, y:Float, z:Float) : Void {
            _vertex = getNextVertexInPool();
            _vertex.position.set(x, y, z);
            projectVertex(_vertex);
        }

        function pushNormal(x:Float, y:Float, z:Float) : Void {
            normals.push(x, y, z);
        }

        function pushColor(r:Float, g:Float, b:Float) : Void {
            colors.push(r, g, b);
        }

        function pushUv(x:Float, y:Float) : Void {
            uvs.push(x, y);
        }

        function checkTriangleVisibility(v1:Dynamic, v2:Dynamic, v3:Dynamic) : Bool {
            if (v1.visible || v2.visible || v3.visible) return true;
            _points3[0] = v1.positionScreen;
            _points3[1] = v2.positionScreen;
            _points3[2] = v3.positionScreen;
            return _clipBox.intersectsBox(_boundingBox.setFromPoints(_points3));
        }

        function checkBackfaceCulling(v1:Dynamic, v2:Dynamic, v3:Dynamic) : Bool {
            return ((v3.positionScreen.x - v1.positionScreen.x) *
                    (v2.positionScreen.y - v1.positionScreen.y)) -
                    ((v3.positionScreen.y - v1.positionScreen.y) *
                    (v2.positionScreen.x - v1.positionScreen.x)) < 0;
        }

        function pushLine(a:Int, b:Int) : Void {
            var v1:Dynamic = _vertexPool[a];
            var v2:Dynamic = _vertexPool[b];
            v1.positionScreen.copy(v1.position).applyMatrix4(_modelViewProjectionMatrix);
            v2.positionScreen.copy(v2.position).applyMatrix4(_modelViewProjectionMatrix);
            if (clipLine(v1.positionScreen, v2.positionScreen)) {
                v1.positionScreen.multiplyScalar(1 / v1.positionScreen.w);
                v2.positionScreen.multiplyScalar(1 / v2.positionScreen.w);
                _line = getNextLineInPool();
                _line.id = object.id;
                _line.v1.copy(v1);
                _line.v2.copy(v2);
                _line.z = Math.max(v1.positionScreen.z, v2.positionScreen.z);
                _line.renderOrder = object.renderOrder;
                _line.material = object.material;
                if (object.material.vertexColors) {
                    _line.vertexColors[0].fromArray(colors, a * 3);
                    _line.vertexColors[1].fromArray(colors, b * 3);
                }
                _renderData.elements.push(_line);
            }
        }

        function pushTriangle(a:Int, b:Int, c:Int, material:Dynamic) : Void {
            var v1:Dynamic = _vertexPool[a];
            var v2:Dynamic = _vertexPool[b];
            var v3:Dynamic = _vertexPool[c];
            if (!checkTriangleVisibility(v1, v2, v3)) return;
            if (material.side == DoubleSide || checkBackfaceCulling(v1, v2, v3)) {
                _face = getNextFaceInPool();
                _face.id = object.id;
                _face.v1.copy(v1);
                _face.v2.copy(v2);
                _face.v3.copy(v3);
                _face.z = (v1.positionScreen.z + v2.positionScreen.z + v3.positionScreen.z) / 3;
                _face.renderOrder = object.renderOrder;
                _vector3.subVectors(v3.position, v2.position);
                var _vector4:Dynamic = new Vector4();
                _vector4.subVectors(v1.position, v2.position);
                _vector3.cross(_vector4);
                _face.normalModel.copy(_vector3);
                _face.normalModel.applyMatrix3(normalMatrix).normalize();
                var normal:Dynamic;
                var uv:Dynamic;
                for (i in 0...3) {
                    normal = _face.vertexNormalsModel[i];
                    normal.fromArray(normals, arguments[i] * 3);
                    normal.applyMatrix3(normalMatrix).normalize();
                    uv = _face.uvs[i];
                    uv.fromArray(uvs, arguments[i] * 2);
                }
                _face.vertexNormalsLength = 3;
                _face.material = material;
                if (material.vertexColors) {
                    _face.color.fromArray(colors, a * 3);
                }
                _renderData.elements.push(_face);
            }
        }

        return {
            setObject,
            projectVertex,
            checkTriangleVisibility,
            checkBackfaceCulling,
            pushVertex,
            pushNormal,
            pushColor,
            pushUv,
            pushLine,
            pushTriangle
        };
    }

    public function new() {
        _renderData = {objects: [], lights: [], elements: []};
        _vector3 = new Vector3();
        _vector4 = new Vector4();
        _clipBox = new Box(new Vector3(-1, -1, -1), new Vector3(1, 1, 1));
        _boundingBox = new Box();
        _points3 = [new Vector3(), new Vector3(), new Vector3()];
        _viewMatrix = new Matrix4();
        _viewProjectionMatrix = new Matrix4();
        _modelViewProjectionMatrix = new Matrix4();
        _frustum = new Frustum();
        _objectPool = [];
        _vertexPool = [];
        _facePool = [];
        _linePool = [];
        _spritePool = [];
        var renderList:Dynamic = RenderList();

        function projectObject(object:Dynamic) : Void {
            if (!object.visible) return;
            if (object.isLight) {
                _renderData.lights.push(object);
            } else if (object.isMesh || object.isLine || object.isPoints) {
                if (!object.material.visible) return;
                if (object.frustumCulled && !_frustum.intersectsObject(object)) return;
                addObject(object);
            } else if (object.isSprite) {
                if (!object.material.visible) return;
                if (object.frustumCulled && !_frustum.intersectsSprite(object)) return;
                addObject(object);
            }
            var children:Dynamic = object.children;
            for (i in 0...children.length) {
                projectObject(children[i]);
            }
        }

        function addObject(object:Dynamic) : Void {
            _object = getNextObjectInPool();
            _object.id = object.id;
            _object.object = object;
            _vector3.setFromMatrixPosition(object.matrixWorld);
            _vector3.applyMatrix4(_viewProjectionMatrix);
            _object.z = _vector3.z;
            _object.renderOrder = object.renderOrder;
            _renderData.objects.push(_object);
        }

        function painterSort(a:Dynamic, b:Dynamic) : Int {
            if (a.renderOrder != b.renderOrder) {
                return a.renderOrder - b.renderOrder;
            } else if (a.z != b.z) {
                return b.z - a.z;
            } else if (a.id != b.id) {
                return a.id - b.id;
            } else {
                return 0;
            }
        }

        function clipLine(s1:Dynamic, s2:Dynamic) : Bool {
            var alpha1:Float = 0;
            var alpha2:Float = 1;
            var bc1near:Float = s1.z + s1.w;
            var bc2near:Float = s2.z + s2.w;
            var bc1far:Float = -s1.z + s1.w;
            var bc2far:Float = -s2.z + s2.w;
            if (bc1near >= 0 && bc2near >= 0 && bc1far >= 0 && bc2far >= 0) {
                return true;
            } else if ((bc1near < 0 && bc2near < 0) || (bc1far < 0 && bc2far < 0)) {
                return false;
            } else {
                if (bc1near < 0) {
                    alpha1 = Math.max(alpha1, bc1near / (bc1near - bc2near));
                } else if (bc2near < 0) {
                    alpha2 = Math.min(alpha2, bc1near / (bc1near - bc2near));
                }
                if (bc1far < 0) {
                    alpha1 = Math.max(alpha1, bc1far / (bc1far - bc2far));
                } else if (bc2far < 0) {
                    alpha2 = Math.min(alpha2, bc1far / (bc1far - bc2far));
                }
                if (alpha2 < alpha1) {
                    return false;
                } else {
                    s1.lerp(s2, alpha1);
                    s2.lerp(s1, 1 - alpha2);
                    return true;
                }
            }
        }

        function pushPoint(_vector4:Vector4, object:Dynamic, camera:Dynamic) : Void {
            var invW:Float = 1 / _vector4.w;
            _vector4.z *= invW;
            if (_vector4.z >= -1 && _vector4.z <= 1) {
                _sprite = getNextSpriteInPool();
                _sprite.id = object.id;
                _sprite.x = _vector4.x * invW;
                _sprite.y = _vector4.y * invW;
                _sprite.z = _vector4.z;
                _sprite.renderOrder = object.renderOrder;
                _sprite.object = object;
                _sprite.rotation = object.rotation;
                _sprite.scale.x = object.scale.x * Math.abs(_sprite.x - (_vector4.x + camera.projectionMatrix.elements[0]) / (_vector4.w + camera.projectionMatrix.elements[12]));
                _sprite.scale.y = object.scale.y * Math.abs(_sprite.y - (_vector4.y + camera.projectionMatrix.elements[5]) / (_vector4.w + camera.projectionMatrix.elements[13]));
                _sprite.material = object.material;
                _renderData.elements.push(_sprite);
            }
        }

        function getNextObjectInPool() : Dynamic {
            if (_objectCount == _objectPoolLength) {
                var object:Dynamic = new RenderableObject();
                _objectPool.push(object);
                _objectPoolLength++;
                _objectCount++;
                return object;
            }
            return _objectPool[_objectCount++];
        }

        function getNextVertexInPool() : Dynamic {
            if (_vertexCount == _vertexPoolLength) {
                var vertex:Dynamic = new RenderableVertex();
                _vertexPool.push(vertex);
                _vertexPoolLength++;
                _vertexCount++;
                return vertex;
            }
            return _vertexPool[_vertexCount++];
        }

        function getNextFaceInPool() : Dynamic {
            if (_faceCount == _facePoolLength) {
                var face:Dynamic = new RenderableFace();
                _facePool.push(face);
                _facePoolLength++;
                _faceCount++;
                return face;
            }
            return _facePool[_faceCount++];
        }

        function getNextLineInPool() : Dynamic {
            if (_lineCount == _linePoolLength) {
                var line:Dynamic = new RenderableLine();
                _linePool.push(line);
                _linePoolLength++;
                _lineCount++;
                return line;
            }
            return _linePool[_lineCount++];
        }

        function getNextSpriteInPool() : Dynamic {
            if (_spriteCount == _spritePoolLength) {
                var sprite:Dynamic = new RenderableSprite();
                _spritePool.push(sprite);
                _spritePoolLength++;
                _spriteCount++;
                return sprite;
            }
            return _spritePool[_spriteCount++];
        }

        function projectScene(scene:Dynamic, camera:Dynamic, sortObjects:Bool, sortElements:Bool) : Dynamic {
            _faceCount = 0;
            _lineCount = 0;
            _spriteCount = 0;
            _renderData.elements.length = 0;
            if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();
            if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();
            _viewMatrix.copy(camera.matrixWorldInverse);
            _viewProjectionMatrix.multiplyMatrices(camera.projectionMatrix, _viewMatrix);
            _frustum.setFromProjectionMatrix(_viewProjectionMatrix);
            _objectCount = 0;
            _renderData.objects.length = 0;
            _renderData.lights.length = 0;
            projectObject(scene);
            if (sortObjects) {
                _renderData.objects.sort(painterSort);
            }
            var objects:Dynamic = _renderData.objects;
            for (o in 0...objects.length) {
                var object:Dynamic = objects[o].object;
                var geometry:Dynamic = object.geometry;
                renderList.setObject(object);
                _modelMatrix = object.matrixWorld;
                _vertexCount = 0;
                if (object.isMesh) {
                    var material:Dynamic = object.material;
                    var isMultiMaterial:Bool = Array.isArray(material);
                    var attributes:Dynamic = geometry.attributes;
                    var groups:Dynamic = geometry.groups;
                    if (!attributes.position) continue;
                    var positions:Dynamic = attributes.position.array;
                    for (i in 0...positions.length) {
                        var x:Float = positions[i];
                        var y:Float = positions[i + 1];
                        var z:Float = positions[i + 2];
                        var morphTargets:Dynamic = geometry.morphAttributes.position;
                        if (morphTargets) {
                            var morphTargetsRelative:Bool = geometry.morphTargetsRelative;
                            var morphInfluences:Dynamic = object.morphTargetInfluences;
                            for (t in 0...morphTargets.length) {
                                var influence:Float = morphInfluences[t];
                                if (influence == 0) continue;
                                var target:Dynamic = morphTargets[t];
                                if (morphTargetsRelative) {
                                    x += target.getX(i / 3) * influence;
                                    y += target.getY(i / 3) * influence;
                                    z += target.getZ(i / 3) * influence;
                                } else {
                                    x += (target.getX(i / 3) - positions[i]) * influence;
                                    y += (target.getY(i / 3) - positions[i + 1]) * influence;
                                    z += (target.getZ(i / 3) - positions[i + 2]) * influence;
                                }
                            }
                        }
                        renderList.pushVertex(x, y, z);
                    }
                    if (attributes.normal) {
                        var normals:Dynamic = attributes.normal.array;
                        for (i in 0...normals.length) {
                            renderList.pushNormal(normals[i], normals[i + 1], normals[i + 2]);
                        }
                    }
                    if (attributes.color) {
                        var colors:Dynamic = attributes.color.array;
                        for (i in 0...colors.length) {
                            renderList.pushColor(colors[i], colors[i + 1], colors[i + 2]);
                        }
                    }
                    if (attributes.uv) {
                        var uvs:Dynamic = attributes.uv.array;
                        for (i in 0...uvs.length) {
                            renderList.pushUv(uvs[i], uvs[i + 1]);
                        }
                    }
                    if (geometry.index) {
                        var indices:Dynamic = geometry.index.array;
                        if (groups.length > 0) {
                            for (g in 0...groups.length) {
                                var group:Dynamic = groups[g];
                                material = isMultiMaterial ? object.material[group.materialIndex] : object.material;
                                if (!material) continue;
                                for (i in group.start...group.start + group.count) {
                                    renderList.pushTriangle(indices[i], indices[i + 1], indices[i + 2], material);
                                }
                            }
                        } else {
                            for (i in 0...indices.length) {
                                renderList.pushTriangle(indices[i], indices[i + 1], indices[i + 2], material);
                            }
                        }
                    } else {
                        if (groups.length > 0) {
                            for (g in 0...groups.length) {
                                var group:Dynamic = groups[g];
                                material = isMultiMaterial ? object.material[group.materialIndex] : object.material;
                                if (!material) continue;
                                for (i in group.start...group.start + group.count) {
                                    renderList.pushTriangle(i, i + 1, i + 2, material);
                                }
                            }
                        } else {
                            for (i in 0...positions.length / 3) {
                                renderList.pushTriangle(i, i + 1, i + 2, material);
                            }
                        }
                    }
                } else if (object.isLine) {
                    _modelViewProjectionMatrix.multiplyMatrices(_viewProjectionMatrix, _modelMatrix);
                    var attributes:Dynamic = geometry.attributes;
                    if (attributes.position) {
                        var positions:Dynamic = attributes.position.array;
                        for (i in 0...positions.length) {
                            renderList.pushVertex(positions[i], positions[i + 1], positions[i + 2]);
                        }
                        if (attributes.color) {
                            var colors:Dynamic = attributes.color.array;
                            for (i in 0...colors.length) {
                                renderList.pushColor(colors[i], colors[i + 1], colors[i + 2]);
                            }
                        }
                        if (geometry.index) {
                            var indices:Dynamic = geometry.index.array;
                            for (i in 0...indices.length) {
                                renderList.pushLine(indices[i], indices[i + 1]);
                            }
                        } else {
                            var step:Int = object.isLineSegments ? 2 : 1;
                            for (i in 0...(positions.length / 3) - 1) {
                                renderList.pushLine(i, i + step);
                            }
                        }
                    }
                } else if (object.isPoints) {
                    _modelViewProjectionMatrix.multiplyMatrices(_viewProjectionMatrix, _modelMatrix);
                    var attributes:Dynamic = geometry.attributes;
                    if (attributes.position) {
                        var positions:Dynamic = attributes.position.array;
                        for (i in 0...positions.length) {
                            _vector4.set(positions[i], positions[i + 1], positions[i + 2], 1);
                            _vector4.applyMatrix4(_modelViewProjectionMatrix);
                            pushPoint(_vector4, object, camera);
                        }
                    }
                } else if (object.isSprite) {
                    object.modelViewMatrix.multiplyMatrices(camera.matrixWorldInverse, object.matrixWorld);
                    _vector4.set(_modelMatrix.elements[12], _modelMatrix.elements[13], _modelMatrix.elements[14], 1);
                    _vector4.applyMatrix4(_viewProjectionMatrix);
                    pushPoint(_vector4, object, camera);
                }
            }
            if (sortElements) {
                _renderData.elements.sort(painterSort);
            }
            return _renderData;
        }
    }
}

class RenderableObject {
    public var id:Int;
    public var object:Dynamic;
    public var z:Float;
    public var renderOrder:Int;

    public function new() {
        id = 0;
        object = null;
        z = 0;
        renderOrder = 0;
    }
}

class RenderableFace {
    public var id:Int;
    public var v1:RenderableVertex;
    public var v2:RenderableVertex;
    public var v3:RenderableVertex;
    public var normalModel:Vector3;
    public var vertexNormalsModel:Array<Vector3>;
    public var vertexNormalsLength:Int;
    public var color:Float32Array;
    public var material:Dynamic;
    public var uvs:Array<Float32Array>;
    public var z:Float;
    public var renderOrder:Int;

    public function new() {
        id = 0;
        v1 = new RenderableVertex();
        v2 = new RenderableVertex();
        v3 = new RenderableVertex();
        normalModel = new Vector3();
        vertexNormalsModel = [new Vector3(), new Vector3(), new Vector3()];
        vertexNormalsLength = 0;
        color = new Float32Array();
        material = null;
        uvs = [new Float32Array(), new Float32Array(), new Float32Array()];
        z = 0;
        renderOrder = 0;
    }
}

class RenderableVertex {
    public var position:Vector3;
    public var positionWorld:Vector3;
    public var positionScreen:Vector4;
    public var visible:Bool;

    public function new() {
        position = new Vector3();
        positionWorld = new Vector3();
        positionScreen = new Vector4();
        visible = true;
    }

    public function copy(vertex:RenderableVertex) : Void {
        positionWorld.copy(vertex.positionWorld);
        positionScreen.copy(vertex.positionScreen);
    }
}

class RenderableLine {
    public var id:Int;
    public var v1:RenderableVertex;
    public var v2:RenderableVertex;
    public var vertexColors:Array<Float32Array>;
    public var material:Dynamic;
    public var z:Float;
    public var renderOrder:Int;

    public function new() {
        id = 0;
        v1 = new RenderableVertex();
        v2 = new RenderableVertex();
        vertexColors = [new Float32Array(), new Float32Array()];
        material = null;
        z = 0;
        renderOrder = 0;
    }
}

class RenderableSprite {
    public var id:Int;
    public var object:Dynamic;
    public var x:Float;
    public var y:Float;
    public var z:Float;
    public var rotation:Float;
    public var scale:Float32Array;
    public var material:Dynamic;
    public var renderOrder:Int;

    public function new() {
        id = 0;
        object = null;
        x = 0;
        y = 0;
        z = 0;
        rotation = 0;
        scale = new Float32Array();
        material = null;
        renderOrder = 0;
    }
}