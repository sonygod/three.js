package three.js.examples.jsm.exporters;

import haxe.Json;
import haxe.io.Bytes;

class GLTFExporter
{
    public var json:Json;
    public var cache:Map<String, Dynamic>;
    public var options:Dynamic;
    public var pending:Array<Promise<Dynamic>>;
    public var byteOffset:Int;

    public function new()
    {
        json = {};
        cache = new Map<String, Dynamic>();
        options = {};
        pending = [];
        byteOffset = 0;
    }

    public function processBufferView(attribute:Dynamic, componentType:Int, start:Int, count:Int, target:Int):{ id:Int, byteLength:Int }
    {
        if (!json.bufferViews) json.bufferViews = [];

        var componentSize:Int;
        switch (componentType)
        {
            case WebGL.BYTE:
            case WebGL.UNSIGNED_BYTE:
                componentSize = 1;
            case WebGL.SHORT:
            case WebGL.UNSIGNED_SHORT:
                componentSize = 2;
            default:
                componentSize = 4;
        }

        var byteStride:Int = attribute.itemSize * componentSize;
        if (target == WebGL.ARRAY_BUFFER)
        {
            byteStride = Math.ceil(byteStride / 4) * 4;
        }

        var byteLength:Int = getPaddedBufferSize(count * byteStride);
        var dataView:Bytes = Bytes.alloc(byteLength);
        var offset:Int = 0;

        for (i in start...start + count)
        {
            for (a in 0...attribute.itemSize)
            {
                var value:Float;
                if (attribute.itemSize > 4)
                {
                    // no support for interleaved data for itemSize > 4
                    value = attribute.array[i * attribute.itemSize + a];
                }
                else
                {
                    if (a == 0) value = attribute.getX(i);
                    else if (a == 1) value = attribute.getY(i);
                    else if (a == 2) value = attribute.getZ(i);
                    else if (a == 3) value = attribute.getW(i);

                    if (attribute.normalized)
                    {
                        value = MathUtils.normalize(value, attribute.array);
                    }
                }

                switch (componentType)
                {
                    case WebGL.FLOAT:
                        dataView.setFloat32(offset, value, true);
                    case WebGL.INT:
                        dataView.setInt32(offset, Std.int(value), true);
                    case WebGL.UNSIGNED_INT:
                        dataView.setUint32(offset, Std.int(value), true);
                    case WebGL.SHORT:
                        dataView.setInt16(offset, Std.int(value), true);
                    case WebGL.UNSIGNED_SHORT:
                        dataView.setUint16(offset, Std.int(value), true);
                    case WebGL.BYTE:
                        dataView.setInt8(offset, Std.int(value));
                    case WebGL.UNSIGNED_BYTE:
                        dataView.setUint8(offset, Std.int(value));
                }

                offset += componentSize;

                if ((offset % byteStride) != 0)
                {
                    offset += byteStride - (offset % byteStride);
                }
            }
        }

        var bufferViewDef =
        {
            buffer: processBuffer(dataView),
            byteOffset: byteOffset,
            byteLength: byteLength
        };

        if (target != null) bufferViewDef.target = target;

        if (target == WebGL.ARRAY_BUFFER)
        {
            bufferViewDef.byteStride = byteStride;
        }

        byteOffset += byteLength;

        json.bufferViews.push(bufferViewDef);

        return { id: json.bufferViews.length - 1, byteLength: 0 };
    }

    public function processBufferViewImage(blob:Bytes):Promise<Int>
    {
        var writer:GLTFExporter = this;
        var json:Json = writer.json;

        if (!json.bufferViews) json.bufferViews = [];

        return new Promise<Int>(function (resolve) {
            var reader:FileReader = new FileReader();
            reader.readAsArrayBuffer(blob);
            reader.onloadend = function () {
                var buffer:Bytes = reader.result;
                var bufferViewDef =
                {
                    buffer: writer.processBuffer(buffer),
                    byteOffset: writer.byteOffset,
                    byteLength: buffer.byteLength
                };
                writer.byteOffset += buffer.byteLength;
                resolve(json.bufferViews.push(bufferViewDef) - 1);
            };
        });
    }

    public function processAccessor(attribute:Dynamic, geometry:Dynamic, start:Int, count:Int):Int
    {
        var json:Json = this.json;

        var types:Array<String> = ['SCALAR', 'VEC2', 'VEC3', 'VEC4', 'MAT3', 'MAT4'];

        var componentType:Int;
        if (attribute.array.constructor == Float32Array)
        {
            componentType = WebGL.FLOAT;
        }
        else if (attribute.array.constructor == Int32Array)
        {
            componentType = WebGL.INT;
        }
        else if (attribute.array.constructor == Uint32Array)
        {
            componentType = WebGL.UNSIGNED_INT;
        }
        else if (attribute.array.constructor == Int16Array)
        {
            componentType = WebGL.SHORT;
        }
        else if (attribute.array.constructor == Uint16Array)
        {
            componentType = WebGL.UNSIGNED_SHORT;
        }
        else if (attribute.array.constructor == Int8Array)
        {
            componentType = WebGL.BYTE;
        }
        else if (attribute.array.constructor == Uint8Array)
        {
            componentType = WebGL.UNSIGNED_BYTE;
        }
        else
        {
            throw new Error('THREE.GLTFExporter: Unsupported bufferAttribute component type: ' + attribute.array.constructor.name);
        }

        if (start == null) start = 0;
        if (count == null || count == Math.POSITIVE_INFINITY) count = attribute.count;

        if (count == 0) return null;

        var minMax:Array<Float> = getMinMax(attribute, start, count);
        var bufferViewTarget:Int;

        if (geometry != null)
        {
            bufferViewTarget = attribute == geometry.index ? WebGL.ELEMENT_ARRAY_BUFFER : WebGL.ARRAY_BUFFER;
        }

        var bufferView:{ id:Int, byteLength:Int } = processBufferView(attribute, componentType, start, count, bufferViewTarget);

        var accessorDef =
        {
            bufferView: bufferView.id,
            byteOffset: bufferView.byteOffset,
            componentType: componentType,
            count: count,
            max: minMax[1],
            min: minMax[0],
            type: types[attribute.itemSize]
        };

        if (attribute.normalized) accessorDef.normalized = true;

        if (!json.accessors) json.accessors = [];

        return json.accessors.push(accessorDef) - 1;
    }

    public function processImage(image:Dynamic, format:Dynamic, flipY:Bool, mimeType:String = 'image/png'):Int
    {
        if (image != null)
        {
            var writer:GLTFExporter = this;
            var cache:Map<String, Dynamic> = writer.cache;
            var json:Json = writer.json;
            var options:Dynamic = writer.options;
            var pending:Array<Promise<Dynamic>> = writer.pending;

            if (!cache.images.has(image))
            {
                cache.images.set(image, {});
            }

            var cachedImages:Dynamic = cache.images.get(image);

            var key:String = mimeType + ':flipY/' + flipY.toString();

            if (cachedImages[key] != null) return cachedImages[key];

            if (!json.images) json.images = [];

            var imageDef:Dynamic = { mimeType: mimeType };

            var canvas:HtmlCanvasElement = getCanvas();

            canvas.width = Math.min(image.width, options.maxTextureSize);
            canvas.height = Math.min(image.height, options.maxTextureSize);

            var ctx:CanvasRenderingContext2D = canvas.getContext('2d');

            if (flipY)
            {
                ctx.translate(0, canvas.height);
                ctx.scale(1, -1);
            }

            if (image.data != null) // THREE.DataTexture
            {
                if (format != RGBAFormat)
                {
                    console.error('GLTFExporter: Only RGBAFormat is supported.', format);
                }

                if (image.width > options.maxTextureSize || image.height > options.maxTextureSize)
                {
                    console.warn('GLTFExporter: Image size is bigger than maxTextureSize', image);
                }

                var data:Uint8ClampedArray = new Uint8ClampedArray(image.height * image.width * 4);

                for (i in 0...data.length) i += 4
                {
                    data[i + 0] = image.data[i + 0];
                    data[i + 1] = image.data[i + 1];
                    data[i + 2] = image.data[i + 2];
                    data[i + 3] = image.data[i + 3];
                }

                ctx.putImageData(new ImageData(data, image.width, image.height), 0, 0);
            }
            else
            {
                if ((typeof HTMLImageElement != 'undefined' && image instanceof HTMLImageElement) ||
                    (typeof HTMLCanvasElement != 'undefined' && image instanceof HTMLCanvasElement) ||
                    (typeof ImageBitmap != 'undefined' && image instanceof ImageBitmap) ||
                    (typeof OffscreenCanvas != 'undefined' && image instanceof OffscreenCanvas))
                {
                    ctx.drawImage(image, 0, 0, canvas.width, canvas.height);
                }
                else
                {
                    throw new Error('THREE.GLTFExporter: Invalid image type. Use HTMLImageElement, HTMLCanvasElement, ImageBitmap or OffscreenCanvas.');
                }
            }

            if (options.binary)
            {
                pending.push(getToBlobPromise(canvas, mimeType).then(function (blob) {
                    return writer.processBufferViewImage(blob);
                }).then(function (bufferViewIndex) {
                    imageDef.bufferView = bufferViewIndex;
                }));
            }
            else
            {
                if (canvas.toDataURL != null)
                {
                    imageDef.uri = canvas.toDataURL(mimeType);
                }
                else
                {
                    pending.push(getToBlobPromise(canvas, mimeType).then(function (blob) {
                        return new FileReader().readAsDataURL(blob);
                    }).then(function (dataURL) {
                        imageDef.uri = dataURL;
                    }));
                }
            }

            var index:Int = json.images.push(imageDef) - 1;
            cachedImages[key] = index;
            return index;
        }
        else
        {
            throw new Error('THREE.GLTFExporter: No valid image data found. Unable to process texture.');
        }
    }

    public function processSampler(map:Dynamic):Int
    {
        var json:Json = this.json;

        if (!json.samplers) json.samplers = [];

        var samplerDef:Dynamic =
        {
            magFilter: THREE_TO_WEBGL[map.magFilter],
            minFilter: THREE_TO_WEBGL[map.minFilter],
            wrapS: THREE_TO_WEBGL[map.wrapS],
            wrapT: THREE_TO_WEBGL[map.wrapT]
        };

        return json.samplers.push(samplerDef) - 1;
    }

    public function processTexture(map:Dynamic):Int
    {
        var writer:GLTFExporter = this;
        var options:Dynamic = writer.options;
        var cache:Map<String, Dynamic> = writer.cache;
        var json:Json = writer.json;

        if (cache.textures.has(map)) return cache.textures.get(map);

        if (!json.textures) json.textures = [];

        // make non-readable textures (e.g. CompressedTexture) readable by blitting them into a new texture
        if (Std.is(map, CompressedTexture))
        {
            map = decompress(map, options.maxTextureSize);
        }

        var mimeType:String = map.userData.mimeType;

        if (mimeType == 'image/webp') mimeType = 'image/png';

        var textureDef:Dynamic =
        {
            sampler: writer.processSampler(map),
            source: writer.processImage(map.image, map.format, map.flipY, mimeType)
        };

        if (map.name) textureDef.name = map.name;

        writer._invokeAll(function (ext) {
            ext.writeTexture && ext.writeTexture(map, textureDef);
        });

        var index:Int = json.textures.push(textureDef) - 1;
        cache.textures.set(map, index);
        return index;
    }
}