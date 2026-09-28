const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');

const workspace = process.argv[2];
const projectRequire = createRequire(path.resolve(workspace, 'package.json'));
for (const name of ['@playwright/test', 'playwright', 'playwright-core']) {
    let manifest;
    try {
        manifest = projectRequire.resolve(`${name}/package.json`);
    } catch (error) {
        if (error.code === 'MODULE_NOT_FOUND') continue;
        throw error;
    }
    const cli = path.join(path.dirname(manifest), 'cli.js');
    if (!fs.existsSync(cli)) throw new Error(`Installed ${name} has no CLI: ${cli}`);
    console.log(cli);
    break;
}
