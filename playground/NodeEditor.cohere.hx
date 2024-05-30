import js.three.*;
import js.three.nodes.*;
import js.flow.*;
import js.flow.editors.FileEditor;
import js.flow.NodeEditorUtils.exportJSON;
import js.flow.NodeEditorLib.*;
import js.flow.SplitscreenManager;

class NodeEditor extends js.three.EventDispatcher {
    var scene:js.three.Scene;
    var renderer:js.three.WebGLRenderer;
    var composer:js.three.EffectComposer;
    var domElement:js.html.Element;
    var canvas:js.flow.Canvas;
    var _preview:Bool;
    var _splitscreen:Bool;
    var search:js.flow.Search;
    var menu:js.flow.CircleMenu;
    var previewMenu:js.flow.CircleMenu;
    var nodesContext:js.flow.ContextMenu;
    var examplesContext:js.flow.ContextMenu;
    var _wasSplitscreen:Bool;
    var splitview:SplitscreenManager;
    var tips:js.flow.Tips;

    public function new(scene:js.three.Scene = null, renderer:js.three.WebGLRenderer = null, composer:js.three.EffectComposer = null) {
        super();
        domElement = js.html.window.document.createElement("flow");
        canvas = new js.flow.Canvas();
        domElement.append(canvas.dom);
        this.scene = scene;
        this.renderer = renderer;
        var global = Nodes.global;
        global.set("THREE", js.three);
        global.set("TSL", Nodes);
        global.set("scene", scene);
        global.set("renderer", renderer);
        global.set("composer", composer);
        nodeClasses = [];
        this.canvas = canvas;
        this.domElement = domElement;
        _preview = false;
        _splitscreen = false;
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

    public function setSize(width:Int, height:Int):Void {
        canvas.setSize(width, height);
    }

    public function centralizeNode(node:js.flow.Node):Void {
        var nodeRect = node.dom.getBoundingClientRect();
        node.setPosition(( ( canvas.width / 2 ) - canvas.scrollLeft ) - nodeRect.width, ( ( canvas.height / 2 ) - canvas.scrollTop ) - nodeRect.height);
    }

    public function add(node:js.flow.Node):Void {
        var onRemove = function() {
            node.removeEventListener("remove", onRemove);
            node.setEditor(null);
        };
        node.setEditor(this);
        node.addEventListener("remove", onRemove);
        canvas.add(node);
        dispatchEvent( { type: "add", node: node } );
    }

    public function get nodes():Array<js.flow.Node> {
        return canvas.nodes;
    }

    public function set preview(value:Bool) {
        if (_preview == value) return;
        if (value) {
            _wasSplitscreen = splitscreen;
            splitscreen = false;
            menu.dom.remove();
            canvas.dom.remove();
            search.dom.remove();
            domElement.append(previewMenu.dom);
        } else {
            canvas.focusSelected = false;
            domElement.append(menu.dom);
            domElement.append(canvas.dom);
            domElement.append(search.dom);
            previewMenu.dom.remove();
            if (_wasSplitscreen) {
                splitscreen = true;
            }
        }
        _preview = value;
    }

    public function get preview():Bool {
        return _preview;
    }

    public function set splitscreen(value:Bool) {
        if (_splitscreen == value) return;
        splitview.setSplitview(value);
        _splitscreen = value;
    }

    public function get splitscreen():Bool {
        return _splitscreen;
    }

    public function newProject():Void {
        canvas.clear();
        canvas.scrollLeft = 0;
        canvas.scrollTop = 0;
        canvas.zoom = 1;
        dispatchEvent({ type: "new" });
    }

    public async function loadURL(url:String):Void {
        var loader = new js.flow.Loader(js.flow.Loader.OBJECTS);
        var json = await loader.load(url, ClassLib);
        loadJSON(json);
    }

    public function loadJSON(json:Dynamic):Void {
        canvas.clear();
        canvas.deserialize(json);
        for (node in canvas.nodes) {
            add(node);
        }
        dispatchEvent({ type: "load" });
    }

    function _initSplitview():Void {
        splitview = new SplitscreenManager(this);
    }

    function _initUpload():Void {
        canvas.onDrop(function() {
            for (item in canvas.droppedItems) {
                var relativeClientX = canvas.relativeClientX;
                var relativeClientY = canvas.relativeClientY;
                var file = item.getAsFile();
                var reader = new js.sys.FileReader();
                reader.onload = function() {
                    var fileEditor = new FileEditor(reader.result, file.name);
                    fileEditor.setPosition(relativeClientX - (fileEditor.getWidth() / 2), relativeClientY - 20);
                    add(fileEditor);
                };
                reader.readAsArrayBuffer(file);
            }
        });
    }

    function _initTips():Void {
        tips = new js.flow.Tips();
        domElement.append(tips.dom);
    }

    function _initMenu():Void {
        menu = new js.flow.CircleMenu();
        previewMenu = new js.flow.CircleMenu();
        menu.setAlign("top left");
        previewMenu.setAlign("top left");
        var previewButton = new js.flow.ButtonInput().setIcon("ti ti-brand-threejs").setToolTip("Preview");
        var splitscreenButton = new js.flow.ButtonInput().setIcon("ti ti-layout-sidebar-right-expand").setToolTip("Splitscreen");
        var menuButton = new js.flow.ButtonInput().setIcon("ti ti-apps").setToolTip("Add");
        var examplesButton = new js.flow.ButtonInput().setIcon("ti ti-file-symlink").setToolTip("Examples");
        var newButton = new js.flow.ButtonInput().setIcon("ti ti-file").setToolTip("New");
        var openButton = new js.flow.ButtonInput().setIcon("ti ti-upload").setToolTip("Open");
        var saveButton = new js.flow.ButtonInput().setIcon("ti ti-download").setToolTip("Save");
        var editorButton = new js.flow.ButtonInput().setIcon("ti ti-subtask").setToolTip("Editor");
        previewButton.onClick(function() {
            preview = true;
        });
        editorButton.onClick(function() {
            preview = false;
        });
        splitscreenButton.onClick(function() {
            splitscreen = !splitscreen;
            splitscreenButton.setIcon(splitscreen ? "ti ti-layout-sidebar-right-collapse" : "ti ti-layout-sidebar-right-expand");
        });
        menuButton.onClick(function() {
            nodesContext.open();
        });
        examplesButton.onClick(function() {
            examplesContext.open();
        });
        newButton.onClick(function() {
            if (js.sys.confirm("Are you sure?")) {
                newProject();
            }
        });
        openButton.onClick(function() {
            var input = js.html.window.document.createElement("input");
            input.type = "file";
            input.onchange = function(e) {
                var file = e.target.files[0];
                var reader = new js.sys.FileReader();
                reader.readAsText(file, "UTF-8");
                reader.onload = function(readerEvent) {
                    var loader = new js.flow.Loader(js.flow.Loader.OBJECTS);
                    var json = loader.parse(JSON.parse(readerEvent.target.result), ClassLib);
                    loadJSON(json);
                };
            };
            input.click();
        });
        saveButton.onClick(function() {
            exportJSON(canvas.toJSON(), "node_editor");
        });
        menu.add(previewButton);
        menu.add(splitscreenButton);
        menu.add(newButton);
        menu.add(examplesButton);
        menu.add(openButton);
        menu.add(saveButton);
        menu.add(menuButton);
        previewMenu.add(editorButton);
        domElement.appendChild(menu.dom);
        this.menu = menu;
        this.previewMenu = previewMenu;
    }

    function _initExamplesContext():Void {
        var context = new js.flow.ContextMenu();
        function onClickExample(button:js.flow.ButtonInput) {
            examplesContext.hide();
            var filename = button.getExtra();
            loadURL("./examples/${filename}.json");
        }
        function addExamples(category:String, names:Array<String>) {
            var subContext = new js.flow.ContextMenu();
            for (name in names) {
                var filename = name.replaceAll(" ", "-").toLowerCase();
                subContext.add(new js.flow.ButtonInput(name)
                    .setIcon("ti ti-file-symlink")
                    .onClick(onClickExample)
                    .setExtra(category.toLowerCase() + "/" + filename));
            }
            context.add(new js.flow.ButtonInput(category), subContext);
            return subContext;
        }
        addExamples("Basic", ["Teapot", "Matcap", "Fresnel", "Particles"]);
        this.examplesContext = context;
    }

    function _initShortcuts():Void {
        js.html.window.document.addEventListener("keydown", function(e) {
            if (e.target == js.html.window.document.body) {
                switch(e.key) {
                    case "Tab":
                        search.inputDOM.focus();
                        e.preventDefault();
                        e.stopImmediatePropagation();
                        break;
                    case " ":
                        preview = !preview;
                        break;
                    case "Delete":
                        if (canvas.selected != null) canvas.selected.dispose();
                        break;
                    case "Escape":
                        canvas.select(null);
                        break;
                }
            }
        });
    }

    function _initParams():Void {
        var urlParams = new URLSearchParams(js.html.window.location.search);
        var example = urlParams.get("example") ?? "basic/teapot";
        loadURL("./examples/${example}.json");
    }

    public function addClass(nodeData:Dynamic):Void {
        removeClass(nodeData);
        nodeClasses.push(nodeData);
        ClassLib[nodeData.name] = nodeData.nodeClass;
    }

    public function removeClass(nodeData:Dynamic):Void {
        var index = nodeClasses.indexOf(nodeData);
        if (index != -1) {
            nodeClasses.splice(index, 1);
            delete ClassLib[nodeData.name];
        }
    }

    function _initSearch():Void {
        function traverseNodeEditors(item:Dynamic) {
            if (item.children != null) {
                for (subItem in item.children) {
                    traverseNodeEditors(subItem);
                }
            } else {
                var button = new js.flow.ButtonInput(item.name);
                button.setIcon("ti ti-" + item.icon);
                button.addEventListener("complete", function() {
                    var nodeClass = getNodeEditorClass(item);
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
        }
        search = new js.flow.Search();
        search.forceAutoComplete = true;
        search.onFilter(function() {
            search.clear();
            var nodeList = getNodeList();
            for (item in nodeList.nodes) {
                traverseNodeEditors(item);
            }
            for (item in nodeClasses) {
                traverseNodeEditors(item);
            }
        });
        search.onSubmit(function() {
            if (search.currentFiltered != null) {
                search.currentFiltered.button.dispatchEvent(new js.html.Event("complete"));
            }
        });
        this.search = search;
        domElement.append(search.dom);
    }

    function _initNodesContext():Void {
        nodesContext = new js.flow.ContextMenu(canvas.canvas).setWidth(300);
        var isContext:Bool;
        var contextPosition:js.flow.Point;
        function add(node:js.flow.Node) {
            nodesContext.hide();
            add(node);
            if (isContext) {
                node.setPosition(contextPosition.x, contextPosition.y);
            } else {
                centralizeNode(node);
            }
            canvas.select(node);
            isContext = false;
        }
        nodesContext.onContext(function() {
            isContext = true;
            var relativeClientX = canvas.relativeClientX;
            var relativeClientY = canvas.relativeClientY;
            contextPosition = { x: Math.round(relativeClientX), y: Math.round(relativeClientY) };
        });
        nodesContext.addEventListener("show", function() {
            reset();
            focus();
        });
        var nodeButtons:Array<js.flow.ButtonInput>;
        var nodeButtonsVisible:Array<js.flow.ButtonInput>;
        var nodeButtonsIndex:Int;
        function focus() {
            js.Lib.window.requestAnimationFrame(function() {
                search.inputDOM.focus();
            });
        }
        function reset() {
            search.setValue("", false);
            for (button in nodeButtons) {
                button.setOpened(false).setVisible(true).setSelected(false);
            }
        }
        var node = new js.flow.Node();
        context.add(node);
        var search = new js.flow.StringInput().setPlaceHolder("Search...").setIcon("ti ti-list-search");
        search.inputDOM.addEventListener("keydown", function(e) {
            switch(e.key) {
                case "ArrowDown":
                    var previous = nodeButtonsVisible[nodeButtonsIndex];
                    if (previous != null) previous.setSelected(false);
                    var current = nodeButtonsVisible[nodeButtonsIndex = (nodeButtonsIndex + 1) % nodeButtonsVisible.length];
                    if (current != null) current.setSelected(true);
                    e.preventDefault();
                    e.stopImmediatePropagation();
                    break;
                case "ArrowUp":
                    var previous = nodeButtonsVisible[nodeButtonsIndex];
                    if (previous != null) previous.setSelected(false);
                    var current = nodeButtonsVisible[nodeButtonsIndex > 0 ? --nodeButtonsIndex : (nodeButtonsIndex = nodeButtonsVisible.length - 1)];
                    if (current != null) current.setSelected(true);
                    e.preventDefault();
                    e.stopImmediatePropagation();
                    break;
                case "Enter":
                    if (nodeButtonsVisible[nodeButtonsIndex] != null) {
                        nodeButtonsVisible[nodeButtonsIndex].dom.click();
                    } else {
                        context.hide();
                    }
                    e.preventDefault();
                    e.stopImmediatePropagation();
                    break;
                case "Escape":
                    context.hide();
                    break;
            }
        });
        search.onChange(function() {
            var value = search.getValue().toLowerCase();
            if (value.length == 0) return reset();
            nodeButtonsVisible = [];
            nodeButtonsIndex = 0;
            for (button in nodeButtons) {
                var buttonLabel = button.getLabel().toLowerCase();
                button.setVisible(false).setSelected(false);
                var visible = buttonLabel.indexOf(value) != -1;
                if (visible && button.children.length == 0) {
                    nodeButtonsVisible.push(button);
                }
            }
            for (button in nodeButtonsVisible) {
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
        var treeView = new js.flow.TreeViewInput();
        node.add(new js.flow.Element().setHeight(30).add(search));
        node.add(new js.flow.Element().setHeight(200).add(treeView));
        function addNodeEditorElement(nodeData:Dynamic) {
            var button = new js.flow.TreeViewNode(nodeData.name);
            button.setIcon("ti ti-" + nodeData.icon);
            if (nodeData.children == null) {
                button.isNodeClass = true;
                button.onClick(function() {
                    var nodeClass = getNodeEditorClass(nodeData);
                    add(new nodeClass());
                });
            }
            if (nodeData.tip != null) {
                //button.setToolTip(item.tip);
            }
            nodeButtons.push(button);
            if (nodeData.children != null) {
                for (subItem in nodeData.children) {
                    var subButton = addNodeEditorElement(subItem);
                    button.add(subButton);
                }
            }
            return button;
        }
        var nodeList = getNodeList();
        for (node in nodeList.nodes) {
            var button = addNodeEditorElement(node);
            treeView.add(button);
        }
        this.nodesContext = context;
    }
}