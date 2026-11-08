// Runs the React Compiler on files and reports which functions compile.
// Usage (from the project root): node compiler-check.cjs [--print] <file.tsx>...
// --print also prints the compiled code, to check what each cache block depends on.
// Needs babel-plugin-react-compiler and Babel (Next's bundled copy or @babel/core) in the project.
const { createRequire } = require('node:module');
const fs = require('node:fs');
const path = require('node:path');

const req = createRequire(path.join(process.cwd(), 'noop.js'));
const tryReq = (...ids) => {
  for (const id of ids) {
    try { return req(id); } catch {}
  }
  throw new Error(`None found: ${ids.join(', ')}`);
};
const resolve = (...ids) => {
  for (const id of ids) {
    try { return req.resolve(id); } catch {}
  }
  throw new Error(`None found: ${ids.join(', ')}`);
};

const babel = tryReq('next/dist/compiled/babel/core', '@babel/core');
const syntaxTs = resolve('next/dist/compiled/babel/plugin-syntax-typescript', '@babel/plugin-syntax-typescript');
const compiler = resolve('babel-plugin-react-compiler');

const args = process.argv.slice(2);
const print = args.includes('--print');

for (const file of args.filter((a) => a !== '--print')) {
  const result = babel.transformSync(fs.readFileSync(file, 'utf8'), {
    filename: file,
    babelrc: false,
    configFile: false,
    plugins: [
      [syntaxTs, { isTSX: true }],
      [compiler, {
        logger: {
          logEvent: (_, e) => {
            const line = e.fnLoc?.start?.line;
            if (e.kind === 'CompileSuccess') console.log(`ok    ${file} ${e.fnName}:${line}`);
            if (e.kind === 'CompileError') console.log(`FAIL  ${file}:${line} ${e.detail?.options?.reason ?? e.detail?.reason}`);
          },
        },
      }],
    ],
  });
  if (print) console.log(result.code);
}
