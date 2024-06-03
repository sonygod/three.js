import { Vector3 } from 'luxe/maths';

class OgcParser {

    static parse(buf: ArrayBuffer): { envelope: Array<Number>, primitives: Array<any> } {
        let cursor = 0;

        if (buf[0] !== 0x47 || buf[1] !== 0x50) {
            throw new Error('bad header');
        }

        let flag = buf[2];

        let littleEndian = (flag & 1) === 1;

        let envelopeSizes = [
            0, // 0: non
            4, // 1: minx, maxx, miny, maxy
            6, // 2: minx, maxx, miny, maxy, minz, maxz
            6, // 3: minx, maxx, miny, maxy, minm, maxm
            8, // 4: minx, maxx, miny, maxy, minz, maxz, minm, maxm
        ];

        let envelope = [];
        for (let i = 0; i < envelopeSizes[flag & 7]; ++i) {
            envelope.push(buf.getFloatLE(cursor, littleEndian));
            cursor += 8;
        }

        const primitives = [];

        while (cursor < buf.length) {
            let type = buf.getUint32LE(cursor);
            cursor += 4;

            switch (type) {
                case 1:
                    primitives.push({ type: 'point', point: Vector3.fromArray(buf.slice(cursor, cursor + 16), littleEndian) });
                    cursor += 16;
                    break;
                // ... handle other types
            }
        }

        return { envelope, primitives };
    }
}

export default OgcParser;