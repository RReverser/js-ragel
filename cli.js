'use strict';

const Lexer = require('./lexer');
const inspect = require('util').inspect;
const Transform = require('stream').Transform;

class Reader {
    constructor() {
        this.values = [];
        this.curly = this.paren = -1;
    }

    // A function following one of those tokens is an expression.
    beforeFunctionExpression(t) {
        return ['(', '{', '[', 'in', 'typeof', 'instanceof', 'new',
            'return', 'case', 'delete', 'throw', 'void',
            // assignment operators
            '=', '+=', '-=', '*=', '/=', '%=', '<<=', '>>=', '>>>=',
            '&=', '|=', '^=', ',',
            // binary/unary operators
            '+', '-', '*', '/', '%', '++', '--', '<<', '>>', '>>>', '&',
            '|', '^', '!', '~', '&&', '||', '?', ':', '===', '==', '>=',
            '<=', '<', '>', '!=', '!=='].indexOf(t) >= 0;
    }

    // Determine if forward slash (/) is an operator or part of a regular expression
    // https://github.com/mozilla/sweet.js/wiki/design
    isRegexStart() {
        const previous = this.values[this.values.length - 1];

        switch (previous) {
            case 'this':
            case ']':
                return false;

            case ')':
                const check = this.values[this.paren - 1];
                return (check === 'if' || check === 'while' || check === 'for' || check === 'with');

            case '}':
                // Dividing a function by anything makes little sense,
                // but we have to check for that.
                if (this.values[this.curly - 3] === 'function') {
                    // Anonymous function, e.g. function(){} /42
                    const check = this.values[this.curly - 4];
                    return check ? !this.beforeFunctionExpression(check) : false;
                } else if (this.values[this.curly - 4] === 'function') {
                    // Named function, e.g. function f(){} /42/
                    const check = this.values[this.curly - 5];
                    return check ? !this.beforeFunctionExpression(check) : true;
                } else {
                    return false;
                }
                
            case null:
                return false;
                
            default:
                return true;
        }
    }

    push(token) {
        if (token.type === 'Punctuator' || token.type === 'IdentifierName') {
            if (token.raw === '{') {
                this.curly = this.values.length;
            } else if (token.raw === '(') {
                this.paren = this.values.length;
            }
            this.values.push(token.raw);
        } else {
            this.values.push(null);
        }
    }
}

process.stdin.setRawMode(true);

let reader = new Reader();

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
.pipe(new Lexer({
    goal: 'script',
    onToken(token) {
        reader.push(token);
        this.permitRegexp = reader.isRegexStart();
    }
}))
.pipe(new Transform({
    objectMode: true,

    transform(token, enc, callback) {
        callback(null, inspect(token, { colors: true }) + '\n');
    }
}))
.pipe(process.stdout);
