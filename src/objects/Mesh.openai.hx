package three.objects;

import three.math.Vector3;
import three.math.Vector2;
import three.math.Sphere;
import three.math.Ray;
import three.math.Matrix4;
import three.core.Object3D;
import three.math.Triangle;
import three.constants.Side;
import three.materials.MeshBasicMaterial;
import three.core.BufferGeometry;

class Mesh extends Object3D {
    public var isMesh:Bool = true;
    public var type:String = 'Mesh';
    public var geometry:BufferGeometry;
    public var material:MeshBasicMaterial;
    public var morphTargetInfluences:Array<Float>;
    public var morphTargetDictionary:Map<String, Int>;

    private var _inverseMatrix:Matrix4;
    private var _ray:Ray;
    private var _sphere:Sphere;
    private var _sphereHitAt:Vector3;

    private var _vA:Vector3;
    private var _vB:Vector3;
    private var _vC:Vector3;

    private var _tempA:Vector3;
    private var _morphA:Vector3;

    private var _uvA:Vector2;
    private var _uvB:Vector2;
    private var _uvC:Vector2;

    private var _normalA:Vector3;
    private var _normalB:Vector3;
    private var _normalC:Vector3;

    private var _intersectionPoint:Vector3;
    private var _intersectionPointWorld:Vector3;

    public function new(geometry:BufferGeometry = null, material:MeshBasicMaterial = null) {
        super();
        this.geometry = geometry != null ? geometry : new BufferGeometry();
        this.material = material != null ? material : new MeshBasicMaterial();
        updateMorphTargets();
    }

    override public function copy(source:Object3D, recursive:Bool = false):Object3D {
        super.copy(source, recursive);
        if (source.morphTargetInfluences != null) {
            morphTargetInfluences = source.morphTargetInfluences.copy();
        }
        if (source.morphTargetDictionary != null) {
            morphTargetDictionary = Lambda.clone(source.morphTargetDictionary);
        }
        material = source.material.clone();
        geometry = source.geometry;
        return this;
    }

    public function updateMorphTargets():Void {
        var geometry:BufferGeometry = this.geometry;
        var morphAttributes:Map<String, Array<Vector3>> = geometry.morphAttributes;
        if (morphAttributes != null && morphAttributes.keys().length > 0) {
            var morphAttribute:Array<Vector3> = morphAttributes.iterator().next();
            morphTargetInfluences = [];
            morphTargetDictionary = new Map<String, Int>();
            for (i in 0...morphAttribute.length) {
                var name:String = morphAttribute[i].name != null ? morphAttribute[i].name : Std.string(i);
                morphTargetInfluences.push(0);
                morphTargetDictionary.set(name, i);
            }
        }
    }

    public function getVertexPosition(index:Int, target:Vector3):Vector3 {
        var geometry:BufferGeometry = this.geometry;
        var position:BufferAttribute = geometry.attributes.position;
        var morphPosition:BufferAttribute = geometry.morphAttributes.position;
        var morphTargetsRelative:Bool = geometry.morphTargetsRelative;

        target.fromBufferAttribute(position, index);

        if (morphPosition != null && morphTargetInfluences != null) {
            _morphA.set(0, 0, 0);
            for (i in 0...morphPosition.length) {
                var influence:Float = morphTargetInfluences[i];
                if (influence == 0) continue;
                var morphAttribute:BufferAttribute = morphPosition[i];
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

    public function raycast(raycaster:Raycaster, intersects:Array<RaycastIntersection>):Void {
        var geometry:BufferGeometry = this.geometry;
        var material:MeshBasicMaterial = this.material;
        if (material == null) return;

        _sphere.copy(geometry.boundingSphere);
        _sphere.applyMatrix4(matrixWorld);

        _ray.copy(raycaster.ray).recast(raycaster.near);

        if (!_sphere.containsPoint(_ray.origin)) {
            if (_ray.intersectSphere(_sphere, _sphereHitAt) == null) return;
            if (_ray.origin.distanceToSquared(_sphereHitAt) > Math.pow(raycaster.far - raycaster.near, 2)) return;
        }

        _inverseMatrix.copy(matrixWorld).invert();
        _ray.copy(raycaster.ray).applyMatrix4(_inverseMatrix);

        if (geometry.boundingBox != null) {
            if (!_ray.intersectsBox(geometry.boundingBox)) return;
        }

        _computeIntersections(raycaster, intersects, _ray);
    }

    private function _computeIntersections(raycaster:Raycaster, intersects:Array<RaycastIntersection>, rayLocalSpace:Ray):Void {
        var geometry:BufferGeometry = this.geometry;
        var material:MeshBasicMaterial = this.material;

        var index:BufferAttribute = geometry.index;
        var position:BufferAttribute = geometry.attributes.position;
        var uv:BufferAttribute = geometry.attributes.uv;
        var uv1:BufferAttribute = geometry.attributes.uv1;
        var normal:BufferAttribute = geometry.attributes.normal;
        var groups:Array<Group> = geometry.groups;
        var drawRange:DrawRange = geometry.drawRange;

        if (index != null) {
            // indexed buffer geometry
            if (Std.is(material, Array)) {
                for (group in groups) {
                    var groupMaterial:MeshBasicMaterial = material[cast group.materialIndex];
                    var start:Int = Math.max(group.start, drawRange.start);
                    var end:Int = Math.min(index.count, Math.min(group.start + group.count, drawRange.start + drawRange.count));
                    for (i in start...end) {
                        var a:Int = index.getX(i);
                        var b:Int = index.getX(i + 1);
                        var c:Int = index.getX(i + 2);
                        var intersection:RaycastIntersection = checkGeometryIntersection(this, groupMaterial, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c);
                        if (intersection != null) {
                            intersection.faceIndex = Math.floor(i / 3); // triangle number in indexed buffer semantics
                            intersection.face.materialIndex = group.materialIndex;
                            intersects.push(intersection);
                        }
                    }
                }
            } else {
                var start:Int = Math.max(0, drawRange.start);
                var end:Int = Math.min(index.count, drawRange.start + drawRange.count);
                for (i in start...end) {
                    var a:Int = index.getX(i);
                    var b:Int = index.getX(i + 1);
                    var c:Int = index.getX(i + 2);
                    var intersection:RaycastIntersection = checkGeometryIntersection(this, material, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c);
                    if (intersection != null) {
                        intersection.faceIndex = Math.floor(i / 3); // triangle number in indexed buffer semantics
                        intersects.push(intersection);
                    }
                }
            }
        } else if (position != null) {
            // non-indexed buffer geometry
            if (Std.is(material, Array)) {
                for (group in groups) {
                    var groupMaterial:MeshBasicMaterial = material[cast group.materialIndex];
                    var start:Int = Math.max(group.start, drawRange.start);
                    var end:Int = Math.min(position.count, Math.min(group.start + group.count, drawRange.start + drawRange.count));
                    for (i in start...end) {
                        var a:Int = i;
                        var b:Int = i + 1;
                        var c:Int = i + 2;
                        var intersection:RaycastIntersection = checkGeometryIntersection(this, groupMaterial, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c);
                        if (intersection != null) {
                            intersection.faceIndex = Math.floor(i / 3); // triangle number in non-indexed buffer semantics
                            intersection.face.materialIndex = group.materialIndex;
                            intersects.push(intersection);
                        }
                    }
                }
            } else {
                var start:Int = Math.max(0, drawRange.start);
                var end:Int = Math.min(position.count, drawRange.start + drawRange.count);
                for (i in start...end) {
                    var a:Int = i;
                    var b:Int = i + 1;
                    var c:Int = i + 2;
                    var intersection:RaycastIntersection = checkGeometryIntersection(this, material, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c);
                    if (intersection != null) {
                        intersection.faceIndex = Math.floor(i / 3); // triangle number in non-indexed buffer semantics
                        intersects.push(intersection);
                    }
                }
            }
        }
    }
}

private function checkIntersection(object:Object3D, material:MeshBasicMaterial, raycaster:Raycaster, ray:Ray, pA:Vector3, pB:Vector3, pC:Vector3, point:Vector3):RaycastIntersection {
    var intersect:RaycastIntersection;
    if (material.side == BackSide) {
        intersect = ray.intersectTriangle(pC, pB, pA, true, point);
    } else {
        intersect = ray.intersectTriangle(pA, pB, pC, material.side == FrontSide, point);
    }
    if (intersect == null) return null;

    _intersectionPointWorld.copy(point);
    _intersectionPointWorld.applyMatrix4(object.matrixWorld);

    var distance:Float = raycaster.ray.origin.distanceTo(_intersectionPointWorld);
    if (distance < raycaster.near || distance > raycaster.far) return null;

    return {
        distance: distance,
        point: _intersectionPointWorld.clone(),
        object: object
    };
}

private function checkGeometryIntersection(object:Object3D, material:MeshBasicMaterial, raycaster:Raycaster, ray:Ray, uv:BufferAttribute, uv1:BufferAttribute, normal:BufferAttribute, a:Int, b:Int, c:Int):RaycastIntersection {
    object.getVertexPosition(a, _vA);
    object.getVertexPosition(b, _vB);
    object.getVertexPosition(c, _vC);

    var intersection:RaycastIntersection = checkIntersection(object, material, raycaster, ray, _vA, _vB, _vC, _intersectionPoint);

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

        var face:Face = {
            a: a,
            b: b,
            c: c,
            normal: new Vector3(),
            materialIndex: 0
        };
        Triangle.getNormal(_vA, _vB, _vC, face.normal);

        intersection.face = face;
    }
    return intersection;
}