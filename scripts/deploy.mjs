import fs from 'node:fs/promises';
import path from 'node:path';
import rokuDeploy from 'roku-deploy';

const rootDir = process.cwd();
const configPath = path.join(rootDir, 'rokudeploy.json');
const outDir = path.join(rootDir, 'out');
const outFile = 'ABSTV';
const stagingDir = path.join(rootDir, 'build', 'staging');
const packageStagingDir = path.join(rootDir, 'build', 'package-staging');

let rawConfig;
try {
  rawConfig = await fs.readFile(configPath, 'utf8');
} catch (error) {
  console.error('Missing rokudeploy.json. Copy rokudeploy.example.json to rokudeploy.json and fill in your Roku device details.');
  process.exit(1);
}

const config = JSON.parse(rawConfig);

if (!config.host || !config.password) {
  console.error('rokudeploy.json must include "host" and "password".');
  process.exit(1);
}

const deployOptions = {
  ...config,
  rootDir,
  outDir,
  outFile,
  stagingDir: packageStagingDir
};

await rokuDeploy.prepublishToStaging({
  rootDir: stagingDir,
  stagingDir: packageStagingDir,
  files: ['**/*', '!**/*.map']
});
await rokuDeploy.zipPackage(deployOptions);
await rokuDeploy.publish(deployOptions);

console.log(`Deployed ${outFile} to Roku device at ${config.host}`);
