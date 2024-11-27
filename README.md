# Node.js binding to the macOS native speech synthesizer

Uses N-API to bind to the native macOS [`AVSpeechSynthesizer`](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer/) API.

* Speech is returned as a `Int16Array` raw PCM, `22050` Hz mono
* Will recognize voices installed via the macOS OS
* Addon binaries are pre-bundled. Doesn't require any install-time postprocessing
* Supports macOS `10.14` and later, x64 and arm64

## Installation

`npm install @echogarden/macos-native-tts`

## Usage examples

### Synthesize text

```ts
import { synthesize } from '@echogarden/macos-native-tts'

const text = `
Hello World! How are you doing today?
`

const { audioSamples, sampleRate } = synthesize(text, {
	voice: 'en-US',
	rate: 0.5,
	pitchMultiplier: 1.0,
	volume: 1.0,
})
```

The returned `audioSamples` is an `Int16Array` containing mono samples at a sample rate of `sampleRate` (usually `22050` or `11025` Hz).

### List voices:
```ts
import { getVoiceList } from '@echogarden/macos-native-tts'

const voices = getVoiceList()

console.log(voices)
```
Prints:

```ts
[
  {
    identifier: 'com.apple.voice.compact.ar-001.Maged',
    name: 'Majed',
    quality: 1,
    gender: 'male',
    language: 'ar-001'
  },
  {
    identifier: 'com.apple.voice.compact.bg-BG.Daria',
    name: 'Daria',
    quality: 1,
    gender: 'female',
    language: 'bg-BG'
  },
  {
    identifier: 'com.apple.voice.compact.ca-ES.Montserrat',
    name: 'Montse',
    quality: 1,
    gender: 'female',
    language: 'ca-ES'
  },

  //...
]
```

## Building the N-API addons

The library is bundled with pre-built addons, so recompilation shouldn't be needed.

If you still want to compile yourself, for a modification or a fork:

* In the `addons` directory, run `npm install`, which would install the necessary build tools.
* Then run `npm run build-x64` (x64) or `npm run build-arm64` (arm64)

## License

MIT
