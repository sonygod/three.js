package three.js.playground;

import js.html.Document;
import js.Browser;
import three.js.THREE;
import three.js.Nodes;
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
import editors.FileEditor;
import NodeEditorUtils;
import NodeEditorLib;

class NodeEditor extends THREE.EventDispatcher {
    public var scene:THREE.Scene;
    public var renderer:THREE.WebGLRenderer;
    public var composer:THREE.EffectComposer;
    public var canvas:Canvas;
    public var domElement:js.html.Element;
    public var nodeClasses:Array<NodeClass>;
    public var _preview:Bool;
    public var _splitscreen:Bool;
    public var search:Search;
    public var menu:CircleMenu;
    public var previewMenu:CircleMenu;
    public var nodesContext:ContextMenu;
    public var examplesContext:ContextMenu;
    public var splitview:SplitscreenManager;

    public function new(scene:THREE.Scene = null, renderer:THREE.WebGLRenderer = null, composer:THREE.EffectComposer = null) {
        super();

        domElement = Browser.document.createElement('flow');
        canvas = new Canvas();
        domElement.appendChild(canvas.dom);

        this.scene = scene;
        this.renderer = renderer;

        Nodes.global.set('THREE', THREE);
        Nodes.global.set('TSL', Nodes);

        Nodes.global.set('scene', scene);
        Nodes.global.set('renderer', renderer);
        Nodes.global.set('composer', composer);

        nodeClasses = [];

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
        var canvasRect = canvas.dom.getBoundingClientRect();
        var nodeRect = node.dom.getBoundingClientRect();

        node.setPosition(
            (canvasRect.width / 2) - canvas.scrollLeft - nodeRect.width,
            (canvasRect.height / 2) - canvas.scrollTop - nodeRect.height
        );

        return this;
    }

    public function add(node:Node):NodeEditor {
        var onRemove = function() {
            node.removeEventListener('remove', onRemove);
            node.setEditor(null);
        };

        node.setEditor(this);
        node.addEventListener('remove', onRemove);

        canvas.add(node);

        dispatchEvent({type: 'add', node: node});

        return this;
    }

    public var nodes(get, never):Array<Node>;
    function get_nodes():Array<Node> {
        return canvas.nodes;
    }

    public var preview(get, set):Bool;
    function get_preview():Bool {
        return _preview;
    }
    function set_preview(value:Bool):Void {
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

    public var splitscreen(get, set):Bool;
    function get_splitscreen():Bool {
        return _splitscreen;
    }
    function set_splitscreen(value:Bool):Void {
        if (_splitscreen == value) return;

        splitview.setSplitview(value);

        _splitscreen = value;
    }

    public function newProject():Void {
        var canvas = this.canvas;
        canvas.clear();
        canvas.scrollLeft = 0;
        canvas.scrollTop = 0;
        canvas.zoom = 1;

        dispatchEvent({type: 'new'});
    }

    public function loadURL(url:String):Promise< Void > {
        var loader = new Loader(Loader.OBJECTS);
        return loader.load(url, ClassLib).then(json -> loadJSON(json));
    }

    public function loadJSON(json:Any):Void {
        var canvas = this.canvas;

        canvas.clear();

        canvas.deserialize(json);

        for (node in canvas.nodes) {
            add(node);
        }

        dispatchEvent({type: 'load'});
    }

    function _initSplitview():Void {
        splitview = new SplitscreenManager(this);
    }

    function _initUpload():Void {
        var canvas = this.canvas;

        canvas.onDrop(() -> {
            for (item in canvas.droppedItems) {
                var file = item.getAsFile();
                var reader = new FileReader();

                reader.onload = function() {
                    var fileEditor = new FileEditor(reader.result, file.name);

                    fileEditor.setPosition(
                        canvas.clientX - fileEditor.width / 2,
                        canvas.clientY - 20
                    );

                    add(fileEditor);
                };

                reader.readAsArrayBuffer(file);
            }
        });
    }

    function _initTips():Void {
        tips = new Tips();
        domElement.appendChild(tips.dom);
    }

    function _initMenu():Void {
        var menu = new CircleMenu();
        var previewMenu = new CircleMenu();

        menu.setAlign('top left');
        previewMenu.setAlign('top left');

        var previewButton = new ButtonInput().setIcon('ti ti-brand-threejs').setToolTip('Preview');
        var splitscreenButton = new ButtonInput().setIcon('ti ti-layout-sidebar-right-expand').setToolTip('Splitscreen');
        var menuButton = new ButtonInput().setIcon('ti ti-apps').setToolTip('Add');
        var examplesButton = new ButtonInput().setIcon('ti ti-file-symlink').setToolTip('Examples');
        var newButton = new ButtonInput().setIcon('ti ti-file').setToolTip('New');
        var openButton = new ButtonInput().setIcon('ti ti-upload').setToolTip('Open');
        var saveButton = new ButtonInput().setIcon('ti ti-download').setToolTip('Save');

        var editorButton = new ButtonInput().setIcon('ti ti-subtask').setToolTip('Editor');

        previewButton.onClick(function() {
            preview = true;
        });

        editorButton.onClick(function() {
            preview = false;
        });

        splitscreenButton.onClick(function() {
            _splitscreen = !_splitscreen;
            splitscreenButton.setIcon(_splitscreen ? 'ti ti-layout-sidebar-right-collapse' : 'ti ti-layout-sidebar-right-expand');
        });

        menuButton.onClick(function() {
            nodesContext.open();
        });

        examplesButton.onClick(function() {
            examplesContext.open();
        });

        newButton.onClick(function() {
            if (confirm('Are you sure?')) {
                newProject();
            }
        });

        openButton.onClick(function() {
            var input = Browser.document.createElement('input');
            input.type = 'file';

            input.onchange = function(e) {
                var file = e.target.files[0];
                var reader = new FileReader();
                reader.readAsText(file, 'UTF-8');

                reader.onload = function(event) {
                    var loader = new Loader(Loader.OBJECTS);
                    var json = loader.parse(JSON.parse(event.target.result), ClassLib);

                    loadJSON(json);
                };
            };

            input.click();
        });

        saveButton.onClick(function() {
            exportJSON(canvas.toJSON(), 'node_editor');
        });

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

    function _initExamplesContext():Void {
        var context = new ContextMenu();

        function onClickExample(button:ButtonInput):Void {
            examplesContext.hide();

            var filename = button.getExtra();

            loadURL('./examples/${filename}.json');
        }

        function addExamples(category:String, names:Array<String>):Void {
            var subContext = new ContextMenu();

            for (name in names) {
                var filename = name.replaceAll(' ', '-').toLowerCase();

                subContext.add(new ButtonInput(name)
                    .setIcon('ti ti-file-symlink')
                    .onClick(onClickExample)
                    .setExtra(category.toLowerCase() + '/' + filename)
                );
            }

            context.add(new ButtonInput(category), subContext);

            return subContext;
        }

        addExamples('Basic', ['Teapot', 'Matcap', 'Fresnel', 'Particles']);

        examplesContext = context;
    }

    function _initShortcuts():Void {
        Browser.document.addEventListener('keydown', function(e) {
            if (e.target == Browser.document.body) {
                switch (e.key) {
                    case 'Tab':
                        search.inputDOM.focus();
                        e.preventDefault();
                        e.stopImmediatePropagation();
                    case ' ':
                        preview = !preview;
                    case 'Delete':
                        if (canvas.selected) canvas.selected.dispose();
                    case 'Escape':
                        canvas.select(null);
                }
            }
        });
    }

    function _initParams():Void {
        var urlParams = new URLSearchParams(Browser.window.location.search);

        var example = urlParams.get('example') || 'basic/teapot';

        loadURL('./examples/${example}.json');
    }

    public function addClass(nodeData:NodeClass):NodeEditor {
        removeClass(nodeData);

        nodeClasses.push(nodeData);

        ClassLib[nodeData.name] = nodeData.nodeClass;

        return this;
    }

    public function removeClass(nodeData:NodeClass):NodeEditor {
        var index = nodeClasses.indexOf(nodeData);

        if (index != -1) {
            nodeClasses.splice(index, 1);

            delete ClassLib[nodeData.name];
        }

        return this;
    }

    function _initSearch():Void {
        function traverseNodeEditors(item:Any):Void {
            if (item.children) {
                for (subItem in item.children) {
                    traverseNodeEditors(subItem);
                }
            } else {
                var button = new ButtonInput(item.name);
                button.setIcon('ti ti-${item.icon}');
                button.addEventListener('complete', function() {
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

        search = new Search();
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
                search.currentFiltered.button.dispatchEvent(new Event('complete'));
            }
        });

        domElement.appendChild(search.dom);

        search.inputDOM.addEventListener('keydown', function(e) {
            switch (e.key) {
                case 'ArrowDown':
                    var previous = nodeButtonsVisible[nodeButtonsIndex];
                    if (previous) previous.setSelected(false);

                    var current = nodeButtonsVisible[nodeButtonsIndex = (nodeButtonsIndex + 1) % nodeButtonsVisible.length];
                    if (current) current.setSelected(true);

                    e.preventDefault();
                    e.stopImmediatePropagation();

                case 'ArrowUp':
                    var previous = nodeButtonsVisible[nodeButtonsIndex];
                    if (previous) previous.setSelected(false);

                    var current = nodeButtonsVisible[nodeButtonsIndex > 0 ? --nodeButtonsIndex : nodeButtonsVisible.length - 1];
                    if (current) current.setSelected(true);

                    e.preventDefault();
                    e.stopImmediatePropagation();

                case 'Enter':
                    if (nodeButtonsVisible[nodeButtonsIndex] != null) {
                        nodeButtonsVisible[nodeButtonsIndex].dom.click();
                    } else {
                        context.hide();
                    }

                    e.preventDefault();
                    e.stopImmediatePropagation();

                case 'Escape':
                    context.hide();
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

                if (buttonLabel.indexOf(value) != -1) {
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
    }

    function _initNodesContext():Void {
        var context = new ContextMenu(this.canvas.canvas).setWidth(300);

        var isContext = false;
        var contextPosition = {};

        function add(node:Node):Void {
            context.hide();

            this.add(node);

            if (isContext) {
                node.setPosition(
                    Math.round(contextPosition.x),
                    Math.round(contextPosition.y)
                );
            } else {
                centralizeNode(node);
            }

            canvas.select(node);
        }

        context.onContext(function() {
            isContext = true;

            var { relativeClientX, relativeClientY } = canvas;

            contextPosition.x = Math.round(relativeClientX);
            contextPosition.y = Math.round(relativeClientY);
        });

        context.addEventListener('show', function() {
            reset();
            focus();
        });

        var search = new StringInput().setPlaceHolder('Search...').setIcon('ti ti-list-search');

        search.inputDOM.addEventListener('keydown', function(e) {
            switch (e.key) {
                case 'ArrowDown':
                    var previous = nodeButtonsVisible[nodeButtonsIndex];
                    if (previous) previous.setSelected(false);

                    var current = nodeButtonsVisible[nodeButtonsIndex = (nodeButtonsIndex + 1) % nodeButtonsVisible.length];
                    if (current) current.setSelected(true);

                    e.preventDefault();
                    e.stopImmediatePropagation();

                case 'ArrowUp':
                    var previous = nodeButtonsVisible[nodeButtonsIndex];
                    if (previous) previous.setSelected(false);

                    var current = nodeButtonsVisible[nodeButtonsIndex > 0 ? --nodeButtonsIndex : nodeButtonsVisible.length - 1];
                    if (current) current.setSelected(true);

                    e.preventDefault();
                    e.stopImmediatePropagation();

                case 'Enter':
                    if (nodeButtonsVisible[nodeButtonsIndex] != null) {
                        nodeButtonsVisible[nodeButtonsIndex].dom.click();
                    } else {
                        context.hide();
                    }

                    e.preventDefault();
                    e.stopImmediatePropagation();

                case 'Escape':
                    context.hide();
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

                if (buttonLabel.indexOf(value) != -1) {
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

        var treeView = new TreeViewInput();
        var node = new Node();
        node.add(new Element().setHeight(30).add(search));
        node.add(new Element().setHeight(200).add(treeView));

        var addNodeEditorElement = function(nodeData:NodeClass):TreeViewNode {
            var button = new TreeViewNode(nodeData.name);
            button.setIcon('ti ti-${nodeData.icon}');

            if (nodeData.children == null) {
                button.isNodeClass = true;
                button.onClick(function() {
                    var nodeClass = getNodeEditorClass(nodeData);
                    var node = new nodeClass();
                    add(node);
                });
            }

            if (nodeData.children) {
                for (subItem in nodeData.children) {
                    var subButton = addNodeEditorElement(subItem);

                    button.add(subButton);
                }
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