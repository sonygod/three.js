enum AttributeType {
    VERTEX(1),
    INDEX(2),
    STORAGE(4);

    public var value:Int;

    function new(value:Int) {
        this.value = value;
    }
}

// size of a chunk in bytes (STD140 layout)

final var GPU_CHUNK_BYTES:Int = 16;

// @TODO: Move to src/constants.js

final var BlendColorFactor:Int = 211;
final var OneMinusBlendColorFactor:Int = 212;