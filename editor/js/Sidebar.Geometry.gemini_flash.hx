package;

import three.THREE;
import three.math.MathUtils;
import three.geometries.BufferGeometry;
import three.helpers.VertexNormalsHelper;

import js.Lib;
import ui.UIPanel;
import ui.UIRow;
import ui.UIText;
import ui.UIInput;
import ui.UIButton;
import ui.UISpan;

import commands.SetGeometryValueCommand;

class SidebarGeometry {
	public var container:UIPanel;

	var editor:Editor;
	var strings:Map<String, String>;
	var signals:Signals;

	var currentGeometryType:String = null;

	public function new(editor:Editor) {
		this.editor = editor;
		strings = editor.strings;
		signals = editor.signals;

		container = new UIPanel();
		container.setBorderTop("0");
		container.setDisplay("none");
		container.setPaddingTop("20px");

		// type

		var geometryTypeRow = new UIRow();
		var geometryType = new UIText();

		geometryTypeRow.add(new UIText(strings.get("sidebar/geometry/type")).setClass("Label"));
		geometryTypeRow.add(geometryType);

		container.add(geometryTypeRow);

		// uuid

		var geometryUUIDRow = new UIRow();
		var geometryUUID = new UIInput().setWidth("102px").setFontSize("12px").setDisabled(true);
		var geometryUUIDRenew = new UIButton(strings.get("sidebar/geometry/new"))
			.setMarginLeft("7px")
			.onClick(function(_) {
				geometryUUID.setValue(MathUtils.generateUUID());
				editor.execute(new SetGeometryValueCommand(editor, editor.selected, "uuid", geometryUUID.getValue()));
			});

		geometryUUIDRow.add(new UIText(strings.get("sidebar/geometry/uuid")).setClass("Label"));
		geometryUUIDRow.add(geometryUUID);
		geometryUUIDRow.add(geometryUUIDRenew);

		container.add(geometryUUIDRow);

		// name

		var geometryNameRow = new UIRow();
		var geometryName = new UIInput().setWidth("150px").setFontSize("12px").onChange(function(_) {
			editor.execute(new SetGeometryValueCommand(editor, editor.selected, "name", geometryName.getValue()));
		});

		geometryNameRow.add(new UIText(strings.get("sidebar/geometry/name")).setClass("Label"));
		geometryNameRow.add(geometryName);

		container.add(geometryNameRow);

		// parameters

		var parameters = new UISpan();
		container.add(parameters);

		// buffergeometry

		container.add(new SidebarGeometryBufferGeometry(editor));

		// Size

		var geometryBoundingBox = new UIText().setFontSize("12px");

		var geometryBoundingBoxRow = new UIRow();
		geometryBoundingBoxRow.add(new UIText(strings.get("sidebar/geometry/bounds")).setClass("Label"));
		geometryBoundingBoxRow.add(geometryBoundingBox);
		container.add(geometryBoundingBoxRow);

		// Helpers

		var helpersRow = new UIRow().setMarginLeft("120px");
		container.add(helpersRow);

		var vertexNormalsButton = new UIButton(strings.get("sidebar/geometry/show_vertex_normals"));
		vertexNormalsButton.onClick(function(_) {
			var object = editor.selected;

			if (editor.helpers.exists(object.id)) {
				editor.removeHelper(object);
			} else {
				editor.addHelper(object, new VertexNormalsHelper(cast object));
			}

			signals.sceneGraphChanged.dispatch();
		});
		helpersRow.add(vertexNormalsButton);

		// Export JSON

		var exportJson = new UIButton(strings.get("sidebar/geometry/export"));
		exportJson.setMarginLeft("120px");
		exportJson.onClick(function(_) {
			var object = editor.selected;
			var geometry = object.geometry;

			var output = geometry.toJSON();

			try {
				output = JSON.stringify(output, null, "\t");
				output = ~/([\n\t]+)([\d\.e\-\[\]]+)/g.replace(output, "$1");
			} catch (e) {
				output = JSON.stringify(output);
			}

			editor.utils.save(new Blob([output]), '${geometryName.getValue() || "geometry"}.json');
		});
		container.add(exportJson);

		//

		signals.objectSelected.add(function(_) {
			currentGeometryType = null;
			build();
		});

		signals.geometryChanged.add(function(_) build());
	}

	function build() {
		var object = editor.selected;

		if (object != null && object.geometry != null) {
			var geometry = object.geometry;

			container.setDisplay("block");

			switch (geometry.type) {
				case "BufferGeometry":
					if (currentGeometryType != geometry.type) {
						// TODO: parameters.clear();
						// parameters.add( new SidebarGeometryModifiers( editor, object ) );

						currentGeometryType = geometry.type;
					}
				case _:
			}

			if (geometry.boundingBox == null) {
				geometry.computeBoundingBox();
			}

			var boundingBox = geometry.boundingBox;
			var x = Math.floor((boundingBox.max.x - boundingBox.min.x) * 1000) / 1000;
			var y = Math.floor((boundingBox.max.y - boundingBox.min.y) * 1000) / 1000;
			var z = Math.floor((boundingBox.max.z - boundingBox.min.z) * 1000) / 1000;

			// geometryBoundingBox.setInnerHTML( `${x}<br/>${y}<br/>${z}` );

			// helpersRow.setDisplay( geometry.hasAttribute( 'normal' ) ? '' : 'none' );
		} else {
			container.setDisplay("none");
		}
	}
}