import three.js.editor.js.Sidebar.Geometry.Modifiers.libs.ui.UIDiv;
import three.js.editor.js.Sidebar.Geometry.Modifiers.libs.ui.UIButton;
import three.js.editor.js.Sidebar.Geometry.Modifiers.libs.ui.UIRow;

import three.js.addons.utils.BufferGeometryUtils.computeMikkTSpaceTangents;
import three.js.addons.libs.mikktspace.MikkTSpace;

class SidebarGeometryModifiers {

    public function new(editor:Dynamic, object:Dynamic) {

        var strings = editor.strings;

        var signals = editor.signals;

        var container = new UIDiv().setMarginLeft('120px');

        var geometry = object.geometry;

        // Compute Vertex Normals

        var computeVertexNormalsButton = new UIButton(strings.getKey('sidebar/geometry/compute_vertex_normals'));
        computeVertexNormalsButton.onClick(function () {

            geometry.computeVertexNormals();

            signals.geometryChanged.dispatch(object);

        });

        var computeVertexNormalsRow = new UIRow();
        computeVertexNormalsRow.add(computeVertexNormalsButton);
        container.add(computeVertexNormalsRow);

        // Compute Vertex Tangents

        if (geometry.hasAttribute('position') && geometry.hasAttribute('normal') && geometry.hasAttribute('uv')) {

            var computeVertexTangentsButton = new UIButton(strings.getKey('sidebar/geometry/compute_vertex_tangents'));
            computeVertexTangentsButton.onClick(function () {

                MikkTSpace.ready.then(function () {

                    computeMikkTSpaceTangents(geometry, MikkTSpace);

                    signals.geometryChanged.dispatch(object);

                });

            });

            var computeVertexTangentsRow = new UIRow();
            computeVertexTangentsRow.add(computeVertexTangentsButton);
            container.add(computeVertexTangentsRow);

        }

        // Center Geometry

        var centerButton = new UIButton(strings.getKey('sidebar/geometry/center'));
        centerButton.onClick(function () {

            geometry.center();

            signals.geometryChanged.dispatch(object);

        });

        var centerRow = new UIRow();
        centerRow.add(centerButton);
        container.add(centerRow);

        //

        return container;

    }

}