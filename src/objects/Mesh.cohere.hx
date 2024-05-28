import Vector3 from '../math/Vector3.hx';
import Vector2 from '../math/Vector2.hx';
import Sphere from '../math/Sphere.hx';
import Ray from '../math/Ray.hx';
import Matrix4 from '../math/Matrix4.hx';
import Object3D from '../core/Object3D.hx';
import Triangle from '../math/Triangle.hx';
import BackSide from '../constants.hx';
import FrontSide from '../constants.hx';
import MeshBasicMaterial from '../materials/MeshBasicMaterial.hx';
import BufferGeometry from '../core/BufferGeometry.hx';

var _inverseMatrix = new Matrix4();
var _ray = new Ray();
var _sphere = new Sphere();
var _sphereHitAt = new Vector3();

var _vA = new Vector3();
var _vB = new Vector3();
var _vC = new Vector3();

var _tempA = new Vector3();
var _morphA = new Vector3();

var _uvA = new Vector2();
var _uvB = new Vector2();
var _uvC = new Vector2();

var _normalA = new Vector3();
var _normalB = new Vector3();
var _normalC = new Vector3();

var _intersectionPoint = new Vector3();
var _intersectionPointWorld = new Vector3();

class Mesh extends Object3D {
    public isMesh:Bool;
    public type:String;
    public geometry:BufferGeometry;
    public material:MeshBasicMaterial;
    public morphTargetInfluences:Array<Int>;
    public morphTargetDictionary:Map<String,Int>;

    public function new(geometry:BufferGeometry = new BufferGeometry(), material:MeshBasicMaterial = new MeshBasicMaterial()) {
        super();
        this.isMesh = true;
        this.type = 'Mesh';
        this.geometry = geometry;
        this.material = material;
        this.updateMorphTargets();
    }

    public function copy(source:Mesh, recursive:Bool) {
        super.copy(source, recursive);
        if (source.morphTargetInfluences != null) {
            this.morphTargetInfluences = source.morphTargetInfluences.slice();
        }
        if (source.morphTargetDictionary != null) {
            this.morphTargetDictionary = source.morphTargetDictionary;
        }
        this.material = (source.material as Array<MeshBasicMaterial>) != null ? source.material.slice() : source.material;
        this.geometry = source.geometry;
        return this;
    }

    public function updateMorphTargets() {
        var geometry = this.geometry;
        var morphAttributes = geometry.morphAttributes;
        var keys = Reflect.fields(morphAttributes);
        if (keys.length > 0) {
            var morphAttribute = Reflect.field(morphAttributes, keys[0]);
            if (morphAttribute != null) {
                this.morphTargetInfluences = [];
                this.morphTargetDictionary = new Map<String,Int>();
                var ml = morphAttribute.length;
                for (var m = 0; m < ml; m++) {
                    var name = (morphAttribute[m] as Map<String,Dynamic>).name;
                    this.morphTargetInfluences.push(0);
                    this.morphTargetDictionary.set(name, m);
                }
            }
        }
    }

    public function getVertexPosition(index:Int, target:Vector3) {
        var geometry = this.geometry;
        var position = geometry.attributes.position;
        var morphPosition = geometry.morphAttributes.position;
        var morphTargetsRelative = geometry.morphTargetsRelative;
        target.fromBufferAttribute(position, index);
        var morphInfluences = this.morphTargetInfluences;
        if (morphPosition != null && morphInfluences != null) {
            _morphA.set(0, 0, 0);
            var il = morphPosition.length;
            for (var i = 0; i < il; i++) {
                var influence = morphInfluences[i];
                var morphAttribute = morphPosition[i];
                if (influence == 0) continue;
                _tempA.fromBufferAttribute(morphAttribute, index);
                if (morphTargetsRelative) {
                    _morphA.addScaledVector(_tempA, influence);
                } else {
                    _morphA.addScaledVector(_tempA.sub(target), influence);
                }
            }
            target.add(_morphA);
        }
        return target;
    }

    public function raycast(raycaster:Dynamic, intersects:Array<Dynamic>) {
        var geometry = this.geometry;
        var material = this.material;
        var matrixWorld = this.matrixWorld;
        if (material == null) return;
        // test with bounding sphere in world space
        if (geometry.boundingSphere == null) geometry.computeBoundingSphere();
        _sphere.copy(geometry.boundingSphere);
        _sphere.applyMatrix4(matrixWorld);
        // check distance from ray origin to bounding sphere
        _ray.copy(raycaster.ray).recast(raycaster.near);
        if (!_sphere.containsPoint(_ray.origin)) {
            if (_ray.intersectSphere(_sphere, _sphereHitAt) == null) return;
            if (_ray.origin.distanceToSquared(_sphereHitAt) > Math.pow(raycaster.far - raycaster.near, 2)) return;
        }
        // convert ray to local space of mesh
        _inverseMatrix.copy(matrixWorld).invert();
        _ray.copy(raycaster.ray).applyMatrix4(_inverseMatrix);
        // test with bounding box in local space
        if (geometry.boundingBox != null && !_ray.intersectsBox(geometry.boundingBox)) return;
        // test for intersections with geometry
        this._computeIntersections(raycaster, intersects, _ray);
    }

    public function _computeIntersections(raycaster:Dynamic, intersects:Array<Dynamic>, rayLocalSpace:Ray) {
        var intersection:Dynamic;
        var geometry = this.geometry;
        var material = this.material;
        var index = geometry.index;
        var position = geometry.attributes.position;
        var uv = geometry.attributes.uv;
        var uv1 = geometry.attributes.uv1;
        var normal = geometry.attributes.normal;
        var groups = geometry.groups;
        var drawRange = geometry.drawRange;
        if (index != null) {
            // indexed buffer geometry
            if (material is Array<MeshBasicMaterial>) {
                var il = groups.length;
                for (var i = 0; i < il; i++) {
                    var group = groups[i];
                    var groupMaterial = material[group.materialIndex];
                    var start = Math.max(group.start, drawRange.start);
                    var end = Math.min(index.count, Math.min(group.start + group.count, drawRange.start + drawRange.count));
                    var jl = end - start;
                    for (var j = start; j < end; j += 3) {
                        var a = index.getX(j);
                        var b = index.getX(j + 1);
                        var c = index.getX(j + 2);
                        intersection = checkGeometryIntersection(this, groupMaterial, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c);
                        if (intersection != null) {
                            intersection.faceIndex = Math.floor(j / 3); // triangle number in indexed buffer semantics
                            intersection.face.materialIndex = group.materialIndex;
                            intersects.push(intersection);
                        }
                    }
                }
            } else {
                var start = Math.max(0, drawRange.start);
                var end = Math.min(index.count, drawRange.start + drawRange.count);
                var il = end - start;
                for (var i = start; i < end; i += 3) {
                    var a = index.getX(i);
                    var b = index.getX(i + 1);
                    var c = index.getX(i + 2);
                    intersection = checkGeometryIntersection(this, material, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c);
                    if (intersection != null) {
                        intersection.faceIndex = Math.floor(i / 3); // triangle number in indexed buffer semantics
                        intersects.push(intersection);
                    }
                }
            }
        } else if (position != null) {
            // non-indexed buffer geometry
            if (material is Array<MeshBasicMaterial>) {
                var il = groups.length;
                for (var i = 0; i < il; i++) {
                    var group = groups[i];
                    var groupMaterial = material[group.materialIndex];
                    var start = Math.max(group.start, drawRange.start);
                    var end = Math.min(position.count, Math.min(group.start + group.count, drawRange.start + drawRange.count));
                    var jl = end - start;
                    for (var j = start; j < end; j += 3) {
                        var a = j;
                        var b = j + 1;
                        var c = j + 2;
                        intersection = checkGeometryIntersection(this, groupMaterial, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c);
                        if (intersection != null) {
                            intersection.faceIndex = Math.floor(j / 3); // triangle number in non-indexed buffer semantics
                            intersection.face.materialIndex = group.materialIndex;
                            intersects.push(intersection);
                        }
                    }
                }
            } else {
                var start = Math.max(0, drawRange.start);
                var end = Math.min(position.count, drawRange.start + drawRange.count);
                var il = end - start;
                for (var i = start; i < end; i += 3) {
                    var a = i;
                    var b = i + 1;
                    var c = i + 2;
                    intersection = checkGeometryIntersection(this, material, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c);
                    if (intersection != null) {
                        intersection.faceIndex = Math.floor(i / 3); // triangle number in non-indexed buffer semantics
                        intersects.push(intersection);
                    }
                }
            }
        }
    }
}

function checkIntersection(object:Dynamic, material:Dynamic, raycaster:Dynamic, ray:Dynamic, pA:Dynamic, pB:Dynamic, pC:Dynamic, point:Dynamic) {
    var intersect:Dynamic;
    if (material.side == BackSide) {
        intersect = ray.intersectTriangle(pC, pB, pA, true, point);
    } else {
        intersect = ray.intersectTriangle(pA, pB, pC, material.side == FrontSide, point);
    }
    if (intersect == null) return null;
    _intersectionPointWorld.copy(point);
    _intersectionPointWorld.applyMatrix4(object.matrixWorld);
    var distance = raycaster.ray.origin.distanceTo(_intersectionPointWorld);
    if (distance < raycaster.near || distance > raycaster.far) return null;
    return { distance: distance, point: _intersectionPointWorld.clone(), object: object };
}

function checkGeometryIntersection(object:Dynamic, material:Dynamic, raycaster:Dynamic, ray:Dynamic, uv:Dynamic, uv1:Dynamic, normal:Dynamic, a:Int, b:Int, c:Int) {
    object.getVertexPosition(a, _vA);
    object.getVertexPosition(b, _vB);
    object.getVertexPosition(c, _vC);
    var intersection = checkIntersection(object, material, raycaster, ray, _vA, _vB, _vC, _intersectionPoint);
    if (intersection != null) {
        if (uv != null) {
            _uvA.fromBufferAttribute(uv, a);
            _uvB.fromBufferAttribute(uv, b);
            _uvC.fromBufferAttribute(uv, c);
            intersection.uv = Triangle.getInterpolation(_intersectionPoint, _vA, _vB, _vC, _uvA, _uvB, _uvC, new Vector2());
        }
        if (uv1 != null) {
            _uvA.fromBufferAttribute(uv1, a);
            _uvB.fromBufferAttribute(uv1, b);
            _uvC.fromBufferAttribute(uv1, c);
            intersection.uv1 = Triangle.getInterpolation(_intersectionPoint, _vA, _vB, _vC, _uvA, _uvB, _uvC, new Vector2());
        }
        if (normal != null) {
            _normalA.fromBufferAttribute(normal, a);
            _normalB.fromBufferAttribute(normal, b);
            _normalC.fromBufferAttribute(normal, c);
            intersection.normal = Triangle.getInterpolation(_intersectionPoint, _vA, _vB, _vC, _normalA, _normalB, _normalC, new Vector3());
            if (intersection.normal.dot(ray.direction) > 0) {
                intersection.normal.multiplyScalar(-1);
            }
        }
        var face = { a: a, b: b, c: c, normal: new Vector3(), materialIndex: 0 };
        Triangle.getNormal(_vA, _vB, _vC, face.normal);
        intersection.face = face;
    }
    return intersection;
}

class Mesh {
}