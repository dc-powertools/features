const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const source = path.resolve(__dirname, '../../src/playwright');
test('Playwright startup records successful versions and browsers and retries failures', () => {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'playwright-startup-'));
    const workspace = path.join(dir, 'workspace with spaces');
    fs.mkdirSync(workspace);
    for (const file of ['postStart.sh', 'install-deps.sh', 'resolve-cli.cjs']) {
        fs.copyFileSync(path.join(source, file), path.join(dir, file));
        fs.chmodSync(path.join(dir, file), 0o755);
    }
    const browsers = path.join(dir, 'browsers');
    const state = path.join(dir, 'deps-state');
    fs.writeFileSync(browsers, 'chromium\n');
    const run = () => spawnSync('bash', [path.join(dir, 'postStart.sh'), workspace], { encoding: 'utf8' });
    const success = () => {
        const result = run();
        assert.equal(result.status, 0, result.stdout + result.stderr);
    };
    const pkg = path.join(workspace, 'node_modules/@playwright/test');
    try {
        success();
        assert.ok(!fs.existsSync(state));
        fs.mkdirSync(pkg, { recursive: true });
        const version = value => fs.writeFileSync(path.join(pkg, 'package.json'), JSON.stringify({ name: '@playwright/test', version: value }));
        version('1.61.0');
        fs.writeFileSync(path.join(pkg, 'cli.js'), `const fs = require('fs');
            const path = require('path');
            if (process.argv[2] === '--version') {
                console.log('Version ' + require('./package.json').version);
            } else {
                fs.appendFileSync(path.join(__dirname, 'calls'), JSON.stringify(process.argv.slice(2)) + '\\n');
                if (fs.existsSync(path.join(__dirname, 'fail'))) process.exit(9);
            }`);
        const calls = () => fs.readFileSync(path.join(pkg, 'calls'), 'utf8').trim().split('\n').map(JSON.parse);
        success();
        assert.equal(fs.readFileSync(state, 'utf8'), '1.61.0 chromium\n');
        assert.equal(fs.statSync(state).mode & 0o777, 0o644);
        success();
        assert.equal(calls().length, 1);
        version('1.62.0');
        fs.writeFileSync(path.join(pkg, 'fail'), '');
        assert.equal(run().status, 9);
        assert.equal(fs.readFileSync(state, 'utf8'), '1.61.0 chromium\n');
        fs.unlinkSync(path.join(pkg, 'fail'));
        success();
        assert.equal(fs.readFileSync(state, 'utf8'), '1.62.0 chromium\n');
        assert.equal(calls().length, 3);
        fs.writeFileSync(browsers, 'all\n');
        success();
        assert.deepEqual(calls().at(-1), ['install-deps']);
        assert.equal(fs.readFileSync(state, 'utf8'), '1.62.0 all\n');
        success();
        assert.equal(calls().length, 4);
        fs.writeFileSync(browsers, 'webkit\n');
        success();
        assert.deepEqual(calls().at(-1), ['install-deps', 'webkit']);
        // A new container without a state record must install again.
        fs.unlinkSync(state);
        success();
        assert.equal(calls().length, 6);
        // Also discover plain playwright and playwright-core installations.
        for (const name of ['playwright', 'playwright-core']) {
            const target = path.join(workspace, 'node_modules', name);
            fs.mkdirSync(target);
            fs.writeFileSync(path.join(target, 'package.json'), JSON.stringify({ name, version: '1.62.0' }));
            fs.writeFileSync(path.join(target, 'cli.js'), '');
        }
        fs.renameSync(pkg, path.join(workspace, 'removed-test-package'));
        const resolve = () => spawnSync('node', [path.join(dir, 'resolve-cli.cjs'), workspace], { encoding: 'utf8' });
        assert.equal(resolve().stdout.trim(), path.join(workspace, 'node_modules/playwright/cli.js'));
        fs.renameSync(path.join(workspace, 'node_modules/playwright'), path.join(workspace, 'removed-playwright'));
        assert.equal(resolve().stdout.trim(), path.join(workspace, 'node_modules/playwright-core/cli.js'));
    } finally {
        fs.rmSync(dir, { recursive: true, force: true });
    }
});
