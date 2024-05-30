import BaseNodeEditor.BaseNodeEditor;
import NodeEditorUtils.createElementFromJSON;

class FloatEditor extends BaseNodeEditor {

	public function new() {

		var { element, inputNode } = createElementFromJSON({
			inputType: 'float',
			inputConnection: false
		});

		super('Float', inputNode, 150);

		element.addEventListener('changeInput', function() {
			this.invalidate();
		});

		this.add(element);

	}

}


Please note that the Haxe code assumes that the `createElementFromJSON` function and the `BaseNodeEditor` class are imported from the respective modules, similar to the JavaScript code. Also, the `addEventListener` method is used in the same way as in JavaScript.

However, Haxe does not have a direct equivalent for JavaScript's `export` keyword. Instead, you would typically use the `@:build` metadata to specify the output file and include the necessary classes in the build.

For example:


@:build(macro.Compiler.includeFile("BaseNodeEditor.hx"))
@:build(macro.Compiler.includeFile("NodeEditorUtils.hx"))
class FloatEditor {
    // ...
}