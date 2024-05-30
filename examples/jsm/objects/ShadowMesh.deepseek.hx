import three.Matrix4;
import three.Mesh;
import three.MeshBasicMaterial;
import three.EqualStencilFunc;
import three.IncrementStencilOp;

class ShadowMesh extends Mesh {

	var _shadowMatrix:Matrix4;

	public function new(mesh:Mesh) {

		var shadowMaterial = new MeshBasicMaterial({
			color: 0x000000,
			transparent: true,
			opacity: 0.6,
			depthWrite: false,
			stencilWrite: true,
			stencilFunc: EqualStencilFunc,
			stencilRef: 0,
			stencilZPass: IncrementStencilOp
		});

		super(mesh.geometry, shadowMaterial);

		this.isShadowMesh = true;

		this.meshMatrix = mesh.matrixWorld;

		this.frustumCulled = false;
		this.matrixAutoUpdate = false;

		this._shadowMatrix = new Matrix4();
	}

	public function update(plane:Dynamic, lightPosition4D:Dynamic) {

		var dot = plane.normal.x * lightPosition4D.x +
			  plane.normal.y * lightPosition4D.y +
			  plane.normal.z * lightPosition4D.z +
			  - plane.constant * lightPosition4D.w;

		var sme = this._shadowMatrix.elements;

		sme[0] = dot - lightPosition4D.x * plane.normal.x;
		sme[4] = - lightPosition4D.x * plane.normal.y;
		sme[8] = - lightPosition4D.x * plane.normal.z;
		sme[12] = - lightPosition4D.x * - plane.constant;

		sme[1] = - lightPosition4D.y * plane.normal.x;
		sme[5] = dot - lightPosition4D.y * plane.normal.y;
		sme[9] = - lightPosition4D.y * plane.normal.z;
		sme[13] = - lightPosition4D.y * - plane.constant;

		sme[2] = - lightPosition4D.z * plane.normal.x;
		sme[6] = - lightPosition4D.z * plane.normal.y;
		sme[10] = dot - lightPosition4D.z * plane.normal.z;
		sme[14] = - lightPosition4D.z * - plane.constant;

		sme[3] = - lightPosition4D.w * plane.normal.x;
		sme[7] = - lightPosition4D.w * plane.normal.y;
		sme[11] = - lightPosition4D.w * plane.normal.z;
		sme[15] = dot - lightPosition4D.w * - plane.constant;

		this.matrix.multiplyMatrices(this._shadowMatrix, this.meshMatrix);
	}
}