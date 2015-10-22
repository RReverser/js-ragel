'use strict';

const through2 = require('through2');
const Lexer = require('./lexer');
const inspect = require('util').inspect;

process.stdin.setRawMode(true);

process.stdin
.pipe(through2(function (chunk, enc, callback) {
	if (chunk[chunk.length - 1] === 0x04) {
		this.push(chunk.slice(0, -1));
		this.push(null);
		process.stdin.setRawMode(false);
		process.stdin.end();
	} else {
		this.push(chunk);
	}
	callback();
}))
.pipe(new Lexer())
.pipe(through2.obj(function (token, enc, callback) {
	callback(null, inspect(token, { colors: true }) + '\n');
}))
.pipe(process.stdout);
