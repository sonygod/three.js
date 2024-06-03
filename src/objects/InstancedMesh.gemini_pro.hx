import three.core.InstancedBufferAttribute;
import three.objects.Mesh;
import three.math.Box3;
import three.math.Matrix4;
import three.math.Sphere;
import three.textures.DataTexture;
import three.constants.FloatType;
import three.constants.RedFormat;

class InstancedMesh extends Mesh {
  public var instanceMatrix:InstancedBufferAttribute;
  public var instanceColor:InstancedBufferAttribute;
  public var morphTexture:DataTexture;
  public var count:Int;
  public var boundingBox:Box3;
  public var boundingSphere:Sphere;

  public var isInstancedMesh:Bool = true;

  public function new(geometry:Mesh, material:Dynamic, count:Int) {
    super(geometry, material);
    this.instanceMatrix = new InstancedBufferAttribute(new Float32Array(count * 16), 16);
    this.count = count;

    for (var i in 0...count) {
      this.setMatrixAt(i, new Matrix4());
    }
  }

  public function computeBoundingBox():Void {
    var geometry = this.geometry;
    var count = this.count;
    if (this.boundingBox == null) {
      this.boundingBox = new Box3();
    }
    if (geometry.boundingBox == null) {
      geometry.computeBoundingBox();
    }
    this.boundingBox.makeEmpty();
    for (var i in 0...count) {
      this.getMatrixAt(i, new Matrix4()).applyToBox(geometry.boundingBox, this.boundingBox);
    }
  }

  public function computeBoundingSphere():Void {
    var geometry = this.geometry;
    var count = this.count;
    if (this.boundingSphere == null) {
      this.boundingSphere = new Sphere();
    }
    if (geometry.boundingSphere == null) {
      geometry.computeBoundingSphere();
    }
    this.boundingSphere.makeEmpty();
    for (var i in 0...count) {
      this.getMatrixAt(i, new Matrix4()).applyToSphere(geometry.boundingSphere, this.boundingSphere);
    }
  }

  public function copy(source:InstancedMesh, recursive:Bool):InstancedMesh {
    super.copy(source, recursive);
    this.instanceMatrix = source.instanceMatrix.clone();
    if (source.morphTexture != null) {
      this.morphTexture = source.morphTexture.clone();
    }
    if (source.instanceColor != null) {
      this.instanceColor = source.instanceColor.clone();
    }
    this.count = source.count;
    if (source.boundingBox != null) {
      this.boundingBox = source.boundingBox.clone();
    }
    if (source.boundingSphere != null) {
      this.boundingSphere = source.boundingSphere.clone();
    }
    return this;
  }

  public function getColorAt(index:Int, color:Dynamic):Void {
    color.fromArray(this.instanceColor.array, index * 3);
  }

  public function getMatrixAt(index:Int, matrix:Matrix4):Void {
    matrix.fromArray(this.instanceMatrix.array, index * 16);
  }

  public function getMorphAt(index:Int, object:Dynamic):Void {
    var objectInfluences = object.morphTargetInfluences;
    var array = this.morphTexture.source.data.data;
    var len = objectInfluences.length + 1;
    var dataIndex = index * len + 1;
    for (var i in 0...objectInfluences.length) {
      objectInfluences[i] = array[dataIndex + i];
    }
  }

  public function raycast(raycaster:Dynamic, intersects:Array<Dynamic>):Void {
    var matrixWorld = this.matrixWorld;
    var raycastTimes = this.count;
    var _mesh:Mesh = new Mesh(this.geometry, this.material);
    if (_mesh.material == null) {
      return;
    }
    if (this.boundingSphere == null) {
      this.computeBoundingSphere();
    }
    var _sphere = this.boundingSphere.clone();
    _sphere.applyMatrix4(matrixWorld);
    if (raycaster.ray.intersectsSphere(_sphere) == false) {
      return;
    }
    for (var instanceId in 0...raycastTimes) {
      this.getMatrixAt(instanceId, new Matrix4()).multiplyMatrices(matrixWorld, _instanceWorldMatrix);
      _mesh.matrixWorld = _instanceWorldMatrix;
      _mesh.raycast(raycaster, _instanceIntersects);
      for (var i in 0..._instanceIntersects.length) {
        var intersect = _instanceIntersects[i];
        intersect.instanceId = instanceId;
        intersect.object = this;
        intersects.push(intersect);
      }
      _instanceIntersects.length = 0;
    }
  }

  public function setColorAt(index:Int, color:Dynamic):Void {
    if (this.instanceColor == null) {
      this.instanceColor = new InstancedBufferAttribute(new Float32Array(this.instanceMatrix.count * 3), 3);
    }
    color.toArray(this.instanceColor.array, index * 3);
  }

  public function setMatrixAt(index:Int, matrix:Matrix4):Void {
    matrix.toArray(this.instanceMatrix.array, index * 16);
  }

  public function setMorphAt(index:Int, object:Dynamic):Void {
    var objectInfluences = object.morphTargetInfluences;
    var len = objectInfluences.length + 1;
    if (this.morphTexture == null) {
      this.morphTexture = new DataTexture(new Float32Array(len * this.count), len, this.count, RedFormat, FloatType);
    }
    var array = this.morphTexture.source.data.data;
    var morphInfluencesSum = 0;
    for (var i in 0...objectInfluences.length) {
      morphInfluencesSum += objectInfluences[i];
    }
    var morphBaseInfluence = this.geometry.morphTargetsRelative ? 1 : 1 - morphInfluencesSum;
    var dataIndex = len * index;
    array[dataIndex] = morphBaseInfluence;
    array.set(objectInfluences, dataIndex + 1);
  }

  public function updateMorphTargets():Void {
  }

  public function dispose():InstancedMesh {
    this.dispatchEvent({type: "dispose"});
    if (this.morphTexture != null) {
      this.morphTexture.dispose();
      this.morphTexture = null;
    }
    return this;
  }
}