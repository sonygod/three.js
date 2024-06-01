import js.Lib;

import MenubarAdd from "./Menubar.Add";
import MenubarEdit from "./Menubar.Edit";
import MenubarFile from "./Menubar.File";
import MenubarView from "./Menubar.View";
import MenubarHelp from "./Menubar.Help";
import MenubarStatus from "./Menubar.Status";

class Menubar {

    public function new(editor) {
        var container = new Lib.UIPanel();
        container.setId("menubar");

        container.add(new MenubarFile(editor));
        container.add(new MenubarEdit(editor));
        container.add(new MenubarAdd(editor));
        container.add(new MenubarView(editor));
        container.add(new MenubarHelp(editor));

        container.add(new MenubarStatus(editor));

        return container;
    }

}