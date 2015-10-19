const JSONStream = require('JSONStream');
const Lexer = require('./lexer');

process.stdin
.pipe(new Lexer())
.pipe(JSONStream.stringify('[\n', ',\n', '\n]\n'))
.pipe(process.stdout);
