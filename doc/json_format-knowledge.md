1) Minimal JSON example covering every feature

{
  "tuning": [64, 59, 55, 50, 45, 40],
  "measures": [
    {
      "signature": [4, 4],
      "marker": { "text": "Demo: tuplets, PM, let ring, tie" },
      "voices": [
        {
          "beats": [
            {
              "duration": [1, 8],
              "palmMute": true,
              "notes": [{ "string": 5, "fret": 0 }]
            },

            {
              "duration": [1, 12],
              "type": 16,
              "tuplet": 3,
              "tupletStart": true,
              "letRing": true,
              "notes": [{ "string": 4, "fret": 3 }]
            },
            {
              "duration": [1, 12],
              "type": 16,
              "tuplet": 3,
              "letRing": true,
              "notes": [{ "string": 4, "fret": 3, "tie": true }]
            },
            {
              "duration": [1, 12],
              "type": 16,
              "tuplet": 3,
              "tupletStop": true,
              "letRing": true,
              "notes": [{ "string": 4, "fret": 3, "tie": true }]
            },

            {
              "duration": [1, 8],
              "rest": true,
              "notes": [{ "rest": true }]
            },

            {
              "duration": [1, 4],
              "notes": [
                { "string": 3, "fret": 2, "ghost": true },
                { "string": 2, "fret": 2 },
                { "string": 1, "fret": 2 },
                { "string": 0, "fret": 2 }
              ]
            },

            {
              "duration": [1, 4],
              "notes": [{ "string": 5, "dead": true }]
            }
          ]
        }
      ]
    },

    {
      "voices": [
        {
          "beats": [
            { "duration": [1, 4], "notes": [{ "string": 5, "fret": 0 }] },
            { "duration": [1, 4], "notes": [{ "string": 5, "fret": 0, "tie": true }] },
            { "duration": [1, 4], "notes": [{ "string": 5, "fret": 0, "tie": true }] },
            { "duration": [1, 4], "notes": [{ "string": 5, "fret": 0, "tie": true }] }
          ]
        }
      ]
    }
  ]
}

What this demonstrates:
	•	tuning (MIDI)
	•	signature + marker
	•	palmMute + letRing rails
	•	triplet tuplet with start/stop
	•	tie-to-previous with sustain ====
	•	rest beat
	•	chord (multiple notes at once)
	•	ghost note (2)
	•	dead note x

⸻

2) JSON Schema (draft, pragmatic)

{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "GuitarTab",
  "type": "object",
  "required": ["measures"],
  "properties": {
    "tuning": {
      "type": "array",
      "description": "6 MIDI note numbers, string 1 -> 6 (high -> low)",
      "items": { "type": "integer" },
      "minItems": 6,
      "maxItems": 6
    },
    "measures": {
      "type": "array",
      "items": { "$ref": "#/$defs/measure" }
    }
  },
  "$defs": {
    "measure": {
      "type": "object",
      "required": ["voices"],
      "properties": {
        "signature": {
          "type": "array",
          "minItems": 2,
          "maxItems": 2,
          "items": { "type": "integer" }
        },
        "marker": {
          "type": "object",
          "properties": {
            "text": { "type": "string" },
            "width": { "type": "number" }
          },
          "additionalProperties": true
        },
        "voices": {
          "type": "array",
          "items": { "$ref": "#/$defs/voice" }
        }
      },
      "additionalProperties": true
    },
    "voice": {
      "type": "object",
      "properties": {
        "rest": { "type": "boolean" },
        "beats": {
          "type": "array",
          "items": { "$ref": "#/$defs/beat" }
        }
      },
      "additionalProperties": true
    },
    "beat": {
      "type": "object",
      "required": ["duration"],
      "properties": {
        "notes": {
          "type": "array",
          "items": { "$ref": "#/$defs/note" }
        },
        "duration": {
          "type": "array",
          "minItems": 2,
          "maxItems": 2,
          "items": { "type": "integer" }
        },
        "type": { "type": "integer" },
        "dots": { "type": "integer" },
        "rest": { "type": "boolean" },

        "tuplet": { "type": "integer" },
        "tupletStart": { "type": "boolean" },
        "tupletStop": { "type": "boolean" },

        "beamStart": { "type": "boolean" },
        "beamStop": { "type": "boolean" },

        "palmMute": { "type": "boolean" },
        "letRing": { "type": "boolean" }
      },
      "additionalProperties": true
    },
    "note": {
      "type": "object",
      "properties": {
        "string": { "type": "integer", "minimum": 0, "maximum": 5 },
        "fret": { "type": "integer", "minimum": 0 },
        "rest": { "type": "boolean" },

        "tie": {
          "type": "boolean",
          "description": "Tie to PREVIOUS note (render sustain gap with '=')"
        },
        "hp": { "type": "boolean" },
        "slide": { "type": "string" },

        "ghost": { "type": "boolean" },
        "dead": { "type": "boolean" }
      },
      "additionalProperties": true
    }
  }
}


⸻

3) Test corpus ideas (small but effective)

Use these as separate JSON files to validate the renderer:
	1.	Exact signature fill + padding
	•	Provide a 4/4 measure with only 3 beats worth of duration
	•	Expect renderer to pad with rests to complete the measure.
	2.	Repeat compression correctness
	•	Construct 16 measures identical, repeated 4 times
	•	Follow with a 4-measure phrase repeated 4 times
	•	Ensure output becomes |: ... :| x4 for both blocks (no “lonely first measure”).
	3.	Tuplets + PM + letRing + ties interaction
	•	A tuplet group where:
	•	beats have palmMute: true
	•	notes have tie: true to previous
	•	letRing: true overlaps later beats
	•	Validate:
	•	tuplet rail aligns with the correct span
	•	PM rail and let ring text appear at first spans
	•	sustain = paints only between tied notes and doesn’t overwrite note tokens.