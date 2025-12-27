const assert = require('assert');
const jsonToAlphaText = require('../../docs/jsonToAlphaText');

function testBeatLevelProps() {
  const score = {
    measures: [
      {
        signature: [4, 4],
        voices: [
          {
            beats: [
              {
                duration: [1, 4],
                palmMute: true,
                letRing: true,
                notes: [{ string: 0, fret: 3 }],
              },
            ],
          },
        ],
      },
    ],
  };

  const output = jsonToAlphaText(score);
  assert(!output.includes('{pm}'), output);
  assert(!output.includes('3.1{'), output);
}

function testTieUsesRepeatedFret() {
  const score = {
    measures: [
      {
        signature: [4, 4],
        voices: [
          {
            beats: [
              { duration: [1, 4], notes: [{ string: 0, fret: 3 }] },
              { duration: [1, 4], notes: [{ string: 0, fret: 3 }] },
              { duration: [1, 4], notes: [{ string: 0, fret: 3 }] },
              { duration: [1, 4], notes: [{ string: 0, fret: 3 }] },
            ],
          },
        ],
      },
      {
        voices: [
          {
            beats: [
              { duration: [1, 4], notes: [{ string: 0, fret: 3, tie: true }] },
            ],
          },
        ],
      },
    ],
  };

  const output = jsonToAlphaText(score);
  assert(!output.includes('{t}'), output);
  assert(!output.includes('-.1'), output);
}

function testNotePropsOmitted() {
  const score = {
    measures: [
      {
        signature: [4, 4],
        voices: [
          {
            beats: [
              { duration: [1, 4], notes: [{ string: 0, fret: 3, ghost: true, hp: true }] },
              { duration: [1, 4], notes: [{ string: 0, fret: 3, ghost: true }] },
              { duration: [1, 4], notes: [{ string: 0, fret: 3, hp: true }] },
              { duration: [1, 4], notes: [{ string: 0, fret: 3 }] },
            ],
          },
        ],
      },
    ],
  };

  const output = jsonToAlphaText(score);
  assert(!output.includes('{g}'), output);
  assert(!output.includes('{h}'), output);
}

testBeatLevelProps();
testTieUsesRepeatedFret();
testNotePropsOmitted();

console.log('alphatex beat-level props tests: ok');
