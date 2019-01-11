const fs = require('fs')
const path = require('path')
const { promisify } = require('util')

const chunk = require('lodash.chunk')

const readFile = promisify(fs.readFile)

const extractTimestamp = line => Number(line.match(/\d+$/)[0])

const avg = list => list.reduce((value, item) => value += item, 0) / list.length

async function main () {
  const lines = (await readFile(path.resolve(__dirname, '../benchmark.log'))).toString().split('\n')

  lines.pop()

  const times = chunk(lines, 2).map(([start, end]) => {
    return extractTimestamp(end) - extractTimestamp(start)
  });

  console.log(`samples:\t${times.length}`);
  console.log(`avg:\t\t${avg(times)}\tms`);
  console.log(`best:\t\t${Math.min(...times)}\tms`);
  console.log(`worst:\t\t${Math.max(...times)}\tms`);
}

main()
