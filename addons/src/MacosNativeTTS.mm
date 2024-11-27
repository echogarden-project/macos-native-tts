#import <vector>
#import <string>
#import <iostream>

#import <AVFoundation/AVFoundation.h>

#include <napi.h>
/////////////////////////////////////////////////////////////////////////////////////
// Utilities
/////////////////////////////////////////////////////////////////////////////////////
Napi::String nsStringToNapiString(Napi::Env env, NSString* nsStr) {
	return Napi::String::New(env, [nsStr UTF8String]);
}

bool areNSStringsEqual(NSString* nsStr1, NSString* nsStr2) {
	return [nsStr1 isEqualToString:nsStr2];
}

std::string genderToString(AVSpeechSynthesisVoiceGender gender) {
	if (gender == 0) {
		return "unknown";
	} else if (gender == 1) {
		return "male";
	} else {
		return "female";
	}
}

/////////////////////////////////////////////////////////////////////////////////////
// Synthesis methods
/////////////////////////////////////////////////////////////////////////////////////
AVSpeechSynthesisVoice* getVoice(NSString* nsIdentifier) {
	auto voices = [AVSpeechSynthesisVoice speechVoices];

	for (AVSpeechSynthesisVoice* voice in voices) {
		if (areNSStringsEqual(nsIdentifier, voice.identifier))
			return voice;
	}

	return nullptr;
}

Napi::Object synthesize(const Napi::CallbackInfo &info) {
	auto env = info.Env();

	try {
		// Parse input arguments
		auto text = info[0].As<Napi::String>().Utf8Value();

		auto options = info[1].As<Napi::Object>();

	   	auto voice = options.Get("voice").As<Napi::String>().Utf8Value();
		auto rate = options.Get("rate").As<Napi::Number>().DoubleValue();
		auto pitchMultiplier = options.Get("pitchMultiplier").As<Napi::Number>().DoubleValue();
		auto volume = options.Get("volume").As<Napi::Number>().DoubleValue();
		auto enableTrace = options.Get("enableTrace").As<Napi::Boolean>().Value();

		if (enableTrace) {
			std::cout << "Minimum speech rate: " << AVSpeechUtteranceMinimumSpeechRate << "\n";
			std::cout << "Maximum speech rate: " << AVSpeechUtteranceMaximumSpeechRate << "\n";
			std::cout << "Maximum speech rate: " << AVSpeechUtteranceDefaultSpeechRate << "\n";
		}

		// Set speech properties
		auto nsVoice = [NSString stringWithUTF8String:voice.c_str()];
		auto nsText = [NSString stringWithUTF8String:text.c_str()];

		auto utterance = [[AVSpeechUtterance alloc] initWithString:nsText];

		// Try to match voice
		utterance.voice = [AVSpeechSynthesisVoice voiceWithIdentifier:nsVoice];

		if (utterance.voice) {
			if (enableTrace) {
				std::cout << "Exact voice matched\n";
			}
		} else {
			if (enableTrace) {
				std::cout << "Exact voice didn't match\n";
			}

			utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:nsVoice];

			if (enableTrace) {
				if (utterance.voice) {
					std::cout << "Language matched\n";
				} else {
					std::cout << "Language didn't match\n";
				}
			}
		}

		if (false) {
			auto voiceObject = getVoice(nsVoice);

			if (voiceObject) {
				utterance.voice = voiceObject;

				if (enableTrace) {
					std::cout << "voice matched\n";
				}
			}
		}

		// Set parameters
		utterance.rate = rate;
		utterance.pitchMultiplier = pitchMultiplier;
		utterance.volume = volume;

		// Create the buffer to store the synthesized speech data
		auto audioBuffer = [[NSMutableData alloc] init];

		auto semaphore = dispatch_semaphore_create(0);

		if (enableTrace) {
			std::cout << "\n";
		}

		__block double sampleRate = 0.0;

		// Define the buffer callback
		AVSpeechSynthesizerBufferCallback bufferCallback = ^(AVAudioBuffer* buffer) {
			auto firstChannelBuffer = buffer.audioBufferList->mBuffers[0];

			if (enableTrace) {
				std::cout << "Received new buffer" << "\n";
				std::cout << "Common format: " << buffer.format.commonFormat  << "\n";
				std::cout << "Sample rate: " << buffer.format.sampleRate << "\n";
				std::cout << "Buffer count: " << buffer.audioBufferList->mNumberBuffers << "\n";
				std::cout << "Sample count: " << firstChannelBuffer.mDataByteSize << "\n";
				std::cout << "\n";
			}

			if (sampleRate == 0) {
				sampleRate = buffer.format.sampleRate;
			}

			if (firstChannelBuffer.mDataByteSize > 0) {
				auto nsAudioData = [NSData dataWithBytes:firstChannelBuffer.mData length:firstChannelBuffer.mDataByteSize];
				[audioBuffer appendData:nsAudioData];
			} else {
				dispatch_semaphore_signal(semaphore);
			}
		};

		// Create the synthesizer and write the utterance to the buffer
		auto synthesizer = [[AVSpeechSynthesizer alloc] init];
		[synthesizer writeUtterance:utterance toBufferCallback:bufferCallback];

		while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW) != 0) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
		}

        // Release objects
        [utterance release];
        [audioBuffer release];
        [synthesizer release];
        dispatch_release(semaphore);

		// Create Napi results
		auto result = Napi::Object::New(env);

		auto audioSamples = Napi::Int16Array::New(env, audioBuffer.length / 2);
		std::memcpy(audioSamples.Data(), audioBuffer.mutableBytes, audioBuffer.length);

		result.Set("audioSamples", audioSamples);
		result.Set("sampleRate", sampleRate);

		return result;
	} catch (const std::exception &e) {
		throw Napi::Error::New(env, e.what());
	}
}

Napi::Array getVoiceList(const Napi::CallbackInfo &info) {
	auto env = info.Env();

	auto voices = [AVSpeechSynthesisVoice speechVoices];

	auto result = Napi::Array::New(env);

	auto index = 0;

	for (AVSpeechSynthesisVoice* voice in voices) {
		auto napiVoiceObject = Napi::Object::New(env);

		napiVoiceObject.Set("identifier", nsStringToNapiString(env, voice.identifier));
		napiVoiceObject.Set("name", nsStringToNapiString(env, voice.name));
		napiVoiceObject.Set("quality", static_cast<int>(voice.quality));
		napiVoiceObject.Set("gender", genderToString(voice.gender));
		napiVoiceObject.Set("language", nsStringToNapiString(env, voice.language));

		result.Set(index, napiVoiceObject);

		index += 1;
	}

	return result;
}

Napi::Boolean isAddonLoaded(const Napi::CallbackInfo &info) {
	return Napi::Boolean::New(info.Env(), true);
}

Napi::Object Init(Napi::Env env, Napi::Object exports) {
	exports.Set("isAddonLoaded", Napi::Function::New(env, isAddonLoaded));
	exports.Set("getVoiceList", Napi::Function::New(env, getVoiceList));
	exports.Set("synthesize", Napi::Function::New(env, synthesize));

	return exports;
}

NODE_API_MODULE(addon, Init)
