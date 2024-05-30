import js.js_typed_array.Float32Array;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.IBitmapDrawable;
import openfl.display.InteractiveObject;
import openfl.display.Loader;
import openfl.display.LoaderInfo;
import openfl.errors.Error;
import openfl.events.ActivityEvent;
import openfl.events.Event;
import openfl.events.FocusEvent;
import openfl.events.FullScreenEvent;
import openfl.events.GameInputEvent;
import openfl.events.HTTPStatusEvent;
import openfl.events.IOErrorEvent;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.events.NetStatusEvent;
import openfl.events.ProgressEvent;
import openfl.events.SecurityErrorEvent;
import openfl.events.TextEvent;
import openfl.events.UncaughtErrorEvent;
import openfl.events.VideoEvent;
import openfl.filters.BitmapFilter;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openMultiplier.core.InstancedInterleavedBuffer;
import openfl.geom.Rectangle;
import openfl.media.ID3Info;
import openfl.net.NetConnection;
import openfl.net.NetStream;
import openfl.system.Security;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.utils.ByteArray;
import openfl.utils.IDataInput;
import openfl.utils.IDataOutput;

class TestInstancedInterleavedBuffer {
    public static function main() {
        var array = new Float32Array([1, 2, 3, 7, 8, 9]);
        var instance = new InstancedInterleavedBuffer(array, 3);

        var assert = new QUnit.Assert();

        // INHERITANCE
        assert.strictEqual(instance instanceof openfl.utils.InterleavedBuffer, true, 'InstancedInterleavedBuffer extends from InterleavedBuffer');

        // INSTANCING
        assert.strictEqual(instance.meshPerAttribute, 1, 'ok');

        // PUBLIC
        assert.strictEqual(instance.isInstancedInterleavedBuffer, true, 'InstancedInterleavedBuffer.isInstancedInterleavedBuffer should be true');

        var copiedInstance = instance.copy(instance);
        assert.strictEqual(copiedInstance.meshPerAttribute, 1, 'additional attribute was copied');
    }
}

TestInstancedInterleavedBuffer.main();