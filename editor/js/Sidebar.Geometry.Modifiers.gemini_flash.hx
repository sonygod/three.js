import three.ThreeImports.*;
import three.addons.utils.BufferGeometryUtils.computeMikkTSpaceTangents;
import three.addons.libs.mikktspace.MikkTSpace;

class SidebarGeometryModifiers extends UIDiv {

	public function new(editor : Editor, object : Object3D) {
		super();
		this.marginLeft = '120px';

		var strings = editor.strings;
		var signals = editor.signals;
		var geometry = cast(object.geometry, BufferGeometry);

		// Compute Vertex Normals

		var computeVertexNormalsButton = new UIButton(strings.getKey('sidebar/geometry/compute_vertex_normals'));
		computeVertexNormalsButton.onClick = function(_) {
			geometry.computeVertexNormals();
			signals.geometryChanged.dispatch(object);
		};

		var computeVertexNormalsRow = new UIRow();
		computeVertexNormalsRow.add(computeVertexNormalsButton);
		this.add(computeVertexNormalsRow);

		// Compute Vertex Tangents

		if (geometry.hasAttribute('position') && geometry.hasAttribute('normal') && geometry.hasAttribute('uv')) {

			var computeVertexTangentsButton = new UIButton(strings.getKey('sidebar/geometry/compute_vertex_tangents'));
			computeVertexTangentsButton.onClick = async function(_) {
				await MikkTSpace.ready;
				computeMikkTSpaceTangents(geometry, MikkTSpace);
				signals.geometryChanged.dispatch(object);
			};

			var computeVertexTangentsRow = new UIRow();
			computeVertexTangentsRow.add(computeVertexTangentsButton);
			this.add(computeVertexTangentsRow);

		}

		// Center Geometry

		var centerButton = new UIButton(strings.getKey('sidebar/geometry/center'));
		centerButton.onClick = function(_) {
			geometry.center();
			signals.geometryChanged.dispatch(object);
		};

		var centerRow = new UIRow();
		centerRow.add(centerButton);
		this.add(centerRow);

	}

}