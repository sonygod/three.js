import three.THREE;

import ui.UICheckbox;
import ui.UIDiv;
import ui.UINumber;
import ui.UIRow;
import ui.UIText;
import ui.three.UITexture;

import commands.SetMaterialMapCommand;
import commands.SetMaterialValueCommand;
import commands.SetMaterialRangeCommand;
import commands.SetMaterialVectorCommand;

class SidebarMaterialMapProperty {

	public function new(editor:Editor, property:String, name:String) {

		var signals = editor.signals;

		var container = new UIRow();
		container.add( new UIText(name).setClass("Label") );

		var enabled = new UICheckbox(false).setMarginRight("8px").onChange(onChange);
		container.add(enabled);

		var map = new UITexture(editor).onChange(onMapChange);
		container.add(map);

		var mapType = property.replace("Map", "");

		var colorMaps = ["map", "emissiveMap", "sheenColorMap", "specularColorMap", "envMap"];

		var intensity:UINumber = null;

		if (property == "aoMap") {

			intensity = new UINumber(1).setWidth("30px").setRange(0, 1).onChange(onIntensityChange);
			container.add(intensity);

		}

		var scale:UINumber = null;

		if (property == "bumpMap" || property == "displacementMap") {

			scale = new UINumber().setWidth("30px").onChange(onScaleChange);
			container.add(scale);

		}

		var scaleX:UINumber = null;
		var scaleY:UINumber = null;

		if (property == "normalMap" || property == "clearcoatNormalMap") {

			scaleX = new UINumber().setWidth("30px").onChange(onScaleXYChange);
			container.add(scaleX);

			scaleY = new UINumber().setWidth("30px").onChange(onScaleXYChange);
			container.add(scaleY);

		}

		var rangeMin:UINumber = null;
		var rangeMax:UINumber = null;

		if (property == "iridescenceThicknessMap") {

			var range = new UIDiv().setMarginLeft("3px");
			container.add(range);

			var rangeMinRow = new UIRow().setMarginBottom("0px").setStyle("min-height", "0px");
			range.add(rangeMinRow);

			rangeMinRow.add(new UIText("min:").setWidth("35px"));

			rangeMin = new UINumber().setWidth("40px").onChange(onRangeChange);
			rangeMinRow.add(rangeMin);

			var rangeMaxRow = new UIRow().setMarginBottom("6px").setStyle("min-height", "0px");
			range.add(rangeMaxRow);

			rangeMaxRow.add(new UIText("max:").setWidth("35px"));

			rangeMax = new UINumber().setWidth("40px").onChange(onRangeChange);
			rangeMaxRow.add(rangeMax);

			// Additional settings for iridescenceThicknessMap
			// Please add conditional if more maps are having a range property
			rangeMin.setPrecision(0).setRange(0, Math.POSITIVE_INFINITY).setNudge(1).setStep(10).setUnit("nm");
			rangeMax.setPrecision(0).setRange(0, Math.POSITIVE_INFINITY).setNudge(1).setStep(10).setUnit("nm");

		}

		var object:THREE.Object3D = null;
		var materialSlot:Int = 0;
		var material:Dynamic = null;

		function onChange(_) {

			var newMap = enabled.getValue() ? map.getValue() : null;

			if (material[property] != newMap) {

				if (newMap != null) {

					var geometry = object.geometry;

					if (!geometry.hasAttribute("uv")) trace('Geometry doesn\'t have uvs:', geometry);

					if (property == "envMap") newMap.mapping = THREE.EquirectangularReflectionMapping;

				}

				editor.execute(new SetMaterialMapCommand(editor, object, property, newMap, materialSlot));

			}

		}

		function onMapChange(texture:THREE.Texture) {

			if (texture != null) {

				if (colorMaps.indexOf(property) != -1 && !texture.isDataTexture && texture.colorSpace != THREE.SRGBColorSpace) {

					texture.colorSpace = THREE.SRGBColorSpace;
					material.needsUpdate = true;

				}

			}

			enabled.setDisabled(false);

			onChange(null);

		}

		function onIntensityChange(_) {

			if (material[ '${property}Intensity'] != intensity.getValue()) {

				editor.execute(new SetMaterialValueCommand(editor, object, '${property}Intensity', intensity.getValue(), materialSlot));

			}

		}

		function onScaleChange(_) {

			if (material['${mapType}Scale'] != scale.getValue()) {

				editor.execute(new SetMaterialValueCommand(editor, object, '${mapType}Scale', scale.getValue(), materialSlot));

			}

		}

		function onScaleXYChange(_) {

			var value = [scaleX.getValue(), scaleY.getValue()];

			if (material['${mapType}Scale'].x != value[0] || material['${mapType}Scale'].y != value[1]) {

				editor.execute(new SetMaterialVectorCommand(editor, object, '${mapType}Scale', value, materialSlot));

			}

		}

		function onRangeChange(_) {

			var value = [rangeMin.getValue(), rangeMax.getValue()];

			if (material['${mapType}Range'][0] != value[0] || material['${mapType}Range'][1] != value[1]) {

				editor.execute(new SetMaterialRangeCommand(editor, object, '${mapType}Range', value[0], value[1], materialSlot));

			}

		}

		function update(currentObject:THREE.Object3D, currentMaterialSlot:Int = 0) {

			object = currentObject;
			materialSlot = currentMaterialSlot;

			if (object == null) return;
			if (object.material == null) return;

			material = editor.getObjectMaterial(object, materialSlot);

			if (Reflect.hasField(material, property)) {

				if (material[property] != null) {

					map.setValue(material[property]);

				}

				enabled.setValue(material[property] != null);
				enabled.setDisabled(map.getValue() == null);

				if (intensity != null) {

					intensity.setValue(material['${property}Intensity']);

				}

				if (scale != null) {

					scale.setValue(material['${mapType}Scale']);

				}

				if (scaleX != null) {

					scaleX.setValue(material['${mapType}Scale'].x);
					scaleY.setValue(material['${mapType}Scale'].y);

				}

				if (rangeMin != null) {

					rangeMin.setValue(material['${mapType}Range'][0]);
					rangeMax.setValue(material['${mapType}Range'][1]);

				}

				container.setDisplay("");

			} else {

				container.setDisplay("none");

			}

		}

		//

		signals.objectSelected.add(function(selected) {

			map.setValue(null);

			update(selected);

		});

		signals.materialChanged.add(update);

		return container;

	}

}