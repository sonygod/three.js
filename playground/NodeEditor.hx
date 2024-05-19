package three.js.playground;

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

class NodeEditor extends three.EventDispatcher {
    public var scene:three.Scene;
    public var renderer:three.WebGLRenderer;
    public var composer:three.EffectComposer;

    private var canvas:Canvas;
    private var domElement:js.html.Element;
    private var nodeClasses:Array<NodeData>;
    private var search:Search;
    private var menu:CircleMenu;
    private var previewMenu:CircleMenu;
    private var nodesContext:ContextMenu;
    private var examplesContext:ContextMenu;
    private var splitview:SplitscreenManager;
    private var _preview:Bool;
    private var _splitscreen:Bool;

    public function new(scene:three.Scene = null, renderer:three.WebGLRenderer = null, composer:three.EffectComposer = null) {
        super();

        domElement = js.Browser.document.createElement("flow");
        canvas = new Canvas();
        domElement.appendChild(canvas.dom);

        this.scene = scene;
        this.renderer = renderer;

        Nodes.global.set("THREE", THREE);
        Nodes.global.set("TSL", Nodes);

        Nodes.global.set("scene", scene);
        Nodes.global.set("renderer", renderer);
        Nodes.global.set("composer", composer);

        nodeClasses = [];

        canvas = canvas;
        domElement = domElement;

        _preview = false;
        _splitscreen = false;

        search = null;

        menu = null;
        previewMenu = null;

        nodesContext = null;
        examplesContext = null;

        _initSplitview();
        _initUpload();
        _initTips();
        _initMenu();
        _initSearch();
        _initNodesContext();
        _initExamplesContext();
        _initShortcuts();
        _initParams();
    }

    public function setSize(width:Int, height:Int):NodeEditor {
        canvas.setSize(width, height);
        return this;
    }

    public function centralizeNode(node:Node):NodeEditor {
        var canvasRect = canvas.getBoundingClientRect();
        var nodeRect = node.dom.getBoundingClientRect();

        node.setPosition(
            (canvasRect.width / 2) - nodeRect.width,
            (canvasRect.height / 2) - nodeRect.height
        );

        return this;
    }

    public function add(node:Node):NodeEditor {
        var onRemove = function() {
            node.removeEventListener("remove", onRemove);
            node.setEditor(null);
        };

        node.setEditor(this);
        node.addEventListener("remove", onRemove);

        canvas.add(node);

        dispatchEvent({ type: "add", node: node });

        return this;
    }

    public function get_nodes():Array<Node> {
        return canvas.nodes;
    }

    public function set_preview(value:Bool):Void {
        if (_preview == value) return;

        if (value) {
            _wasSplitscreen = _splitscreen;
            _splitscreen = false;

            menu.dom.remove();
            canvas.dom.remove();
            search.dom.remove();

            domElement.appendChild(previewMenu.dom);
        } else {
            canvas.focusSelected = false;

            domElement.appendChild(menu.dom);
            domElement.appendChild(canvas.dom);
            domElement.appendChild(search.dom);

            previewMenu.dom.remove();

            if (_wasSplitscreen) {
                _splitscreen = true;
            }
        }

        _preview = value;
    }

    public function get_preview():Bool {
        return _preview;
    }

    public function set_splitscreen(value:Bool):Void {
        if (_splitscreen == value) return;

        splitview.setSplitview(value);
        _splitscreen = value;
    }

    public function get_splitscreen():Bool {
        return _splitscreen;
    }

    public function newProject():Void {
        var canvas = this.canvas;
        canvas.clear();
        canvas.scrollLeft = 0;
        canvas.scrollTop = 0;
        canvas.zoom = 1;

        dispatchEvent({ type: "new" });
    }

    public function loadURL(url:String):Promise<Void> {
        var loader = new Loader(Loader.OBJECTS);
        return loader.load(url, ClassLib).then(json -> loadJSON(json));
    }

    public function loadJSON(json:Dynamic):Void {
        var canvas = this.canvas;

        canvas.clear();

        canvas.deserialize(json);

        for (node in canvas.nodes) {
            add(node);
        }

        dispatchEvent({ type: "load" });
    }

    private function _initSplitview():Void {
        splitview = new SplitscreenManager(this);
    }

    private function _initUpload():Void {
        var canvas = this.canvas;

        canvas.onDrop(() -> {
            for (item in canvas.droppedItems) {
                var relativeClientX = canvas.relativeClientX;
                var relativeClientY = canvas.relativeClientY;

                var file = item.getAsFile();
                var reader = new FileReader();

                reader.onload = function() {
                    var fileEditor = new FileEditor(reader.result, file.name);

                    fileEditor.setPosition(
                        relativeClientX - (fileEditor.getWidth() / 2),
                        relativeClientY - 20
                    );

                    add(fileEditor);
                };

                reader.readAsArrayBuffer(file);
            }
        });
    }

    private function _initTips():Void {
        tips = new Tips();
        domElement.appendChild(tips.dom);
    }

    private function _initMenu():Void {
        var menu = new CircleMenu();
        var previewMenu = new CircleMenu();

        menu.setAlign("top left");
        previewMenu.setAlign("top left");

        var previewButton = new ButtonInput().setIcon("ti ti-brand-threejs").setToolTip("Preview");
        var splitscreenButton = new ButtonInput().setIcon("ti ti-layout-sidebar-right-expand").setToolTip("Splitscreen");
        var menuButton = new ButtonInput().setIcon("ti ti-apps").setToolTip("Add");
        var examplesButton = new ButtonInput().setIcon("ti ti-file-symlink").setToolTip("Examples");
        var newButton = new ButtonInput().setIcon("ti ti-file").setToolTip("New");
        var openButton = new ButtonInput().setIcon("ti ti-upload").setToolTip("Open");
        var saveButton = new ButtonInput().setIcon("ti ti-download").setToolTip("Save");

        var editorButton = new ButtonInput().setIcon("ti ti-subtask").setToolTip("Editor");

        previewButton.onClick(() -> _preview = true);
        editorButton.onClick(() -> _preview = false);

        splitscreenButton.onClick(() -> _splitscreen = !_splitscreen);

        menuButton.onClick(() -> nodesContext.open());
        examplesButton.onClick(() -> examplesContext.open());

        newButton.onClick(() -> {
            if (js.Browser.confirm("Are you sure?")) {
                newProject();
            }
        });

        openButton.onClick(() -> {
            var input = js.Browser.document.createElement("input");
            input.type = "file";

            input.onchange = e -> {
                var file = e.target.files[0];
                var reader = new FileReader();
                reader.readAsText(file, "UTF-8");

                reader.onload = readerEvent -> {
                    var json = JSON.parse(readerEvent.target.result);
                    loadJSON(json);
                };
            };

            input.click();
        });

        saveButton.onClick(() -> exportJSON(canvas.toJSON(), "node_editor"));

        menu.add(previewButton)
            .add(splitscreenButton)
            .add(newButton)
            .add(examplesButton)
            .add(openButton)
            .add(saveButton)
            .add(menuButton);

        previewMenu.add(editorButton);

        domElement.appendChild(menu.dom);

        this.menu = menu;
        this.previewMenu = previewMenu;
    }

    private function _initExamplesContext():Void {
        var context = new ContextMenu();

        var onClickExample = function(button:ButtonInput) {
            examplesContext.hide();

            var filename = button.getExtra();

            loadURL("./examples/" + filename + ".json");
        };

        var addExamples = function(category:String, names:Array<String>) {
            var subContext = new ContextMenu();

            for (name in names) {
                var filename = name.replaceAll(" ", "-").toLowerCase();

                subContext.add(new ButtonInput(name)
                    .setIcon("ti ti-file-symlink")
                    .onClick(onClickExample)
                    .setExtra(category.toLowerCase() + "/" + filename)
                );
            }

            context.add(new ButtonInput(category), subContext);

            return subContext;
        };

        addExamples("Basic", ["Teapot", "Matcap", "Fresnel", "Particles"]);

        examplesContext = context;
    }

    private function _initShortcuts():Void {
        js.Browser.document.addEventListener("keydown", function(e) {
            if (e.target == js.Browser.document.body) {
                var key = e.key;

                if (key == "Tab") {
                    search.inputDOM.focus();

                    e.preventDefault();
                    e.stopImmediatePropagation();
                } else if (key == " ") {
                    _preview = !_preview;
                } else if (key == "Delete") {
                    if (canvas.selected) canvas.selected.dispose();
                } else if (key == "Escape") {
                    canvas.select(null);
                }
            }
        });
    }

    private function _initParams():Void {
        var urlParams = new js.html.URLSearchParams(js.Browser.window.location.search);

        var example = urlParams.get("example") || "basic/teapot";

        loadURL("./examples/" + example + ".json");
    }

    public function addClass(nodeData:NodeData):NodeEditor {
        removeClass(nodeData);

        nodeClasses.push(nodeData);

        ClassLib[nodeData.name] = nodeData.nodeClass;

        return this;
    }

    public function removeClass(nodeData:NodeData):NodeEditor {
        var index = nodeClasses.indexOf(nodeData);

        if (index != -1) {
            nodeClasses.splice(index, 1);

            delete ClassLib[nodeData.name];
        }

        return this;
    }

    private function _initSearch():Void {
        var traverseNodeEditors = function(item:NodeData) {
            if (item.children != null) {
                for (subItem in item.children) {
                    traverseNodeEditors(subItem);
                }
            } else {
                var button = new ButtonInput(item.name);
                button.setIcon("ti ti-" + item.icon);
                button.addEventListener("complete", async () -> {
                    var nodeClass = await getNodeEditorClass(item);

                    var node = new nodeClass();

                    add(node);

                    centralizeNode(node);
                    canvas.select(node);
                });

                search.add(button);

                if (item.tags != null) {
                    search.setTag(button, item.tags);
                }
            }
        };

        var search = new Search();
        search.forceAutoComplete = true;

        search.onFilter(() -> {
            search.clear();

            var nodeList = getNodeList();

            for (item in nodeList.nodes) {
                traverseNodeEditors(item);
            }

            for (item in nodeClasses) {
                traverseNodeEditors(item);
            }
        });

        search.onSubmit(() -> {
            if (search.currentFiltered != null) {
                search.currentFiltered.button.dispatchEvent(new js.html.Event("complete"));
            }
        });

        this.search = search;

        domElement.appendChild(search.dom);
    }

    private function _initNodesContext():Void {
        var context = new ContextMenu(this.canvas.canvas).setWidth(300);

        var isContext = false;
        var contextPosition = {};

        var add = function(node:Node) {
            context.hide();

            add(node);

            if (isContext) {
                node.setPosition(
                    Math.round(contextPosition.x),
                    Math.round(contextPosition.y)
                );
            } else {
                centralizeNode(node);
            }

            canvas.select(node);
        };

        context.onContext(() -> {
            isContext = true;

            var relativeClientX = canvas.relativeClientX;
            var relativeClientY = canvas.relativeClientY;

            contextPosition.x = Math.round(relativeClientX);
            contextPosition.y = Math.round(relativeClientY);
        });

        context.addEventListener("show", () -> {
            reset();
            focus();
        });

        var treeView = new TreeViewInput();
        var node = new Node();
        node.add(new Element().setHeight(30).add(search));
        node.add(new Element().setHeight(200).add(treeView));

        var addNodeEditorElement = function(nodeData:NodeData) {
            var button = new TreeViewNode(nodeData.name);
            button.setIcon("ti ti-" + nodeData.icon);

            if (nodeData.children == null) {
                button.isNodeClass = true;
                button.onClick(async () -> {
                    var nodeClass = await getNodeEditorClass(nodeData);

                    add(new nodeClass());
                });
            }

            if (nodeData.tip != null) {
                button.setToolTip(nodeData.tip);
            }

            return button;
        };

        var nodeList = getNodeList();

        for (node in nodeList.nodes) {
            var button = addNodeEditorElement(node);

            treeView.add(button);
        }

        nodesContext = context;
    }
}