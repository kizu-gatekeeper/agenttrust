const fs = require('fs');
const path = require('path');
const solc = require('solc');

const sourcePath = path.join(__dirname, 'contracts', 'AgentTrust.sol');
const source = fs.readFileSync(sourcePath, 'utf8');

const input = {
  language: 'Solidity',
  sources: { 'AgentTrust.sol': { content: source } },
  settings: {
    optimizer: { enabled: true, runs: 200 },
    outputSelection: { '*': { '*': ['abi', 'evm.bytecode.object', 'evm.deployedBytecode.object', 'evm.gasEstimates'] } }
  }
};

const output = JSON.parse(solc.compile(JSON.stringify(input)));

if (output.errors) {
  for (const e of output.errors) {
    console.log(e.severity.toUpperCase() + ': ' + e.formattedMessage);
  }
  if (output.errors.some(e => e.severity === 'error')) process.exit(1);
}

const c = output.contracts['AgentTrust.sol']['AgentTrust'];
const bytecode = c.evm.bytecode.object;
const deployed = c.evm.deployedBytecode.object;
const result = {
  contractName: 'AgentTrust',
  compilerVersion: solc.version(),
  optimizer: { enabled: true, runs: 200 },
  abi: c.abi,
  bytecode: '0x' + bytecode,
  deployedBytecode: '0x' + deployed,
  bytecodeSizeBytes: bytecode.length / 2,
  deployedBytecodeSizeBytes: deployed.length / 2,
  gasEstimates: c.evm.gasEstimates || null
};
fs.mkdirSync(path.join(__dirname, 'build'), { recursive: true });
fs.writeFileSync(path.join(__dirname, 'build', 'AgentTrust.json'), JSON.stringify(result, null, 2));
fs.writeFileSync(path.join(__dirname, 'build', 'AgentTrust.abi.json'), JSON.stringify(c.abi, null, 2));
console.log('Compiler:', solc.version());
console.log('Creation bytecode size (bytes):', bytecode.length / 2);
console.log('Deployed bytecode size (bytes):', deployed.length / 2);
console.log('Gas estimates:', JSON.stringify(c.evm.gasEstimates));
