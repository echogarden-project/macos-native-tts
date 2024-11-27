import { writeFile } from 'node:fs/promises'
import { getVoiceList, isAddonAvailable, synthesize } from './Exports.js'
import { playAudioSamples } from '@echogarden/audio-io'

const log = console.log

const available = isAddonAvailable()
//console.log(available)

if (!available) {
	log(`Addon is not available!`)
	process.exit(1)
}

log(getVoiceList());

const selectedVoice = process.argv[2] || ''

log(`Selected voice: ${selectedVoice}`)

const text = `Hello World! How are you doing today?`

const { audioSamples, sampleRate } = synthesize(text, {
	voice: selectedVoice,
	rate: 0.5,
	pitchMultiplier: 1.0,
	enableTrace: true,
})

log(`Synthesized. ${audioSamples.length} samples returned, at ${sampleRate} Hz.`)

log(audioSamples)

await writeFile(`out/out.pcm`, Uint8Array.from(audioSamples))

await playAudioSamples(audioSamples, sampleRate, 1);
