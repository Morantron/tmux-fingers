const huffman = require('n-ary-huffman')
const range = require('lodash.range')
const uniq = require('lodash.uniq')
const path = require('path')
const fs = require('fs')
const MAX_MATCHES = 200
const CACHE_ROOT = path.resolve(__dirname, './cache')
const { promisify } = require('util')
const exec = promisify(require('child_process').exec)

const alphabetsDefinition = require('./alphabets.json')

const ALPHABETS_DIR = path.resolve(__dirname, '../alphabets/')

const items = range(1, MAX_MATCHES).map((i) => ({
  name: '',
  weight: i,
  codeWord: null
}))

const ensureDir = async dir => await exec(`mkdir -p ${dir}`)

const spit = ({path, hints}) => {
  fs.writeFile(path, hints.join(' '), (err) => {
    if (err) {
      console.log('err', err);
    }
  })
}

const byLength = (a, b) => Math.sign(a.length - b.length)

const DISALLOWED_CHARACTERS = /[cimq]/

async function main() {
  Object.keys(alphabetsDefinition).forEach(async alphabetName => {
    const alphabet = alphabetsDefinition[alphabetName].split('').filter(char => !char.match(DISALLOWED_CHARACTERS))

    if (alphabet.length !== uniq(alphabet).length) {
      console.error(`ERROR: ${alphabetName} contains duplicate characters`);
      process.exit(1)
    }

    const alphabetDir = path.resolve(ALPHABETS_DIR, alphabetName)

    await ensureDir(alphabetDir)

    range(1, MAX_MATCHES + 1).map(matches => {
      const outputPath = path.resolve(
        alphabetDir,
        String(matches)
      )

      let hints

      if (matches <= alphabet.length) {
        hints = alphabet.slice(0, matches)
      } else {
        const tree = huffman.createTree(items.slice(0, matches), alphabet.length)
        hints = []

        tree.assignCodeWords(alphabet, (item, codeWord) => {
          hints.push(codeWord)
        })

        hints.sort(byLength)
      }

      spit({
        path: outputPath,
        hints: hints.reverse()
      })
    })
  })
}

main()
