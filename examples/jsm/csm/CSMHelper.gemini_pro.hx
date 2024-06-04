import three.core.Group;
import three.objects.Mesh;
import three.objects.LineSegments;
import three.geometries.BufferGeometry;
import three.materials.LineBasicMaterial;
import three.helpers.Box3Helper;
import three.math.Box3;
import three.geometries.PlaneGeometry;
import three.materials.MeshBasicMaterial;
import three.core.BufferAttribute;
import three.constants.Side;

class CSMHelper extends Group {

	public var csm:Dynamic;
	public var displayFrustum:Bool = true;
	public var displayPlanes:Bool = true;
	public var displayShadowBounds:Bool = true;
	public var frustumLines:LineSegments;
	public var cascadeLines:Array<Box3Helper> = [];
	public var cascadePlanes:Array<Mesh> = [];
	public var shadowLines:Array<Group> = [];

	public function new(csm:Dynamic) {
		super();
		this.csm = csm;
		var indices = new Uint16Array([0, 1, 1, 2, 2, 3, 3, 0, 4, 5, 5, 6, 6, 7, 7, 4, 0, 4, 1, 5, 2, 6, 3, 7]);
		var positions = new Float32Array(24);
		var frustumGeometry = new BufferGeometry();
		frustumGeometry.setIndex(new BufferAttribute(indices, 1));
		frustumGeometry.setAttribute('position', new BufferAttribute(positions, 3, false));
		frustumLines = new LineSegments(frustumGeometry, new LineBasicMaterial());
		this.add(frustumLines);
		this.frustumLines = frustumLines;
	}

	public function updateVisibility():Void {
		var displayFrustum = this.displayFrustum;
		var displayPlanes = this.displayPlanes;
		var displayShadowBounds = this.displayShadowBounds;

		var frustumLines = this.frustumLines;
		var cascadeLines = this.cascadeLines;
		var cascadePlanes = this.cascadePlanes;
		var shadowLines = this.shadowLines;
		for (i in 0...cascadeLines.length) {
			var cascadeLine = cascadeLines[i];
			var cascadePlane = cascadePlanes[i];
			var shadowLineGroup = shadowLines[i];

			cascadeLine.visible = displayFrustum;
			cascadePlane.visible = displayFrustum && displayPlanes;
			shadowLineGroup.visible = displayShadowBounds;
		}

		frustumLines.visible = displayFrustum;
	}

	public function update():Void {
		var csm = this.csm;
		var camera = csm.camera;
		var cascades = csm.cascades;
		var mainFrustum = csm.mainFrustum;
		var frustums = csm.frustums;
		var lights = csm.lights;

		var frustumLines = this.frustumLines;
		var frustumLinePositions = frustumLines.geometry.getAttribute('position');
		var cascadeLines = this.cascadeLines;
		var cascadePlanes = this.cascadePlanes;
		var shadowLines = this.shadowLines;

		this.position.copy(camera.position);
		this.quaternion.copy(camera.quaternion);
		this.scale.copy(camera.scale);
		this.updateMatrixWorld(true);

		while (cascadeLines.length > cascades) {
			this.remove(cascadeLines.pop());
			this.remove(cascadePlanes.pop());
			this.remove(shadowLines.pop());
		}

		while (cascadeLines.length < cascades) {
			var cascadeLine = new Box3Helper(new Box3(), 0xffffff);
			var planeMat = new MeshBasicMaterial({transparent: true, opacity: 0.1, depthWrite: false, side: Side.DoubleSide});
			var cascadePlane = new Mesh(new PlaneGeometry(), planeMat);
			var shadowLineGroup = new Group();
			var shadowLine = new Box3Helper(new Box3(), 0xffff00);
			shadowLineGroup.add(shadowLine);

			this.add(cascadeLine);
			this.add(cascadePlane);
			this.add(shadowLineGroup);

			cascadeLines.push(cascadeLine);
			cascadePlanes.push(cascadePlane);
			shadowLines.push(shadowLineGroup);
		}

		for (i in 0...cascades) {
			var frustum = frustums[i];
			var light = lights[i];
			var shadowCam = light.shadow.camera;
			var farVerts = frustum.vertices.far;

			var cascadeLine = cascadeLines[i];
			var cascadePlane = cascadePlanes[i];
			var shadowLineGroup = shadowLines[i];
			var shadowLine = shadowLineGroup.children[0];

			cascadeLine.box.min.copy(farVerts[2]);
			cascadeLine.box.max.copy(farVerts[0]);
			cascadeLine.box.max.z += 1e-4;

			cascadePlane.position.addVectors(farVerts[0], farVerts[2]);
			cascadePlane.position.multiplyScalar(0.5);
			cascadePlane.scale.subVectors(farVerts[0], farVerts[2]);
			cascadePlane.scale.z = 1e-4;

			this.remove(shadowLineGroup);
			shadowLineGroup.position.copy(shadowCam.position);
			shadowLineGroup.quaternion.copy(shadowCam.quaternion);
			shadowLineGroup.scale.copy(shadowCam.scale);
			shadowLineGroup.updateMatrixWorld(true);
			this.attach(shadowLineGroup);

			shadowLine.box.min.set(shadowCam.bottom, shadowCam.left, -shadowCam.far);
			shadowLine.box.max.set(shadowCam.top, shadowCam.right, -shadowCam.near);
		}

		var nearVerts = mainFrustum.vertices.near;
		var farVerts = mainFrustum.vertices.far;
		frustumLinePositions.setXYZ(0, farVerts[0].x, farVerts[0].y, farVerts[0].z);
		frustumLinePositions.setXYZ(1, farVerts[3].x, farVerts[3].y, farVerts[3].z);
		frustumLinePositions.setXYZ(2, farVerts[2].x, farVerts[2].y, farVerts[2].z);
		frustumLinePositions.setXYZ(3, farVerts[1].x, farVerts[1].y, farVerts[1].z);

		frustumLinePositions.setXYZ(4, nearVerts[0].x, nearVerts[0].y, nearVerts[0].z);
		frustumLinePositions.setXYZ(5, nearVerts[3].x, nearVerts[3].y, nearVerts[3].z);
		frustumLinePositions.setXYZ(6, nearVerts[2].x, nearVerts[2].y, nearVerts[2].z);
		frustumLinePositions.setXYZ(7, nearVerts[1].x, nearVerts[1].y, nearVerts[1].z);
		frustumLinePositions.needsUpdate = true;
	}

	public function dispose():Void {
		var frustumLines = this.frustumLines;
		var cascadeLines = this.cascadeLines;
		var cascadePlanes = this.cascadePlanes;
		var shadowLines = this.shadowLines;

		frustumLines.geometry.dispose();
		frustumLines.material.dispose();

		var cascades = this.csm.cascades;

		for (i in 0...cascades) {
			var cascadeLine = cascadeLines[i];
			var cascadePlane = cascadePlanes[i];
			var shadowLineGroup = shadowLines[i];
			var shadowLine = shadowLineGroup.children[0];

			cascadeLine.dispose();
			cascadePlane.geometry.dispose();
			cascadePlane.material.dispose();
			shadowLine.dispose();
		}
	}

}