import three.NodeEditor;
import three.NodeEditorLib;
import three.NodeEditorUtils;
import three.SplitscreenManager;
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
import three.editors.FileEditor;

class NodeEditor extends three.EventDispatcher {

    public var scene:three.Scene;
    public var renderer:three.Renderer;
    public var composer:three.EffectComposer;

    private var _preview:Bool;
    private var _splitscreen:Bool;

    private var domElement:Element;
    private var canvas:Canvas;
    private var menu:CircleMenu;
    private var previewMenu:CircleMenu;
    private var nodesContext:ContextMenu;
    private var examplesContext:ContextMenu;
    private var tips:Tips;
    private var search:Search;
    private var splitview:SplitscreenManager;

    public function new(scene:three.Scene = null, renderer:three.Renderer = null, composer:three.EffectComposer = null) {
        super();

        NodeEditorLib.init();

        domElement = new Element();
        domElement.innerHTML = '<flow></flow>';

        canvas = new Canvas();
        domElement.append(canvas.dom);

        scene = scene;
        renderer = renderer;
        composer = composer;

        NodeEditorLib.global.set('THREE', three);
        NodeEditorLib.global.set('TSL', three.nodes);
        NodeEditorLib.global.set('scene', scene);
        NodeEditorLib.global.set('renderer', renderer);
        NodeEditorLib.global.set('composer', composer);

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

    public function centralizeNode(node:Node):Void {
        const canvas = this.canvas;
        const nodeRect = node.dom.getBoundingClientRect();

        node.setPosition(
            ( ( canvas.width / 2 ) - canvas.scrollLeft ) - nodeRect.width,
            ( ( canvas.height / 2 ) - canvas.scrollTop ) - nodeRect.height
        );
    }

    public function add(node:Node):Void {
        const onRemove = () => {
            node.removeEventListener('remove', onRemove);
            node.setEditor(null);
        };

        node.setEditor(this);
        node.addEventListener('remove', onRemove);

        canvas.add(node);

        this.dispatchEvent({type: 'add', node: node});
    }

    public function get nodes():Array<Node> {
        return canvas.nodes;
    }

    public function set preview(value:Bool):Void {
        if (_preview === value) return;

        if (value) {
            _wasSplitscreen = this.splitscreen;
            this.splitscreen = false;
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
            if (_wasSplitscreen == true) {
                this.splitscreen = true;
            }
        }

        _preview = value;
    }

    public function get preview():Bool {
        return _preview;
    }

    public function set splitscreen(value:Bool):Void {
        if (_splitscreen === value) return;
        splitview.setSplitview(value);
        _splitscreen = value;
    }

    public function get splitscreen():Bool {
        return _splitscreen;
    }

    public function newProject():Void {
        const canvas = this.canvas;
        canvas.clear();
        canvas.scrollLeft = 0;
        canvas.scrollTop = 0;
        canvas.zoom = 1;
        this.dispatchEvent({type: 'new'});
    }

    public async function loadURL(url:String):Void {
        const loader = new Loader(Loader.OBJECTS);
        const json = await loader.load(url, ClassLib);
        this.loadJSON(json);
    }

    public function loadJSON(json:Dynamic):Void {
        const canvas = this.canvas;
        canvas.clear();
        canvas.deserialize(json);
        for (node in canvas.nodes) {
            this.add(node);
        }
        this.dispatchEvent({type: 'load'});
    }

    private function _initSplitview():Void {
        splitview = new SplitscreenManager(this);
    }

    private function _initUpload():Void {
        canvas.onDrop(() => {
            for (item in canvas.droppedItems) {
                const file = item.getAsFile();
                const reader = new FileReader();
                reader.onload = () => {
                    const fileEditor = new FileEditor(reader.result, file.name);
                    fileEditor.setPosition(
                        canvas.relativeClientX - (fileEditor.getWidth() / 2),
                        canvas.relativeClientY - 20
                    );
                    this.add(fileEditor);
                };
                reader.readAsArrayBuffer(file);
            }
        });
    }

    private function _initTips():Void {
        tips = new Tips();
        domElement.append(tips.dom);
    }

    private function _initMenu():Void {
        menu = new CircleMenu();
        previewMenu = new CircleMenu();

        menu.setAlign('top left');
        previewMenu.setAlign('top left');

        const previewButton = new ButtonInput().setIcon('ti ti-brand-threejs').setToolTip('Preview');
        const splitscreenButton = new ButtonInput().setIcon('ti ti-layout-sidebar-right-expand').setToolTip('Splitscreen');
        const menuButton = new ButtonInput().setIcon('ti ti-apps').setToolTip('Add');
        const examplesButton = new ButtonInput().setIcon('ti ti-file-symlink').setToolTip('Examples');
        const newButton = new ButtonInput().setIcon('ti ti-file').setToolTip('New');
        const openButton = new ButtonInput().setIcon('ti ti-upload').setToolTip('Open');
        const saveButton = new ButtonInput().setIcon('ti ti-download').setToolTip('Save');

        const editorButton = new ButtonInput().setIcon('ti ti-subtask').setToolTip('Editor');

        previewButton.onClick(() => this.preview = true);
        editorButton.onClick(() => this.preview = false);

        splitscreenButton.onClick(() => {
            this.splitscreen = !this.splitscreen;
            splitscreenButton.setIcon(this.splitscreen ? 'ti ti-layout-sidebar-right-collapse' : 'ti ti-layout-sidebar-right-expand');
        });

        menuButton.onClick(() => nodesContext.open());
        examplesButton.onClick(() => examplesContext.open());

        newButton.onClick(() => {
            if (confirm('Are you sure?') === true) {
                this.newProject();
            }
        });

        openButton.onClick(() => {
            const input = document.createElement('input');
            input.type = 'file';

            input.onchange = (e) => {
                const file = e.target.files[0];

                const reader = new FileReader();
                reader.readAsText(file, 'UTF-8');

                reader.onload = (readerEvent) => {
                    const loader = new Loader(Loader.OBJECTS);
                    const json = loader.parse(JSON.parse(readerEvent.target.result), ClassLib);
                    this.loadJSON(json);
                };
            };

            input.click();
        });

        saveButton.onClick(() => {
            NodeEditorUtils.exportJSON(canvas.toJSON(), 'node_editor');
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
    }

    private function _initExamplesContext():Void {
        examplesContext = new ContextMenu();

        // Add examples context menu items here
    }

    private function _initShortcuts():Void {
        document.addEventListener('keydown', (e) => {
            if (e.target === document.body) {
                const key = e.key;

                if (key === 'Tab') {
                    search.inputDOM.focus();
                    e.preventDefault();
                    e.stopImmediatePropagation();
                } else if (key === ' ') {
                    this.preview = !this.preview;
                } else if (key === 'Delete') {
                    if (canvas.selected) canvas.selected.dispose();
                } else if (key === 'Escape') {
                    canvas.select(null);
                }
            }
        });
    }

    private function _initParams():Void {
        const urlParams = new URLSearchParams(window.location.search);

        const example = urlParams.get('example') || 'basic/teapot';

        this.loadURL(`./examples/${example}.json`);
    }

    public function addClass(nodeData:Dynamic):Void {
        this.removeClass(nodeData);
        nodeClasses.push(nodeData);
        ClassLib[nodeData.name] = nodeData.nodeClass;
    }

    public function removeClass(nodeData:Dynamic):Void {
        const index = nodeClasses.indexOf(nodeData);
        if (index !== -1) {
            nodeClasses.splice(index, 1);
            delete ClassLib[nodeData.name];
        }
    }

    private function _initSearch():Void {
        search = new Search();
        search.forceAutoComplete = true;

        search.onFilter(() => {
            search.clear();

            const nodeList = NodeEditorLib.getNodeList();

            for (item in nodeList.nodes) {
                traverseNodeEditors(item);
            }

            for (item in nodeClasses) {
                traverseNodeEditors(item);
            }
        });

        search.onSubmit(() => {
            if (search.currentFiltered !== null) {
                search.currentFiltered.button.dispatchEvent(new Event('complete'));
            }
        });

        domElement.append(search.dom);
    }

    private async function _initNodesContext():Void {
        nodesContext = new ContextMenu(canvas.canvas).setWidth(300);

        let isContext = false;
        const contextPosition:Dynamic = {};

        const add = (node:Node) => {
            nodesContext.hide();
            this.add(node);
            if (isContext) {
                node.setPosition(Math.round(contextPosition.x), Math.round(contextPosition.y));
            } else {
                this.centralizeNode(node);
            }
            canvas.select(node);
            isContext = false;
        };

        nodesContext.onContext(() => {
            isContext = true;
            const {relativeClientX, relativeClientY} = canvas;
            contextPosition.x = Math.round(relativeClientX);
            contextPosition.y = Math.round(relativeClientY);
        });

        nodesContext.addEventListener('show', () => {
            reset();
            focus();
        });

        // Add nodes context menu items here
    }

}