import ui.UIPanel;
import ui.UIBreak;
import ui.UIText;

class ViewportInfo {

	public function new(editor:Editor) {

		var signals = editor.signals;
		var strings = editor.strings;

		var container = new UIPanel();
		container.setId('info');
		container.setPosition('absolute');
		container.setLeft('10px');
		container.setBottom('20px');
		container.setFontSize('12px');
		container.setColor('#fff');
		container.setTextTransform('lowercase');

		var objectsText = new UIText('0').setTextAlign('right').setWidth('60px').setMarginRight('6px');
		var verticesText = new UIText('0').setTextAlign('right').setWidth('60px').setMarginRight('6px');
		var trianglesText = new UIText('0').setTextAlign('right').setWidth('60px').setMarginRight('6px');
		var frametimeText = new UIText('0').setTextAlign('right').setWidth('60px').setMarginRight('6px');

		var objectsUnitText = new UIText(strings.getKey('viewport/info/objects'));
		var verticesUnitText = new UIText(strings.getKey('viewport/info/vertices'));
		var trianglesUnitText = new UIText(strings.getKey('viewport/info/triangles'));

		container.add(objectsText, objectsUnitText, new UIBreak());
		container.add(verticesText, verticesUnitText, new UIBreak());
		container.add(trianglesText, trianglesUnitText, new UIBreak());
		container.add(frametimeText, new UIText(strings.getKey('viewport/info/rendertime')), new UIBreak());

		signals.objectAdded.add(update);
		signals.objectRemoved.add(update);
		signals.geometryChanged.add(update);
		signals.sceneRendered.add(updateFrametime);

		function update() {

			var scene = editor.scene;

			var objects = 0;
			var vertices = 0;
			var triangles = 0;

			for (i in 0...scene.children.length) {

				var object = scene.children[i];

				object.traverseVisible(function(object) {

					objects++;

					if (Std.isOfType(object, Mesh) || Std.isOfType(object, Points)) {

						var geometry = (cast object).geometry;

						vertices += geometry.attributes.position.count;

						if (Std.isOfType(object, Mesh)) {

							if (geometry.index != null) {

								triangles += Std.int(geometry.index.count / 3);

							} else {

								triangles += Std.int(geometry.attributes.position.count / 3);

							}

						}

					}

				});

			}

			objectsText.setValue(editor.utils.formatNumber(objects));
			verticesText.setValue(editor.utils.formatNumber(vertices));
			trianglesText.setValue(editor.utils.formatNumber(triangles));

			// Haxe doesn't have built-in Intl.PluralRules, you'll need to implement or use an external library
			// For simplicity, we'll just use the plural form for now
			// var pluralRules = new Intl.PluralRules(editor.config.getKey('language'));

			// var objectsStringKey = (pluralRules.select(objects) === 'one') ? 'viewport/info/oneObject' : 'viewport/info/objects';
			var objectsStringKey = 'viewport/info/objects';
			objectsUnitText.setValue(strings.getKey(objectsStringKey));

			// var verticesStringKey = (pluralRules.select(vertices) === 'one') ? 'viewport/info/oneVertex' : 'viewport/info/vertices';
			var verticesStringKey = 'viewport/info/vertices';
			verticesUnitText.setValue(strings.getKey(verticesStringKey));

			// var trianglesStringKey = (pluralRules.select(triangles) === 'one') ? 'viewport/info/oneTriangle' : 'viewport/info/triangles';
			var trianglesStringKey = 'viewport/info/triangles';
			trianglesUnitText.setValue(strings.getKey(trianglesStringKey));

		}

		function updateFrametime(frametime:Float) {

			frametimeText.setValue(frametime.toFixed(2));

		}

		return container;

	}

}