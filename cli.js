'use strict';

const Lexer = require('./lexer');
const inspect = require('util').inspect;
const Transform = require('stream').Transform;

process.stdin.setRawMode(true);

process.stdin
.pipe(new Transform({
    objectMode: true,

    transform(chunk, enc, callback) {
        if (chunk[chunk.length - 1] === 0x03) {
            this.push(chunk.slice(0, -1));
            this.push(null);
            process.stdin.setRawMode(false);
            process.stdin.end();
        } else {
            this.push(chunk);
        }
        callback();
    }
}))
.pipe(new Lexer({ goal: 'script' }))
.pipe(new Transform({
    objectMode: true,

    transform(token, enc, callback) {
        callback(null, inspect(token, { colors: true }) + '\n');
    }
}))
.pipe(process.stdout);
