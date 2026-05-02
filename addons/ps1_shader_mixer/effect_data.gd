@tool
extends Resource

const EFFECTS = [
	{"label": "Dithering", "bool": "use_dithering", "float": "dithering_intensity", "default": 0.5},
	{"label": "Scanlines", "bool": "use_scanlines", "float": "scanlines_opacity", "default": 0.3},
	{"label": "Aberración", "bool": "use_chromatic_aberration", "float": "aberration_amount", "default": 0.003},
	{"label": "VHS Noise", "bool": "use_vhs_noise", "float": "noise_intensity", "default": 0.2},
	{"label": "Color PS1", "bool": "use_color_quantization", "float": "color_levels", "default": 0.5},
	{"label": "Pixelado", "bool": "use_pixelate", "float": "pixel_size", "default": 0.3},
	{"label": "CRT Curvatura", "bool": "use_crt", "float": "crt_amount", "default": 0.3},
]
