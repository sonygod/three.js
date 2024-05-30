package three.test.unit.src.objects;

import three.core.Object3D;
import three.objects.Mesh;
import three.objects.SkinnedMesh;
import three.constants.AttachedBindMode;

class SkinnedMeshTests {

	#if (utest)

	 public function new() {}

	 public function testExtending() {
	  var skinnedMesh:SkinnedMesh = new SkinnedMesh();
	  utest.Assert.isTrue(skinnedMesh instanceof Object3D, 'SkinnedMesh extends from Object3D');
	  utest.Assert.isTrue(skinnedMesh instanceof Mesh, 'SkinnedMesh extends from Mesh');
	 }

	 public function testInstancing() {
	  var object:SkinnedMesh = new SkinnedMesh();
	  utest.Assert.notNull(object, 'Can instantiate a SkinnedMesh.');
	 }

	 public function testType() {
	  var object:SkinnedMesh = new SkinnedMesh();
	  utest.Assert.equals(object.type, 'SkinnedMesh', 'SkinnedMesh.type should be SkinnedMesh');
	 }

	 public function testBindMode() {
	  var object:SkinnedMesh = new SkinnedMesh();
	  utest.Assert.equals(object.bindMode, AttachedBindMode, 'SkinnedMesh.bindMode should be AttachedBindMode');
	 }

	 public function todo_bindMatrix() {
	  utest.Assert.fail('todo: implement me!');
	 }

	 public function todo_bindMatrixInverse() {
	  utest.Assert.fail('todo: implement me!');
	 }

	 public function testIsSkinnedMesh() {
	  var object:SkinnedMesh = new SkinnedMesh();
	  utest.Assert.isTrue(object.isSkinnedMesh, 'SkinnedMesh.isSkinnedMesh should be true');
	 }

	 public function todo_copy() {
	  utest.Assert.fail('todo: implement me!');
	 }

	 public function todo_bind() {
	  utest.Assert.fail('todo: implement me!');
	 }

	 public function todo_pose() {
	  utest.Assert.fail('todo: implement me!');
	 }

	 public function todo_normalizeSkinWeights() {
	  utest.Assert.fail('todo: implement me!');
	 }

	 public function todo_updateMatrixWorld() {
	  utest.Assert.fail('todo: implement me!');
	 }

	 public function todo_applyBoneTransform() {
	  utest.Assert.fail('todo: implement me!');
	 }

	#end

}