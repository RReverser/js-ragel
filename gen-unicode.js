'use strict';

function codePoints(path) {
	return require(`unicode-5.1.0/${path}/code-points`);
}

const ID_Start = codePoints('properties/ID_Start');
const ID_Start_Set = new Set(ID_Start);
const ID_Continue = codePoints('properties/ID_Continue');
const Zs = codePoints('categories/Zs');
const fs = require('fs');
const _ = require('highland');
const through2 = require('through2');

function toByteSequence(buf, codePoint) {
	let newBuf = new Buffer(String.fromCodePoint(codePoint));
	let samePrefix = buf.length === newBuf.length;
	if (samePrefix) {
		for (let i = 0; i < buf.length--; i++) {
			if (buf[i] !== newBuf[i]) {
				samePrefix = false;
				break;
			}
		}
		if (samePrefix) {
			return newBuf;
		}
	}
	return (
		_(new Buffer(String.fromCodePoint(codePoint)))
		.map(byte => '0x' + ('0' + byte.toString(16).toUpperCase()).slice(-2))
		.intersperse(' ')
	);
}

function toHex(byte) {
	return '0x' + ('0' + byte.toString(16).toUpperCase()).slice(-2);
}

function splitBy(condition) {
	let start, end, first = true;
	return through2.obj(function (item, enc, callback) {
		if (first) {
			first = false;
			start = end = item;
		} else if (condition(item, end, start)) {
			end = item;
		} else {
			this.push({ start, end });
			start = end = item;
		}
		callback();
	}, function (callback) {
		this.push({ start, end });
		callback();
	});
}

function toString(codePoints) {
	let start, end;

	return _(
		_(codePoints)
		.map(codePoint => new Buffer(String.fromCodePoint(codePoint)))
		.pipe(splitBy((item, end) => {
			let length = item.length;
			if (length !== end.length) {
				return false;
			}
			for (let i = 0; i < length - 1; i++) {
				if (item[i] !== end[i]) {
					return false;
				}
			}
			return end[length - 1] + 1 === item[length - 1];
		}))
	)
	.map(range => {
		let start = range.start, end = range.end;
		let length = start.length;
		let str = '';
		for (let i = 0; i < length - 1; i++) {
			str += toHex(start[i]) + ' ';
		}
		let lastStart = start[length - 1], lastEnd = end[length - 1];
		str += lastStart === lastEnd ? toHex(lastStart) : `${toHex(lastStart)}..${toHex(lastEnd)}`;
		return str;
	})
	.intersperse(' | ');
}

_([`%%{
	machine javascript;

	NBSP = `, toString([ 0x00A0 ]), `;
	ZWNBSP = `, toString([ 0xFEFF ]), `;

	LS = `, toString([ 0x2028 ]), `;
	PS = `, toString([ 0x2029 ]), `;

	ZWNJ = `, toString([ 0x200C ]), `;
	ZWJ = `, toString([ 0x200D ]), `;

	USP = `, toString(Zs), `;
	UnicodeIDStart = alpha | `, toString(_(ID_Start).filter(item => !(item >= 65 && item <= 90) && !(item >= 97 && item <= 122))), `;
	UnicodeIDContinue = UnicodeIDStart | `, toString(_(ID_Continue).filter(item => !ID_Start_Set.has(item))), `;
}%%
`]).flatten().pipe(fs.createWriteStream('./unicode.rl'));
