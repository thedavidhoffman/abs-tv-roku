import fs from 'node:fs/promises';
import path from 'node:path';
import rokuDeploy from 'roku-deploy';

const rootDir = process.cwd();
const outDir = path.join(rootDir, 'out');
const stagingDir = path.join(rootDir, 'build', 'staging');
const outFile = 'ABSTV';

const files = [
  'components/**/*',
  'images/**/*',
  'source/**/*',
  'manifest'
];

await fs.mkdir(outDir, { recursive: true });

await rokuDeploy.prepublishToStaging({
  rootDir,
  stagingDir,
  files
});

await rokuDeploy.zipPackage({
  stagingDir,
  outDir,
  outFile
});

console.log(`Created package: ${path.join(outDir, `${outFile}.zip`)}`);
