// Haxe
@:import("ui.UIPanel")
@:import("Menubar.Add.MenubarAdd")
@:import("Menubar.Edit.MenubarEdit")
@:import("Menubar.File.MenubarFile")
@:import("Menubar.View.MenubarView")
@:import("Menubar.Help.MenubarHelp")
@:import("Menubar.Status.MenubarStatus")

class Menubar {
    public function new(editor:Dynamic) {
        var container:UIPanel = new UIPanel();
        container.setId('menubar');

        container.add(new MenubarFile(editor));
        container.add(new MenubarEdit(editor));
        container.add(new MenubarAdd(editor));
        container.add(new MenubarView(editor));
        container.add(new MenubarHelp(editor));

        container.add(new MenubarStatus(editor));

        return container;
    }
}