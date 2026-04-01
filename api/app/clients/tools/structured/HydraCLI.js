const fs = require('fs');
const path = require('path');
const { execFile } = require('child_process');

const DEFAULT_HYDRA_DIR = '/app/hydra';
const LOCAL_HYDRA_DIR = path.resolve(__dirname, '../../../../hydra');

function resolveHydraDir() {
  const configuredDir = process.env.HYDRA_CLI_DIR;
  if (configuredDir && fs.existsSync(configuredDir)) {
    return configuredDir;
  }
  if (fs.existsSync(DEFAULT_HYDRA_DIR)) {
    return DEFAULT_HYDRA_DIR;
  }
  if (fs.existsSync(LOCAL_HYDRA_DIR)) {
    return LOCAL_HYDRA_DIR;
  }
  return DEFAULT_HYDRA_DIR;
}

function runHydraCLI(scriptName, args = []) {
  return new Promise((resolve, reject) => {
    const hydraDir = resolveHydraDir();
    const scriptPath = path.join(hydraDir, scriptName);
    const commandArgs = [scriptPath, ...args];

    execFile('python3', commandArgs, { timeout: 120000 }, (error, stdout, stderr) => {
      if (error) {
        return reject(
          new Error(
            `HYDRA CLI failed (${scriptName}): ${stderr?.trim() || error.message || 'Unknown error'}`,
          ),
        );
      }
      const output = (stdout || '').trim();
      if (!output) {
        return reject(new Error(`HYDRA CLI returned empty output (${scriptName})`));
      }
      return resolve(output);
    });
  });
}

module.exports = {
  runHydraCLI,
};
