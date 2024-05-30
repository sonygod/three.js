import MenubarAdd from './Menubar.Add.hx';
import MenubarEdit from './Menubar.Edit.hx';
import MenubarFile from './Menubar.File.hx';
import MenubarView from './Menubar.View.hx';
import MenubarHelp from './Menubar.Help.hx';
import MenubarStatus from './Menubar.Status.hx';

function menubar(editor) {
    var container = new UIPanel();
    container.setId('menubar');

    container.add(new MenubarFile(editor));
    container.add(new MenubarEdit(editor));
    container.add(new MenubarAdd(editor));
    container.add(new MenubarView(editor));
    container.add(new MenubarHelp(editor));
    container.add(new MenubarStatus(editor));

    return container;
}

export default { menubar };