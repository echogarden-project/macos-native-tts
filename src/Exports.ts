import { createRequire } from 'node:module'

const log = console.log

export function getVoiceList() {
	const addon = getAddonForCurrentPlatform();

	return addon.getVoiceList();
}

export function synthesize(text: string, options: MacosNativeTTSOptions) {
	const addon = getAddonForCurrentPlatform()

	options = { ...defaultMacosNativeTTSOptions, ...options }

	log(options)

	const result: MacosNativeTTSSynthesizeResult = addon.synthesize(text, options)

	return result
}

export function isAddonAvailable() {
	try {
		const addon = getAddonForCurrentPlatform()

		if (!addon) {
			log(`Addon failed to load`)

			return false
		}

		const result = addon.isAddonLoaded()

		return result === true
	} catch (e) {
		log(e)

		return false
	}
}

function getAddonForCurrentPlatform() {
	const platform = process.platform
	const arch = process.arch

	const require = createRequire(import.meta.url)

	let addonModule: any

	if (platform === 'darwin' && arch === 'x64') {
		addonModule = require('../addons/bin/macos-x64-tts.node')
	} else if (platform === 'darwin' && arch === 'arm64') {
		addonModule = require('../addons/bin/macos-arm64-tts.node')
	} else {
		throw new Error(`macos-native-tts initialization error: platform ${platform}, ${arch} is not supported`)
	}

	return addonModule
}

export interface MacosNativeTTSSynthesizeResult {
	audioSamples: Int16Array
	sampleRate: number
}

export interface MacosNativeTTSOptions {
	voice?: string
	rate?: number
	pitchMultiplier?: number
	volume?: number
	enableTrace?: boolean
}

export const defaultMacosNativeTTSOptions: MacosNativeTTSOptions = {
	voice: 'en-US',
	rate: 0.5,
	pitchMultiplier: 1.0,
	volume: 1.0,
	enableTrace: false,
}
