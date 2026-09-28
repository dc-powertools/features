const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const source = path.resolve(__dirname, '../../src/node/postStart.sh');
test('Node startup installs incrementally, skips other managers, and propagates failures', () => {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'node-startup-'));
    const workspace = path.join(dir, 'workspace with spaces');
    fs.mkdirSync(workspace);
    fs.copyFileSync(source, path.join(dir, 'postStart.sh'));
    const flag = path.join(dir, 'install-on-start');
    fs.writeFileSync(flag, 'true\n');
    const run = () => spawnSync('bash', [path.join(dir, 'postStart.sh'), workspace], { encoding: 'utf8' });
    const success = () => {
        const result = run();
        assert.equal(result.status, 0, result.stdout + result.stderr);
    };
    const manifest = { name: 'startup-fixture', version: '1.0.0', private: true,
        dependencies: { fixture: 'file:./fixture' }, scripts: { postinstall: 'node count.cjs' } };
    const writeManifest = () => fs.writeFileSync(path.join(workspace, 'package.json'), JSON.stringify(manifest));
    try {
        success(); // No package.json is a valid workspace.
        assert.ok(!fs.existsSync(path.join(workspace, 'package-lock.json')));
        fs.mkdirSync(path.join(workspace, 'fixture'));
        fs.writeFileSync(path.join(workspace, 'fixture/package.json'), '{"name":"fixture","version":"1.0.0"}');
        fs.writeFileSync(path.join(workspace, 'count.cjs'), `const fs = require('fs');
            const n = fs.existsSync('count') ? Number(fs.readFileSync('count', 'utf8')) : 0;
            fs.writeFileSync('count', String(n + 1));`);
        writeManifest();
        fs.writeFileSync(flag, 'false\n');
        success();
        assert.ok(!fs.existsSync(path.join(workspace, 'count')));
        fs.writeFileSync(flag, 'true\n');
        fs.writeFileSync(path.join(workspace, 'pnpm-lock.yaml'), 'lockfileVersion: 9\n');
        success();
        assert.ok(!fs.existsSync(path.join(workspace, 'package-lock.json')));
        fs.unlinkSync(path.join(workspace, 'pnpm-lock.yaml'));
        success();
        assert.ok(fs.existsSync(path.join(workspace, 'node_modules/fixture/package.json')));
        fs.writeFileSync(path.join(workspace, 'node_modules/fixture/kept'), 'preserved');
        success();
        assert.equal(fs.readFileSync(path.join(workspace, 'count'), 'utf8'), '2');
        assert.ok(fs.existsSync(path.join(workspace, 'node_modules/fixture/kept')));
        manifest.packageManager = 'yarn@4.0.0';
        writeManifest();
        success(); // Explicit manager takes priority even with an npm lockfile.
        assert.equal(fs.readFileSync(path.join(workspace, 'count'), 'utf8'), '2');
        delete manifest.packageManager;
        manifest.scripts.preinstall = 'exit 7';
        writeManifest();
        assert.equal(run().status, 7);
    } finally {
        fs.rmSync(dir, { recursive: true, force: true });
    }
});
