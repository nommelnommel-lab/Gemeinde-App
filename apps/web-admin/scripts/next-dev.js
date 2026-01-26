const { spawn } = require('node:child_process');

const args = process.argv.slice(2);
let port;

if (args[0] === '-p' && args[1]) {
  port = args[1];
} else if (args[0] && /^\d+$/.test(args[0])) {
  port = args[0];
}

const nextArgs = ['dev'];
if (port) {
  nextArgs.push('-p', port);
}

const child = spawn('next', nextArgs, {
  stdio: 'inherit',
  shell: true,
});

child.on('exit', (code) => {
  process.exit(code ?? 0);
});
