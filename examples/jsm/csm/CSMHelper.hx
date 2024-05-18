package three.js.examples.jvm.csm;

import three.js.Group;
import three.js.Mesh;
import three.js.LineSegments;
import three.js.BufferGeometry;
import three.js.LineBasicMaterial;
import three.js.Box3Helper;
import three.js.Box3;
import three.js.PlaneGeometry;
import three.js.MeshBasicMaterial;
import three.js.BufferAttribute;
import three.js.DoubleSide;

class CSMHelper extends Group {

    public var csm:Dynamic;
    public var displayFrustum:Bool = true;
    public var displayPlanes:Bool = true;
    public var displayShadowBounds:Bool = true;

    public var frustumLines:LineSegments;
    public var cascadeLines:Array<Dynamic> = [];
    public var cascadePlanes:Array<Dynamic> = [];
    public var shadowLines:Array<Dynamic> = [];

    public function new(csm:Dynamic) {
        super();
        this.csm = csm;

        var indices:Array<Int> = [0, 1, 1, 2, 2, 3, 3, 0, 4, 5, 5, 6, 6, 7, 7, 4, 0, 4, 1, 5, 2, 6, 3, 7];
        var positions:Array<Float> = new Array<Float>(24);
        var frustumGeometry:BufferGeometry = new BufferGeometry();
        frustumGeometry.setIndex(new BufferAttribute(new Uint16Array(indices), 1));
        frustumGeometry.setAttribute('position', new BufferAttribute(new Float32Array(positions), 3, false));
        frustumLines = new LineSegments(frustumGeometry, new LineBasicMaterial());
        this.add(frustumLines);
    }

    public function updateVisibility() {
        var displayFrustum:Bool = this.displayFrustum;
        var displayPlanes:Bool = this.displayPlanes;
        var displayShadowBounds:Bool = this.displayShadowBounds;

        var frustumLines:LineSegments = this.frustumLines;
        var cascadeLines:Array<Dynamic> = this.cascadeLines;
        var cascadePlanes:Array<Dynamic> = this.cascadePlanes;
        var shadowLines:Array<Dynamic> = this.shadowLines;

        for (i in 0...cascadeLines.length) {
            var cascadeLine:Dynamic = cascadeLines[i];
            var cascadePlane:Dynamic = cascadePlanes[i];
            var shadowLineGroup:Dynamic = shadowLines[i];

            cascadeLine.visible = displayFrustum;
            cascadePlane.visible = displayFrustum && displayPlanes;
            shadowLineGroup.visible = displayShadowBounds;
        }

        frustumLines.visible = displayFrustum;
    }

    public function update() {
        var csm:Dynamic = this.csm;
        var camera:Dynamic = csm.camera;
        var cascades:Int = csm.cascades;
        var mainFrustum:Dynamic = csm.mainFrustum;
        var frustums:Array<Dynamic> = csm.frustums;
        var lights:Array<Dynamic> = csm.lights;

        var frustumLines:LineSegments = this.frustumLines;
        var frustumLinePositions:BufferAttribute = frustumLines.geometry.getAttribute('position');
        var cascadeLines:Array<Dynamic> = this.cascadeLines;
        var cascadePlanes:Array<Dynamic> = this.cascadePlanes;
        var shadowLines:Array<Dynamic> = this.shadowLines;

        this.position.copyFrom(camera.position);
        this.quaternion.copyFrom(camera.quaternion);
        this.scale.copyFrom(camera.scale);
        this.updateMatrixWorld(true);

        while (cascadeLines.length > cascades) {
            this.remove(cascadeLines.pop());
            this.remove(cascadePlanes.pop());
            this.remove(shadowLines.pop());
        }

        while (cascadeLines.length < cascades) {
            var cascadeLine:Box3Helper = new Box3Helper(new Box3(), 0xffffff);
            var planeMat:MeshBasicMaterial = new MeshBasicMaterial({ transparent: true, opacity: 0.1, depthWrite: false, side: DoubleSide });
            var cascadePlane:Mesh = new Mesh(new PlaneGeometry(), planeMat);
            var shadowLineGroup:Group = new Group();
            var shadowLine:Box3Helper = new Box3Helper(new Box3(), 0xffff00);
            shadowLineGroup.add(shadowLine);

            this.add(cascadeLine);
            this.add(cascadePlane);
            this.add(shadowLineGroup);

            cascadeLines.push(cascadeLine);
            cascadePlanes.push(cascadePlane);
            shadowLines.push(shadowLineGroup);
        }

        for (i in 0...cascades) {
            var frustum:Dynamic = frustums[i];
            var light:Dynamic = lights[i];
            var shadowCam:Dynamic = light.shadow.camera;
            var farVerts:Array<Dynamic> = frustum.vertices.far;

            var cascadeLine:Dynamic = cascadeLines[i];
            var cascadePlane:Dynamic = cascadePlanes[i];
            var shadowLineGroup:Dynamic = shadowLines[i];
            var shadowLine:Dynamic = shadowLineGroup.children[0];

            cascadeLine.box.min.copyFrom(farVerts[2]);
            cascadeLine.box.max.copyFrom(farVerts[0]);
            cascadeLine.box.max.z += 1e-4;

            cascadePlane.position.addVectors(farVerts[0], farVerts[2]);
            cascadePlane.position.multiplyScalar(0.5);
            cascadePlane.scale.subVectors(farVerts[0], farVerts[2]);
            cascadePlane.scale.z = 1e-4;

            this.remove(shadowLineGroup);
            shadowLineGroup.position.copyFrom(shadowCam.position);
            shadowLineGroup.quaternion.copyFrom(shadowCam.quaternion);
            shadowLineGroup.scale.copyFrom(shadowCam.scale);
            shadowLineGroup.updateMatrixWorld(true);
            this.attach(shadowLineGroup);

            shadowLine.box.min.set(shadowCam.bottom, shadowCam.left, -shadowCam.far);
            shadowLine.box.max.set(shadowCam.top, shadowCam.right, -shadowCam.near);
        }

        var nearVerts:Array<Dynamic> = mainFrustum.vertices.near;
        var farVerts:Array<Dynamic> = mainFrustum.vertices.far;
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

    public function dispose() {
        var frustumLines:LineSegments = this.frustumLines;
        var cascadeLines:Array<Dynamic> = this.cascadeLines;
        var cascadePlanes:Array<Dynamic> = this.cascadePlanes;
        var shadowLines:Array<Dynamic> = this.shadowLines;

        frustumLines.geometry.dispose();
        frustumLines.material.dispose();

        var cascades:Int = this.csm.cascades;

        for (i in 0...cascades) {
            var cascadeLine:Dynamic = cascadeLines[i];
            var cascadePlane:Dynamic = cascadePlanes[i];
            var shadowLineGroup:Dynamic = shadowLines[i];
            var shadowLine:Dynamic = shadowLineGroup.children[0];

            cascadeLine.dispose();

            cascadePlane.geometry.dispose();
            cascadePlane.material.dispose();

            shadowLine.dispose();
        }
    }
}