package three.js.examples.jsm.nodes.materials;

import NodeMaterial.*;
import InstancedPointsNodeMaterial.*;
import LineBasicNodeMaterial.*;
import LineDashedNodeMaterial.*;
import Line2NodeMaterial.*;
import MeshNormalNodeMaterial.*;
import MeshBasicNodeMaterial.*;
import MeshLambertNodeMaterial.*;
import MeshPhongNodeMaterial.*;
import MeshStandardNodeMaterial.*;
import MeshPhysicalNodeMaterial.*;
import MeshSSSNodeMaterial.*;
import MeshToonNodeMaterial.*;
import MeshMatcapNodeMaterial.*;
import PointsNodeMaterial.*;
import SpriteNodeMaterial.*;
import ShadowNodeMaterial.*;

extern class NodeMaterial {}
extern class InstancedPointsNodeMaterial {}
extern class LineBasicNodeMaterial {}
extern class LineDashedNodeMaterial {}
extern class Line2NodeMaterial {}
extern class MeshNormalNodeMaterial {}
extern class MeshBasicNodeMaterial {}
extern class MeshLambertNodeMaterial {}
extern class MeshPhongNodeMaterial {}
extern class MeshStandardNodeMaterial {}
extern class MeshPhysicalNodeMaterial {}
extern class MeshSSSNodeMaterial {}
extern class MeshToonNodeMaterial {}
extern class MeshMatcapNodeMaterial {}
extern class PointsNodeMaterial {}
extern class SpriteNodeMaterial {}
extern class ShadowNodeMaterial {}

// Export NodeMaterial
@:native("NodeMaterial")
extern class NodeMaterial {
    static function addNodeMaterial():Void;
    static function createNodeMaterialFromType():Void;
}

// Export other materials
@:native("InstancedPointsNodeMaterial")
extern class InstancedPointsNodeMaterial {}

@:native("LineBasicNodeMaterial")
extern class LineBasicNodeMaterial {}

@:native("LineDashedNodeMaterial")
extern class LineDashedNodeMaterial {}

@:native("Line2NodeMaterial")
extern class Line2NodeMaterial {}

@:native("MeshNormalNodeMaterial")
extern class MeshNormalNodeMaterial {}

@:native("MeshBasicNodeMaterial")
extern class MeshBasicNodeMaterial {}

@:native("MeshLambertNodeMaterial")
extern class MeshLambertNodeMaterial {}

@:native("MeshPhongNodeMaterial")
extern class MeshPhongNodeMaterial {}

@:native("MeshStandardNodeMaterial")
extern class MeshStandardNodeMaterial {}

@:native("MeshPhysicalNodeMaterial")
extern class MeshPhysicalNodeMaterial {}

@:native("MeshSSSNodeMaterial")
extern class MeshSSSNodeMaterial {}

@:native("MeshToonNodeMaterial")
extern class MeshToonNodeMaterial {}

@:native("MeshMatcapNodeMaterial")
extern class MeshMatcapNodeMaterial {}

@:native("PointsNodeMaterial")
extern class PointsNodeMaterial {}

@:native("SpriteNodeMaterial")
extern class SpriteNodeMaterial {}

@:native("ShadowNodeMaterial")
extern class ShadowNodeMaterial {}