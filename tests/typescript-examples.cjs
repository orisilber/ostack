// Run with TYPESCRIPT_PATH pointing to a TypeScript package (or install it locally).
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const vm = require('node:vm');
const ts = require(process.env.TYPESCRIPT_PATH || 'typescript');

const document = fs.readFileSync(path.join(__dirname,
  '../skills/typescript-best-practices/references/patterns.md'), 'utf8');
const blocks = [...document.matchAll(/```ts\n([\s\S]*?)\n```/g)].map(match => match[1]);
const block = marker => {
  const matches = blocks.filter(code => code.includes(marker));
  assert.equal(matches.length, 1, `Expected one example containing ${marker}`);
  return matches[0];
};
const tuple = block('type NonEmpty<T>');
const source = [
  tuple.slice(0, tuple.indexOf('// Don\'t')),
  tuple.slice(tuple.indexOf('// Do:')),
  block('const isNonEmpty'),
  block('function nonEmptySnapshot'),
  '// Do:' + block('function nonNegativeDurationMs').split('// Do:')[1],
  `
function typeAssertions() {
  // @ts-expect-error empty tuples cannot be passed
  pickWinner([]);
  const entries: NonEmpty<string> = ["one"];
  // @ts-expect-error readonly tuples have no mutating pop
  entries.pop();
  // @ts-expect-error raw negative numbers are not validated durations
  const negative: TimeRange = { start: new Date(), duration: -1 };
  // @ts-expect-error raw positive numbers also require boundary validation
  const raw: TimeRange = { start: new Date(), duration: 1 };
  // @ts-expect-error a structural wrapper cannot impersonate the number brand
  const fabricated: TimeRange = { start: new Date(), duration: { milliseconds: -1 } };
}
`,
].join('\n');
const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'ostack-typescript-'));
try {
  const file = path.join(directory, 'examples.ts');
  fs.writeFileSync(file, source);
  const options = { strict: true, noUncheckedIndexedAccess: true, noEmit: true,
    target: ts.ScriptTarget.ES2020, types: [] };
  const program = ts.createProgram([file], options);
  const diagnostics = ts.getPreEmitDiagnostics(program);
  assert.equal(diagnostics.length, 0, ts.formatDiagnosticsWithColorAndContext(diagnostics, {
    getCanonicalFileName: name => name, getCurrentDirectory: () => directory,
    getNewLine: () => '\n',
  }));
  const javascript = ts.transpileModule(source, { compilerOptions: options }).outputText;
  vm.runInNewContext(javascript + `
    for (const value of [-1, NaN, Infinity, -Infinity]) {
      assert.throws(() => nonNegativeDurationMs(value));
    }
    assert.equal(nonNegativeDurationMs(0), 0);
    assert.equal(nonNegativeDurationMs(12), 12);
    assert.throws(() => nonEmptySnapshot([]));
    const original = ["winner"];
    const snapshot = nonEmptySnapshot(original);
    original.pop();
    assert.equal(pickWinner(snapshot), "winner");
    assert.equal(Object.isFrozen(snapshot), true);
    assert.throws(() => snapshot.pop());
  `, { assert });
  console.log(`TYPESCRIPT EXAMPLES: PASS (TypeScript ${ts.version}, strict + noUncheckedIndexedAccess; runtime boundary and alias checks)`);
} finally {
  fs.rmSync(directory, { recursive: true, force: true });
}
