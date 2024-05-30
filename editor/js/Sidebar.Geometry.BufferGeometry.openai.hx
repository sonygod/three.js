package three.js.editor.js;

import ui.UIRow;
import ui.UIText;
import ui.UISpan;
import ui.UIBreak;
import ui.UICheckbox;

class SidebarGeometryBufferGeometry {
  public function new(editor:Editor) {
    var strings = editor.strings;
    var signals = editor.signals;

    var container = new UIRow();

    function update(object:Any) {
      if (object == null) return; // objectSelected.dispatch( null )
      if (object == null) return;

      var geometry = object.geometry;

      if (geometry != null) {
        container.clear();
        container.setDisplay('block');

        // attributes

        var attributesRow = new UIRow();

        var textAttributes = new UIText(strings.getKey('sidebar/geometry/buffer_geometry/attributes')).setClass('Label');
        attributesRow.add(textAttributes);

        var containerAttributes = new UISpan().setDisplay('inline-block').setVerticalAlign('middle').setWidth('160px');
        attributesRow.add(containerAttributes);

        var index = geometry.index;

        if (index != null) {
          containerAttributes.add(new UIText(strings.getKey('sidebar/geometry/buffer_geometry/index')).setWidth('80px'));
          containerAttributes.add(new UIText(editor.utils.formatNumber(index.count)).setFontSize('12px'));
          containerAttributes.add(new UIBreak());
        }

        var attributes = geometry.attributes;

        for (name in attributes) {
          var attribute = attributes[name];

          containerAttributes.add(new UIText(name).setWidth('80px'));
          containerAttributes.add(new UIText(editor.utils.formatNumber(attribute.count) + ' (' + attribute.itemSize + ')').setFontSize('12px'));
          containerAttributes.add(new UIBreak());
        }

        container.add(attributesRow);

        // morph targets

        var morphAttributes = geometry.morphAttributes;
        var hasMorphTargets = Lambda.count(Object.keys(morphAttributes)) > 0;

        if (hasMorphTargets) {
          // morph attributes

          var rowMorphAttributes = new UIRow();

          var textMorphAttributes = new UIText(strings.getKey('sidebar/geometry/buffer_geometry/morphAttributes')).setClass('Label');
          rowMorphAttributes.add(textMorphAttributes);

          var containerMorphAttributes = new UISpan().setDisplay('inline-block').setVerticalAlign('middle').setWidth('160px');
          rowMorphAttributes.add(containerMorphAttributes);

          for (name in morphAttributes) {
            var morphTargets = morphAttributes[name];

            containerMorphAttributes.add(new UIText(name).setWidth('80px'));
            containerMorphAttributes.add(new UIText(editor.utils.formatNumber(morphTargets.length)).setFontSize('12px'));
            containerMorphAttributes.add(new UIBreak());
          }

          container.add(rowMorphAttributes);

          // morph relative

          var rowMorphRelative = new UIRow();

          var textMorphRelative = new UIText(strings.getKey('sidebar/geometry/buffer_geometry/morphRelative')).setClass('Label');
          rowMorphRelative.add(textMorphRelative);

          var checkboxMorphRelative = new UICheckbox().setValue(geometry.morphTargetsRelative).setDisabled(true);
          rowMorphRelative.add(checkboxMorphRelative);

          container.add(rowMorphRelative);
        }
      } else {
        container.setDisplay('none');
      }
    }

    signals.objectSelected.add(update);
    signals.geometryChanged.add(update);

    return container;
  }
}