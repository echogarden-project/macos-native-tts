{
    "targets": [
        {
            "conditions": [
                [
                    "OS=='mac'",
                    {
                        "sources": ["src/MacosNativeTTS.mm"],
                        "include_dirs": [
                            "<!@(node -p \"require('node-addon-api').include\")"
                        ],
                        "defines": ["NAPI_CPP_EXCEPTIONS"],
                        "cflags!": ["-fno-exceptions"],
                        "cflags_cc!": ["-fno-exceptions"],
						"xcode_settings": {
							"OTHER_CPLUSPLUSFLAGS": ["-x", "objective-c++"],
							"GCC_ENABLE_CPP_EXCEPTIONS": "YES",
						},
						"libraries": [
							"-framework AVFoundation",
						],
						"conditions": [
							[
								"target_arch=='x64'",
								{
									"target_name": "macos-x64-tts",
								},
							],
							[
								"target_arch=='arm64'",
								{
									"target_name": "macos-arm64-tts",
								},
							],
						],						
                    },
                ]
            ],
        }
    ]
}
