%%machine javascript;

function charCode(ch) {
    return ch.charCodeAt(0);
}

const CHR_A = charCode('A');
const CHR_a = charCode('a');
const CHR_0 = charCode('0');

%%include "syntax.rl";

module.exports = class Lexer extends require('stream').Transform {
	constructor(options) {
		super({
            decodeStrings: true,
			readableObjectMode: true
		});

		%%write init;

        this.rawSliceStart = 0;
        this.number = 0;
        this.string = '';

        this.leftOver = '';
		this.tmplLevel = 0;
		this.permitRegexp = true;

        this.goal = options.goal;
        this.strict = this.goal === 'module';
        this.onToken = options.onToken;
	}
    
    pushToken(data, token) {
        token.raw = data.slice(this.ts, this.te);
        this.onToken(token);
        this.push(token);
    }

	exec(data, callback) {
        let p = this.leftOver.length;
        const eof = data !== null ? -1 : p;
        data = this.leftOver + (data || '');
		%%write exec;
        if (this.cs === javascript_error) {
            this.emit('error', new Error('Parsing error: unrecognized character at "' + data.slice(p, p + 3) + '..."'));
            return;
        }
        if (this.ts >= 0) {
            this.leftOver = data.slice(this.ts);
            this.te -= this.ts;
            this.rawSliceStart -= this.ts;
            this.ts = 0;
        } else {
            this.leftOver = '';
        }
		callback();
	}

	_transform(data, enc, callback) {
		this.exec(data, callback);
	}

	_flush(callback) {
		this.exec(null, callback);
	}
};
