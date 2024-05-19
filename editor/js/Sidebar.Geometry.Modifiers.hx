package three.js.editor.js;

import js.threeEDITOR.ui.UIDiv;
import js.threeEDITOR.ui.UIButton;
import js.threeEDITOR.ui.UIRow;

import js.three.addons.utils.BufferGeometryUtils;
import js.three.addons.libs.MikkTSpace;

class SidebarGeometryModifiers {
    public function new(editor:Editor, object:Object3D) {
        var strings = editor.strings;
        var signals = editor.signals;

        var container = new UIDiv();
        container.marginLeft = '120px';

        var geometry = object.geometry;

        // Compute Vertex Normals

        var computeVertexNormalsButton = new UIButton(strings.getKey('sidebar/geometry/compute_vertex_normals'));
        computeVertexNormalsButton.onClick(function() {
            geometry.computeVertexNormals();
            signals.geometryChanged.dispatch(object);
        });

        var computeVertexNormalsRow = new UIRow();
        computeVertexNormalsRow.add(computeVertexNormalsButton);
        container.add(computeVertexNormalsRow);

        // Compute Vertex Tangents

        if (geometry.hasAttribute('position') && geometry.hasAttribute('normal') && geometry.hasAttribute('uv')) {
            var computeVertexTangentsButton = new UIButton(strings.getKey('sidebar/geometry/compute_vertex_tangents'));
            computeVertexTangentsButton.onClick(function() {
                MikkTSpace.ready.then(function() {
                    BufferGeometryUtils.computeMikkTSpaceTangents(geometry, MikkTSpace);
                    signals.geometryChanged.dispatch(object);
                });
            });

            var computeVertexTangentsRow = new UIRow();
            computeVertexTangentsRow.add(computeVertexTangentsButton);
            container.add(computeVertexTangentsRow);
        }

        // Center Geometry

        var centerButton = new UIButton(strings.getKey('sidebar/geometry/center'));
        centerButton.onClick(function() {
            geometry.center();
            signals.geometryChanged.dispatch(object);
        });

        var centerRow = new UIRow();
        centerRow.add(centerButton);
        container.add(centerRow);

        return container;
    }
}

// Export the class
extern class SidebarGeometryModifiers {}