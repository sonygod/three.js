package three.js.playground;

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

import js.html.Document;
import js.html.Element;

class NodeEditor extends three.js.EventDispatcher {
    private var scene:three.js.Scene;
    private var renderer:three.js.WebGLRenderer;
    private var composer:Dynamic;
    private var canvas:Canvas;
    private var domElement:js.html.Element;
    private var nodeClasses:Array<Dynamic>;
    private var search:Search;
    private var menu:CircleMenu;
    private var previewMenu:CircleMenu;
    private var nodesContext:ContextMenu;
    private var examplesContext:ContextMenu;
    private var splitview:SplitscreenManager;
    private var _preview:Bool;
    private var _splitscreen:Bool;

    public function new(scene:three.js.Scene = null, renderer:three.js.WebGLRenderer = null, composer:Dynamic = null) {
        super();

        domElement = js.Browser.document.createElement('div');
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

    public function setSize(width:Int, height:Int) {
        canvas.setSize(width, height);
        return this;
    }

    public function centralizeNode(node:Node) {
        var canvas = this.canvas;
        var nodeRect = node.dom.getBoundingClientRect();

        node.setPosition(
            (canvas.width / 2) - canvas.scrollLeft - nodeRect.width,
            (canvas.height / 2) - canvas.scrollTop - nodeRect.height
        );

        return this;
    }

    public function add(node:Node) {
        node.setEditor(this);
        canvas.add(node);
        dispatchEvent({ type: 'add', node: node });
        return this;
    }

    public var nodes(get, never):Array<Node>;
    private function get_nodes():Array<Node> {
        return canvas.nodes;
    }

    public var preview(get, set):Bool;
    private function get_preview():Bool {
        return _preview;
    }
    private function set_preview(value:Bool):Void {
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
            if (_wasSplitscreen) _splitscreen = true;
        }
        _preview = value;
    }

    public var splitscreen(get, set):Bool;
    private function get_splitscreen():Bool {
        return _splitscreen;
    }
    private function set_splitscreen(value:Bool):Void {
        if (_splitscreen == value) return;
        splitview.setSplitview(value);
        _splitscreen = value;
    }

    public function newProject() {
        canvas.clear();
        canvas.scrollLeft = 0;
        canvas.scrollTop = 0;
        canvas.zoom = 1;
        dispatchEvent({ type: 'new' });
    }

    public function loadURL(url:String) {
        var loader = new Loader(Loader.OBJECTS);
        loader.load(url, ClassLib, function(json) {
            loadJSON(json);
        });
    }

    public function loadJSON(json:Dynamic) {
        canvas.clear();
        canvas.deserialize(json);
        for (node in canvas.nodes) {
            add(node);
        }
        dispatchEvent({ type: 'load' });
    }

    private function _initSplitview() {
        splitview = new SplitscreenManager(this);
    }

    private function _initUpload() {
        canvas.onDrop(function() {
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

    private function _initTips() {
        tips = new Tips();
        domElement.appendChild(tips.dom);
    }

    private function _initMenu() {
        menu = new CircleMenu();
        previewMenu = new CircleMenu();
        menu.setAlign('top left');
        previewMenu.setAlign('top left');

        // ... (rest of menu initialization)
    }

    private function _initExamplesContext() {
        examplesContext = new ContextMenu();
        // ... (rest of examples context initialization)
    }

    private function _initShortcuts() {
        js.Browser.document.addEventListener('keydown', function(e) {
            if (e.target == js.Browser.document.body) {
                var key = e.key;
                if (key == 'Tab') {
                    search.inputDOM.focus();
                    e.preventDefault();
                    e.stopImmediatePropagation();
                } else if (key == ' ') {
                    preview = !preview;
                } else if (key == 'Delete') {
                    if (canvas.selected) canvas.selected.dispose();
                } else if (key == 'Escape') {
                    canvas.select(null);
                }
            }
        });
    }

    private function _initParams() {
        var urlParams = new URLSearchParams(js.Browser.location.search);
        var example = urlParams.get('example') || 'basic/teapot';
        loadURL('./examples/${example}.json');
    }

    public function addClass(nodeData:Dynamic) {
        removeClass(nodeData);
        nodeClasses.push(nodeData);
        ClassLib[nodeData.name] = nodeData.nodeClass;
        return this;
    }

    public function removeClass(nodeData:Dynamic) {
        var index = nodeClasses.indexOf(nodeData);
        if (index != -1) {
            nodeClasses.splice(index, 1);
            delete ClassLib[nodeData.name];
        }
        return this;
    }
}