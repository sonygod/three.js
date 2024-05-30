import js.THREE.PlaneGeometry;

import js.UIDiv;
import js.UIRow;
import js.UIText;
import js.UIInteger;
import js.UINumber;

class GeometryParametersPanel {
    public function new(editor:Editor, object:Dynamic) {
        var strings = editor.strings;
        var container = new UIDiv();
        var geometry = untyped object.geometry;
        var parameters = untyped geometry.parameters;

        var widthRow = new UIRow();
        var width = new UINumber(untyped parameters.width).onChange(update);

        widthRow.add(new UIText(strings.getKey('sidebar/geometry/plane_geometry/width')).setClass('Label'));
        widthRow.add(width);

        container.add(widthRow);

        var heightRow = new UIRow();
        var height = new UINumber(untyped parameters.height).onChange(update);

        heightRow.add(new UIText(strings.getKey('sidebar/geometry/plane_geometry/height')).setClass('Label'));
        heightRow.add(height);

        container.add(heightRow);

        var widthSegmentsRow = new UIRow();
        var widthSegments = new UIInteger(untyped parameters.widthSegments).setRange(1, Int.POSITIVE_INFINITY).onChange(update);

        widthSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/plane_geometry/widthsegments')).setClass('Label'));
        widthSegmentsRow.add(widthSegments);

        container.add(widthSegmentsRow);

        var heightSegmentsRow = new UIRow();
        var heightSegments = new UIInteger(untyped parameters.heightSegments).setRange(1, Int.POSITIVE_INFINITY).onChange(update);

        heightSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/plane_geometry/heightsegments')).setClass('Label'));
        heightSegmentsRow.add(heightSegments);

        container.add(heightSegmentsRow);

        function update() {
            var widthValue = width.getValue();
            var heightValue = height.getValue();
            var widthSegmentsValue = widthSegments.getValue();
            var heightSegmentsValue = heightSegments.getValue();
            var newGeometry = new PlaneGeometry(widthValue, heightValue, widthSegmentsValue, heightSegmentsValue);
            editor.execute(new SetGeometryCommand(editor, object, newGeometry));
        }

        return container;
    }
}

class SetGeometryCommand {
    public function new(editor:Editor, object:Dynamic, geometry:PlaneGeometry) {
        _editor = editor;
        _object = object;
        _geometry = geometry;
    }

    public function execute() {
        untyped _object.geometry = _geometry;
        _editor.signals.objectChanged.dispatch(_object);
    }

    private var _editor:Editor;
    private var _object:Dynamic;
    private var _geometry:PlaneGeometry;
}