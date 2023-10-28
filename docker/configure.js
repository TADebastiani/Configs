#! /usr/bin/env node

const fs = require('fs');

const daemonPath = process.argv[2];
const dockerPoint = process.argv[3];
const rawDaemonData = fs.readFileSync(daemonPath, {encoding: 'utf8'});

let daemonData = rawDaemonData ? JSON.parse(rawDaemonData) : {};
daemonData['data-root'] = dockerPoint;

fs.writeFileSync(daemonPath, JSON.stringify(daemonData, null, 4), {encoding: 'utf8'});
