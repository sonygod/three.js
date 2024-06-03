import three.THREE;
import three.nodes.Nodes;
import flow.Canvas;
import flow.CircleMenu;
import flow.ButtonInput;
import flow.StringInput;
import flow.ContextMenu;
import flow.Tips;
import flow.Search;
import flow.Loader;
import flow.Node;
import flow.TreeViewNode;
import flow.TreeViewInput;
import flow.Element;
import FileEditor from './editors/FileEditor';
import { exportJSON } from './NodeEditorUtils';
import { init, ClassLib, getNodeEditorClass, getNodeList } from './NodeEditorLib';
import SplitscreenManager from './SplitscreenManager';

class NodeEditor extends THREE.EventDispatcher {
    public var scene: THREE.Scene;
    public var renderer: THREE.WebGLRenderer;
    public var nodeClasses: Array<Dynamic>;
    public var canvas: Canvas;
    public var domElement: HTMLElement;
    private var _preview: Bool;
    private var _splitscreen: Bool;
    public var search: Search;
    public var menu: CircleMenu;
    public var previewMenu: CircleMenu;
    public var nodesContext: ContextMenu;
    public var examplesContext: ContextMenu;
    private var _wasSplitscreen: Bool;
    public var tips: Tips;
    public var splitview: SplitscreenManager;

    public function new(scene: THREE.Scene = null, renderer: THREE.WebGLRenderer = null, composer: Any = null) {
        super();
        init();
        Element.icons["unlink"] = "ti ti-unlink";
        this.scene = scene;
        this.renderer = renderer;
        const { global } = Nodes;
        global.set("THREE", THREE);
        global.set("TSL", Nodes);
        global.set("scene", scene);
        global.set("renderer", renderer);
        global.set("composer", composer);
        this.nodeClasses = [];
        this.canvas = new Canvas();
        this.domElement = js.Browser.document.createElement("flow");
        this.domElement.append(this.canvas.dom);
        this._preview = false;
        this._splitscreen = false;
        this.search = null;
        this.menu = null;
        this.previewMenu = null;
        this.nodesContext = null;
        this.examplesContext = null;
        this._initSplitview();
        this._initUpload();
        this._initTips();
        this._initMenu();
        this._initSearch();
        this._initNodesContext();
        this._initExamplesContext();
        this._initShortcuts();
        this._initParams();
    }

    public function setSize(width: Float, height: Float): NodeEditor {
        this.canvas.setSize(width, height);
        return this;
    }

    public function centralizeNode(node: Node): NodeEditor {
        const canvas = this.canvas;
        const nodeRect = node.dom.getBoundingClientRect();
        node.setPosition(
            ((canvas.width / 2) - canvas.scrollLeft) - nodeRect.width,
            ((canvas.height / 2) - canvas.scrollTop) - nodeRect.height
        );
        return this;
    }

    public function add(node: Node): NodeEditor {
        const onRemove = () => {
            node.removeEventListener("remove", onRemove);
            node.setEditor(null);
        };
        node.setEditor(this);
        node.addEventListener("remove", onRemove);
        this.canvas.add(node);
        this.dispatchEvent({ type: "add", node: node });
        return this;
    }

    public function get nodes(): Array<Node> {
        return this.canvas.nodes;
    }

    public function set preview(value: Bool): Void {
        if (this._preview == value) return;
        if (value) {
            this._wasSplitscreen = this.splitscreen;
            this.splitscreen = false;
            this.menu.dom.remove();
            this.canvas.dom.remove();
            this.search.dom.remove();
            this.domElement.append(this.previewMenu.dom);
        } else {
            this.canvas.focusSelected = false;
            this.domElement.append(this.menu.dom);
            this.domElement.append(this.canvas.dom);
            this.domElement.append(this.search.dom);
            this.previewMenu.dom.remove();
            if (this._wasSplitscreen == true) {
                this.splitscreen = true;
            }
        }
        this._preview = value;
    }

    public function get preview(): Bool {
        return this._preview;
    }

    public function set splitscreen(value: Bool): Void {
        if (this._splitscreen == value) return;
        this.splitview.setSplitview(value);
        this._splitscreen = value;
    }

    public function get splitscreen(): Bool {
        return this._splitscreen;
    }

    public function newProject(): Void {
        const canvas = this.canvas;
        canvas.clear();
        canvas.scrollLeft = 0;
        canvas.scrollTop = 0;
        canvas.zoom = 1;
        this.dispatchEvent({ type: "new" });
    }

    public async function loadURL(url: String): Promise<Void> {
        const loader = new Loader(Loader.OBJECTS);
        const json = await loader.load(url, ClassLib);
        this.loadJSON(json);
    }

    public function loadJSON(json: Dynamic): Void {
        const canvas = this.canvas;
        canvas.clear();
        canvas.deserialize(json);
        for (const node of canvas.nodes) {
            this.add(node);
        }
        this.dispatchEvent({ type: "load" });
    }

    private function _initSplitview(): Void {
        this.splitview = new SplitscreenManager(this);
    }

    private function _initUpload(): Void {
        const canvas = this.canvas;
        canvas.onDrop(() => {
            for (const item of canvas.droppedItems) {
                const { relativeClientX, relativeClientY } = canvas;
                const file = item.getAsFile();
                const reader = new js.html.FileReader();
                reader.onload = () => {
                    const fileEditor = new FileEditor(reader.result, file.name);
                    fileEditor.setPosition(
                        relativeClientX - (fileEditor.getWidth() / 2),
                        relativeClientY - 20
                    );
                    this.add(fileEditor);
                };
                reader.readAsArrayBuffer(file);
            }
        });
    }

    private function _initTips(): Void {
        this.tips = new Tips();
        this.domElement.append(this.tips.dom);
    }

    private function _initMenu(): Void {
        const menu = new CircleMenu();
        const previewMenu = new CircleMenu();
        menu.setAlign("top left");
        previewMenu.setAlign("top left");
        const previewButton = new ButtonInput().setIcon("ti ti-brand-threejs").setToolTip("Preview");
        const splitscreenButton = new ButtonInput().setIcon("ti ti-layout-sidebar-right-expand").setToolTip("Splitscreen");
        const menuButton = new ButtonInput().setIcon("ti ti-apps").setToolTip("Add");
        const examplesButton = new ButtonInput().setIcon("ti ti-file-symlink").setToolTip("Examples");
        const newButton = new ButtonInput().setIcon("ti ti-file").setToolTip("New");
        const openButton = new ButtonInput().setIcon("ti ti-upload").setToolTip("Open");
        const saveButton = new ButtonInput().setIcon("ti ti-download").setToolTip("Save");
        const editorButton = new ButtonInput().setIcon("ti ti-subtask").setToolTip("Editor");
        previewButton.onClick(() => this.preview = true);
        editorButton.onClick(() => this.preview = false);
        splitscreenButton.onClick(() => {
            this.splitscreen = !this.splitscreen;
            splitscreenButton.setIcon(this.splitscreen ? "ti ti-layout-sidebar-right-collapse" : "ti ti-layout-sidebar-right-expand");
        });
        menuButton.onClick(() => this.nodesContext.open());
        examplesButton.onClick(() => this.examplesContext.open());
        newButton.onClick(() => {
            if (js.Browser.window.confirm("Are you sure?") == true) {
                this.newProject();
            }
        });
        openButton.onClick(() => {
            const input = js.Browser.document.createElement("input");
            input.type = "file";
            input.onchange = e => {
                const file = e.target.files[0];
                const reader = new js.html.FileReader();
                reader.readAsText(file, "UTF-8");
                reader.onload = readerEvent => {
                    const loader = new Loader(Loader.OBJECTS);
                    const json = loader.parse(haxe.Unserializer.run(readerEvent.target.result), ClassLib);
                    this.loadJSON(json);
                };
            };
            input.click();
        });
        saveButton.onClick(() => {
            exportJSON(this.canvas.toJSON(), "node_editor");
        });
        menu.add(previewButton)
            .add(splitscreenButton)
            .add(newButton)
            .add(examplesButton)
            .add(openButton)
            .add(saveButton)
            .add(menuButton);
        previewMenu.add(editorButton);
        this.domElement.appendChild(menu.dom);
        this.menu = menu;
        this.previewMenu = previewMenu;
    }

    private function _initExamplesContext(): Void {
        const context = new ContextMenu();
        const onClickExample = async (button: ButtonInput) => {
            this.examplesContext.hide();
            const filename = button.getExtra();
            this.loadURL(`./examples/${filename}.json`);
        };
        const addExamples = (category: String, names: Array<String>) => {
            const subContext = new ContextMenu();
            for (const name of names) {
                const filename = name.replaceAll(" ", "-").toLowerCase();
                subContext.add(new ButtonInput(name)
                    .setIcon("ti ti-file-symlink")
                    .onClick(onClickExample)
                    .setExtra(category.toLowerCase() + "/" + filename)
                );
            }
            context.add(new ButtonInput(category), subContext);
            return subContext;
        };
        addExamples("Basic", [
            "Teapot",
            "Matcap",
            "Fresnel",
            "Particles"
        ]);
        this.examplesContext = context;
    }

    private function _initShortcuts(): Void {
        js.Browser.document.addEventListener("keydown", (e: KeyboardEvent) => {
            if (e.target == js.Browser.document.body) {
                const key = e.key;
                if (key == "Tab") {
                    this.search.inputDOM.focus();
                    e.preventDefault();
                    e.stopImmediatePropagation();
                } else if (key == " ") {
                    this.preview = !this.preview;
                } else if (key == "Delete") {
                    if (this.canvas.selected != null) this.canvas.selected.dispose();
                } else if (key == "Escape") {
                    this.canvas.select(null);
                }
            }
        });
    }

    private function _initParams(): Void {
        const urlParams = new URLSearchParams(js.Browser.window.location.search);
        const example = urlParams.get("example") || "basic/teapot";
        this.loadURL(`./examples/${example}.json`);
    }

    public function addClass(nodeData: Dynamic): NodeEditor {
        this.removeClass(nodeData);
        this.nodeClasses.push(nodeData);
        ClassLib[nodeData.name] = nodeData.nodeClass;
        return this;
    }

    public function removeClass(nodeData: Dynamic): NodeEditor {
        const index = this.nodeClasses.indexOf(nodeData);
        if (index != -1) {
            this.nodeClasses.splice(index, 1);
            delete ClassLib[nodeData.name];
        }
        return this;
    }

    private async function _initSearch(): Promise<Void> {
        const traverseNodeEditors = (item: Dynamic) => {
            if (item.children != null) {
                for (const subItem of item.children) {
                    traverseNodeEditors(subItem);
                }
            } else {
                const button = new ButtonInput(item.name);
                button.setIcon(`ti ti-${item.icon}`);
                button.addEventListener("complete", async () => {
                    const nodeClass = await getNodeEditorClass(item);
                    const node = new nodeClass();
                    this.add(node);
                    this.centralizeNode(node);
                    this.canvas.select(node);
                });
                search.add(button);
                if (item.tags != null) {
                    search.setTag(button, item.tags);
                }
            }
        };
        const search = new Search();
        search.forceAutoComplete = true;
        search.onFilter(async () => {
            search.clear();
            const nodeList = await getNodeList();
            for (const item of nodeList.nodes) {
                traverseNodeEditors(item);
            }
            for (const item of this.nodeClasses) {
                traverseNodeEditors(item);
            }
        });
        search.onSubmit(() => {
            if (search.currentFiltered != null) {
                search.currentFiltered.button.dispatchEvent(new Event("complete"));
            }
        });
        this.search = search;
        this.domElement.append(search.dom);
    }

    private async function _initNodesContext(): Promise<Void> {
        const context = new ContextMenu(this.canvas.canvas).setWidth(300);
        let isContext = false;
        const contextPosition = {};
        const add = (node: Node) => {
            context.hide();
            this.add(node);
            if (isContext) {
                node.setPosition(
                    Std.int(contextPosition.x),
                    Std.int(contextPosition.y)
                );
            } else {
                this.centralizeNode(node);
            }
            this.canvas.select(node);
            isContext = false;
        };
        context.onContext(() => {
            isContext = true;
            const { relativeClientX, relativeClientY } = this.canvas;
            contextPosition.x = Std.int(relativeClientX);
            contextPosition.y = Std.int(relativeClientY);
        });
        context.addEventListener("show", () => {
            reset();
            focus();
        });
        const nodeButtons = [];
        let nodeButtonsVisible = [];
        let nodeButtonsIndex = -1;
        const focus = () => js.Browser.window.requestAnimationFrame(() => search.inputDOM.focus());
        const reset = () => {
            search.setValue("", false);
            for (const button of nodeButtons) {
                button.setOpened(false).setVisible(true).setSelected(false);
            }
        };
        const node = new Node();
        context.add(node);
        const search = new StringInput().setPlaceHolder("Search...").setIcon("ti ti-list-search");
        search.inputDOM.addEventListener("keydown", e => {
            const key = e.key;
            if (key == "ArrowDown") {
                const previous = nodeButtonsVisible[nodeButtonsIndex];
                if (previous != null) previous.setSelected(false);
                const current = nodeButtonsVisible[nodeButtonsIndex = (nodeButtonsIndex + 1) % nodeButtonsVisible.length];
                if (current != null) current.setSelected(true);
                e.preventDefault();
                e.stopImmediatePropagation();
            } else if (key == "ArrowUp") {
                const previous = nodeButtonsVisible[nodeButtonsIndex];
                if (previous != null) previous.setSelected(false);
                const current = nodeButtonsVisible[nodeButtonsIndex > 0 ? --nodeButtonsIndex : (nodeButtonsIndex = nodeButtonsVisible.length - 1)];
                if (current != null) current.setSelected(true);
                e.preventDefault();
                e.stopImmediatePropagation();
            } else if (key == "Enter") {
                if (nodeButtonsVisible[nodeButtonsIndex] != null) {
                    nodeButtonsVisible[nodeButtonsIndex].dom.click();
                } else {
                    context.hide();
                }
                e.preventDefault();
                e.stopImmediatePropagation();
            } else if (key == "Escape") {
                context.hide();
            }
        });
        search.onChange(() => {
            const value = search.getValue().toLowerCase();
            if (value.length == 0) return reset();
            nodeButtonsVisible = [];
            nodeButtonsIndex = 0;
            for (const button of nodeButtons) {
                const buttonLabel = button.getLabel().toLowerCase();
                button.setVisible(false).setSelected(false);
                const visible = buttonLabel.indexOf(value) != -1;
                if (visible && button.children.length == 0) {
                    nodeButtonsVisible.push(button);
                }
            }
            for (const button of nodeButtonsVisible) {
                var parent = button;
                while (parent != null) {
                    parent.setOpened(true).setVisible(true);
                    parent = parent.parent;
                }
            }
            if (nodeButtonsVisible[nodeButtonsIndex] != null) {
                nodeButtonsVisible[nodeButtonsIndex].setSelected(true);
            }
        });
        const treeView = new TreeViewInput();
        node.add(new Element().setHeight(30).add(search));
        node.add(new Element().setHeight(200).add(treeView));
        const addNodeEditorElement = (nodeData: Dynamic) => {
            const button = new TreeViewNode(nodeData.name);
            button.setIcon(`ti ti-${nodeData.icon}`);
            if (nodeData.children == null) {
                button.isNodeClass = true;
                button.onClick(async () => {
                    const nodeClass = await getNodeEditorClass(nodeData);
                    add(new nodeClass());
                });
            }
            if (nodeData.tip != null) {
                //button.setToolTip(item.tip);
            }
            nodeButtons.push(button);
            if (nodeData.children != null) {
                for (const subItem of nodeData.children) {
                    const subButton = addNodeEditorElement(subItem);
                    button.add(subButton);
                }
            }
            return button;
        };
        const nodeList = await getNodeList();
        for (const node of nodeList.nodes) {
            const button = addNodeEditorElement(node);
            treeView.add(button);
        }
        this.nodesContext = context;
    }
}


This conversion assumes that the `three`, `flow`, and `FileEditor` modules have been imported correctly, and that the `exportJSON` function and `ClassLib`, `getNodeEditorClass`, and `getNodeList` functions have been defined correctly. The `SplitscreenManager` class is also assumed to be imported correctly.

Please note that the JavaScript `URLSearchParams` class is not available in Haxe, so the `_initParams` method has been left unchanged. If you need to access URL parameters in Haxe, you may need to use a different approach.

Additionally, the `replaceAll` method is not available in Haxe, so the `_initExamplesContext` method has been left unchanged. If you need to replace all occurrences of a substring in Haxe, you can use a regular expression with the `replace` method, as shown below:


const filename = EReg.replace(name, " ", "-").toLowerCase();