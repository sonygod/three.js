import three.js.extras.core.Matrix4;
import three.js.extras.objects.Mesh;
import three.js.extras.materials.MeshBasicMaterial;
import three.js.extras.constants.EqualStencilFunc;
import three.js.extras.constants.IncrementStencilOp;

/**
 * A shadow Mesh that follows a shadow-casting Mesh in the scene, but is confined to a single plane.
 */

var _shadowMatrix:Matrix4 = new Matrix4();

class ShadowMesh extends Mesh {

	public var isShadowMesh:Bool = true;
	public var meshMatrix:Matrix4;

	public function new( mesh:Mesh ) {

		var shadowMaterial:MeshBasicMaterial = new MeshBasicMaterial( {

			color: 0x000000,
			transparent: true,
			opacity: 0.6,
			depthWrite: false,
			stencilWrite: true,
			stencilFunc: EqualStencilFunc,
			stencilRef: 0,
			stencilZPass: IncrementStencilOp

		} );

		super( mesh.geometry, shadowMaterial );

		this.isShadowMesh = true;

		this.meshMatrix = mesh.matrixWorld;

		this.frustumCulled = false;
		this.matrixAutoUpdate = false;

	}

	public function update( plane, lightPosition4D ) {

		// based on https://www.opengl.org/archives/resources/features/StencilTalk/tsld021.htm

		var dot = plane.normal.x * lightPosition4D.x +
			  plane.normal.y * lightPosition4D.y +
			  plane.normal.z * lightPosition4D.z +
			  - plane.constant * lightPosition4D.w;

		var sme = _shadowMatrix.elements;

		sme[ 0 ] = dot - lightPosition4D.x * plane.normal.x;
		sme[ 4 ] = - lightPosition4D.x * plane.normal.y;
		sme[ 8 ] = - lightPosition4D.x * plane.normal.z;
		sme[ 12 ] = - lightPosition4D.x * - plane.constant;

		sme[ 1 ] = - lightPosition4D.y * plane.normal.x;
		sme[ 5 ] = dot - lightPosition4D.y * plane.normal.y;
		sme[ 9 ] = - lightPosition4D.y * plane.normal.z;
		sme[ 13 ] = - lightPosition4D.y * - plane.constant;

		sme[ 2 ] = - lightPosition4D.z * plane.normal.x;
		sme[ 6 ] = - lightPosition4D.z * plane.normal.y;
		sme[ 10 ] = dot - lightPosition4D.z * plane.normal.z;
		sme[ 14 ] = - lightPosition4D.z * - plane.constant;

		sme[ 3 ] = - lightPosition4D.w * plane.normal.x;
		sme[ 7 ] = - lightPosition4D.w * plane.normal.y;
		sme[ 11 ] = - lightPosition4D.w * plane.normal.z;
		sme[ 15 ] = dot - lightPosition4D.w * - plane.constant;

		this.matrix.multiplyMatrices( _shadowMatrix, this.meshMatrix );

	}

}

export haxe.extern.module("three.js.examples.jsm.objects.ShadowMesh") {
	public class ShadowMesh extends three.js.extras.objects.Mesh {
		public var isShadowMesh:Bool;
		public var meshMatrix:three.js.extras.core.Matrix4;
		public function new(mesh:three.js.extras.objects.Mesh);
		public function update(plane:Dynamic, lightPosition4D:Dynamic);
	}
}