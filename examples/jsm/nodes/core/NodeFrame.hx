package three.js.examples.jm.nodes.core;

import three.js.examples.jm.constants.NodeUpdateType;

class NodeFrame {

    public var time:Float = 0;
    public var deltaTime:Float = 0;

    public var frameId:Int = 0;
    public var renderId:Int = 0;

    public var startTime:Null<Float>;

    public var updateMap:WeakMap<Dynamic, { renderMap:WeakMap<Dynamic, Int>, frameMap:WeakMap<Dynamic, Int> }>;
    public var updateBeforeMap:WeakMap<Dynamic, { renderMap:WeakMap<Dynamic, Int>, frameMap:WeakMap<Dynamic, Int> }>;

    public var renderer:Null<Dynamic>;
    public var material:Null<Dynamic>;
    public var camera:Null<Dynamic>;
    public var object:Null<Dynamic>;
    public var scene:Null<Dynamic>;

    public function new() {
        updateMap = new WeakMap();
        updateBeforeMap = new WeakMap();
    }

    private function _getMaps(referenceMap:WeakMap<Dynamic, Dynamic>, nodeRef:Dynamic):{ renderMap:WeakMap<Dynamic, Int>, frameMap:WeakMap<Dynamic, Int> } {
        var maps:Null<{ renderMap:WeakMap<Dynamic, Int>, frameMap:WeakMap<Dynamic, Int> }> = referenceMap.get(nodeRef);

        if (maps == null) {
            maps = {
                renderMap: new WeakMap(),
                frameMap: new WeakMap()
            };
            referenceMap.set(nodeRef, maps);
        }

        return maps;
    }

    public function updateBeforeNode(node:Dynamic) {
        var updateType:Int = node.getUpdateBeforeType();
        var reference:Dynamic = node.updateReference(this);

        switch (updateType) {
            case NodeUpdateType.FRAME:
                var maps:{ renderMap:WeakMap<Dynamic, Int>, frameMap:WeakMap<Dynamic, Int> } = _getMaps(updateBeforeMap, reference);
                if (maps.frameMap.get(reference) != frameId) {
                    if (node.updateBefore(this) != false) {
                        maps.frameMap.set(reference, frameId);
                    }
                }
            case NodeUpdateType.RENDER:
                var maps:{ renderMap:WeakMap<Dynamic, Int>, frameMap:WeakMap<Dynamic, Int> } = _getMaps(updateBeforeMap, reference);
                if (maps.renderMap.get(reference) != renderId) {
                    if (node.updateBefore(this) != false) {
                        maps.renderMap.set(reference, renderId);
                    }
                }
            case NodeUpdateType.OBJECT:
                node.updateBefore(this);
        }
    }

    public function updateNode(node:Dynamic) {
        var updateType:Int = node.getUpdateType();
        var reference:Dynamic = node.updateReference(this);

        switch (updateType) {
            case NodeUpdateType.FRAME:
                var maps:{ renderMap:WeakMap<Dynamic, Int>, frameMap:WeakMap<Dynamic, Int> } = _getMaps(updateMap, reference);
                if (maps.frameMap.get(reference) != frameId) {
                    if (node.update(this) != false) {
                        maps.frameMap.set(reference, frameId);
                    }
                }
            case NodeUpdateType.RENDER:
                var maps:{ renderMap:WeakMap<Dynamic, Int>, frameMap:WeakMap<Dynamic, Int> } = _getMaps(updateMap, reference);
                if (maps.renderMap.get(reference) != renderId) {
                    if (node.update(this) != false) {
                        maps.renderMap.set(reference, renderId);
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

    private var lastTime:Null<Float>;

}