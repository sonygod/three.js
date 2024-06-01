import haxe.extern.EitherType;
import js.jquery.JQuery;
import js.threejs.Three;
import ui.UI;
import ui.UIPanel;
import ui.UIBreak;
import ui.UIButton;
import ui.UIRow;
import ui.UIInput;
import commands.AddScriptCommand;
import commands.SetScriptValueCommand;
import commands.RemoveScriptCommand;

using StringTools;

class SidebarScript 
{
	public var dom:UIPanel;

	public function new(editor:Editor) 
	{
		var strings = editor.strings;
		var signals = editor.signals;

		dom = new UIPanel();
		dom.setBorderTop("0");
		dom.setPaddingTop("20px");
		dom.setDisplay("none");

		//

		var scriptsContainer = new UIRow();
		dom.add(scriptsContainer);

		var newScript = new UIButton(strings.getKey("sidebar/script/new"));
		newScript.onClick(function(_) 
		{
			var script = { name: "", source: "function update( event ) {}" };
			editor.execute(new AddScriptCommand(editor, editor.selected, script));
		});
		dom.add(newScript);

		//

		function update() 
		{
			scriptsContainer.clear();
			scriptsContainer.setDisplay("none");

			var object = editor.selected;

			if (object == null) 
			{
				return;
			}

			var scripts:Array<Dynamic> =  Reflect.field(editor.scripts, object.uuid); //editor.scripts[object.uuid];

			if (scripts != null && scripts.length > 0) 
			{
				scriptsContainer.setDisplay("block");

				for (i in 0...scripts.length) 
				{
					var object = object;
					var script = scripts[i];

					var name = new UIInput(script.name).setWidth("130px").setFontSize("12px");
					name.onChange(function(_) 
					{
						editor.execute(new SetScriptValueCommand(editor, editor.selected, script, "name", name.getValue()));
					});
					scriptsContainer.add(name);

					var edit = new UIButton(strings.getKey("sidebar/script/edit"));
					edit.setMarginLeft("4px");
					edit.onClick(function(_) 
					{
						signals.editScript.dispatch(object, script);
					});
					scriptsContainer.add(edit);

					var remove = new UIButton(strings.getKey("sidebar/script/remove"));
					remove.setMarginLeft("4px");
					remove.onClick(function(_) 
					{
						if (js.Browser.window.confirm(strings.getKey("prompt/script/remove"))) 
						{
							editor.execute(new RemoveScriptCommand(editor, editor.selected, script));
						}
					});
					scriptsContainer.add(remove);

					scriptsContainer.add(new UIBreak());
				}
			}
		}

		// signals

		signals.objectSelected.add(function(object) 
		{
			if (object != null && editor.camera != object) 
			{
				dom.setDisplay("block");

				update();
			}
			 else 
			{
				dom.setDisplay("none");
			}
		});

		signals.scriptAdded.add(update);
		signals.scriptRemoved.add(update);
		signals.scriptChanged.add(update);
	}
}