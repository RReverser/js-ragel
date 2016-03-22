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
const Transform = require('stream').Transform;

function toHex(word) {
	return '0x' + ('000' + word.toString(16).toUpperCase()).slice(-4);
}

function splitBy(condition) {
	let start, end, first = true;
    return new Transform({
        objectMode: true,

        transform(item, enc, callback) {
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
        },

        flush(callback) {
            this.push({ start, end });
		    callback();
        }
    });
}

function toString(codePoints) {
	let start, end;

	return (
		_(codePoints)
		.map(codePoint => {
            let str = String.fromCodePoint(codePoint);
            let charCodes = [];
            for (let i = 0; i < str.length; i++) {
                charCodes.push(str.charCodeAt(i));
            }
            return charCodes;
        })
		.through(splitBy((item, end) => {
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
        .intersperse(' | ')
    );
}

function streamify(strings, ...substs) {
    return (
        _(strings)
        .zip(substs)
        .flatMap(([ str, subst ]) => _([ str ]).concat(toString(subst)))
        .append(strings[strings.length - 1])
    );
}

streamify`%%{
	machine javascript;

	NBSP = ${[ 0x00A0 ]};
	ZWNBSP = ${[ 0xFEFF ]};

	LS = ${[ 0x2028 ]};
	PS = ${[ 0x2029 ]};

	ZWNJ = ${[ 0x200C ]};
	ZWJ = ${[ 0x200D ]};

	USP = ${Zs};
	UnicodeIDStart = alpha | ${_(ID_Start).filter(item => !(item >= 65 && item <= 90) && !(item >= 97 && item <= 122))};
	UnicodeIDContinue = UnicodeIDStart | ${_(ID_Continue).filter(item => !ID_Start_Set.has(item))};
}%%
`.pipe(fs.createWriteStream('./unicode.rl'));
