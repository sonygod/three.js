package;

import three.js.test.unit.src.animation.AnimationObjectGroup;
import three.js.test.unit.src.core.Object3D;
import three.js.test.unit.src.animation.PropertyBinding;

class AnimationObjectGroupTests {

    static function main() {
        var ObjectA = new Object3D();
        var ObjectB = new Object3D();
        var ObjectC = new Object3D();

        var PathA = 'object.position';
        var PathB = 'object.rotation';
        var PathC = 'object.scale';

        var ParsedPathA = PropertyBinding.parseTrackName(PathA);
        var ParsedPathB = PropertyBinding.parseTrackName(PathB);
        var ParsedPathC = PropertyBinding.parseTrackName(PathC);

        // INSTANCING
        var groupA = new AnimationObjectGroup();
        trace(groupA instanceof AnimationObjectGroup, 'AnimationObjectGroup can be instanciated');

        // PROPERTIES
        // TODO: uuid
        // TODO: stats

        // PUBLIC
        var object = new AnimationObjectGroup();
        trace(object.isAnimationObjectGroup, 'AnimationObjectGroup.isAnimationObjectGroup should be true');

        // TODO: add
        // TODO: remove
        // TODO: uncache

        // OTHERS
        // TODO: smoke test
    }
}