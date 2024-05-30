package three.js.examples.jsm.nodes.core;

import NodeUpdateType from './constants';

class NodeFrame {

    public var time:Float = 0;
    public var deltaTime:Float = 0;

    public var frameId:Int = 0;
    public var renderId:Int = 0;

    public var startTime:Null<Float>;

    public var updateMap:WeakMap<Dynamic, Dynamic> = new WeakMap();
    public var updateBeforeMap:WeakMap<Dynamic, Dynamic> = new WeakMap();

    public var renderer:Null_DYNAMIC;
    public var material:Null_DYNAMIC;
    public var camera:Null_DYNAMIC;
    public var object:Null_DYNAMIC;
    public var scene:Null_DYNAMIC;

    public function new() {}

    private function _getMaps(referenceMap:WeakMap<Dynamic, Dynamic>, nodeRef:Dynamic):{ renderMap:WeakMap<Dynamic, Dynamic>, frameMap:WeakMap<Dynamic, Dynamic> } {
        var maps = referenceMap.get(nodeRef);
        if (maps == null) {
            maps = { renderMap:new WeakMap(), frameMap:new WeakMap() };
            referenceMap.set(nodeRef, maps);
        }
        return maps;
    }

    public function updateBeforeNode(node:Dynamic) {
        var updateType = node.getUpdateBeforeType();
        var reference = node.updateReference(this);

        switch (updateType) {
            case NodeUpdateType.FRAME:
                var maps = _getMaps(updateBeforeMap, reference);
                var frameMap = maps.frameMap;
                if (frameMap.get(reference) != frameId) {
                    if (node.updateBefore(this) != false) {
                        frameMap.set(reference, frameId);
                    }
                }
            case NodeUpdateType.RENDER:
                var maps = _getMaps(updateBeforeMap, reference);
                var renderMap = maps.renderMap;
                if (renderMap.get(reference) != renderId) {
                    if (node.updateBefore(this) != false) {
                        renderMap.set(reference, renderId);
                    }
                }
            case NodeUpdateType.OBJECT:
                node.updateBefore(this);
        }
    }

    public function updateNode(node:Dynamic) {
        var updateType = node.getUpdateType();
        var reference = node.updateReference(this);

        switch (updateType) {
            case NodeUpdateType.FRAME:
                var maps = _getMaps(updateMap, reference);
                var frameMap = maps.frameMap;
                if (frameMap.get(reference) != frameId) {
                    if (node.update(this) != false) {
                        frameMap.set(reference, frameId);
                    }
                }
            case NodeUpdateType.RENDER:
                var maps = _getMaps(updateMap, reference);
                var renderMap = maps.renderMap;
                if (renderMap.get(reference) != renderId) {
                    if (node.update(this) != false) {
                        renderMap.set(reference, renderId);
                    }
                }
            case NodeUpdateType.OBJECT:
                node.update(this);
        }
    }

    public function update() {
        frameId++;
        if (lastTime == null) lastTime = haxe.Timer.stamp();
        deltaTime = (haxe.Timer.stamp() - lastTime) / 1000;
        lastTime = haxe.Timer.stamp();
        time += deltaTime;
    }
}

// export default NodeFrame; (not necessary in Haxe, as we don't use modules like JavaScript)