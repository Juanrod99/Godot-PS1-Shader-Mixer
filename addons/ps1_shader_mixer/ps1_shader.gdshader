shader_type canvas_item;

// Uniforms
uniform bool use_dithering = true;
uniform float dithering_intensity: hint_range(0.0, 1.0) = 0.5;

uniform bool use_scanlines = true;
uniform float scanlines_opacity: hint_range(0.0, 1.0) = 0.3;

uniform bool use_chromatic_aberration = false;
uniform float aberration_amount: hint_range(0.0, 1.0) = 0.003;

uniform bool use_vhs_noise = false;
uniform float noise_intensity: hint_range(0.0, 1.0) = 0.2;

uniform bool use_color_quantization = true;
uniform float color_levels: hint_range(0.0, 1.0) = 0.5;

uniform bool use_pixelate = false;
uniform float pixel_size: hint_range(0.0, 1.0) = 0.3;

uniform bool use_crt = false;
uniform float crt_amount: hint_range(0.0, 1.0) = 0.3;

// Helpers
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;

    // Primero calculamos el UV modificado
    if (use_crt) {
        vec2 centered = uv * 2.0 - 1.0;
        centered *= 1.0 + dot(centered.yx, centered.yx) * crt_amount * 0.3;
        uv = (centered + 1.0) / 2.0;
    }

    if (use_pixelate) {
        float pixels = mix(512.0, 32.0, pixel_size);
        uv = floor(uv * pixels) / pixels;
    }

    // Luego leemos el color con el UV final
    vec4 col = texture(TEXTURE, uv);

    // Aberración cromática sobre el UV ya modificado
    if (use_chromatic_aberration) {
        float amount = aberration_amount * 0.05;
        col.r = texture(TEXTURE, uv + vec2(amount, 0.0)).r;
        col.b = texture(TEXTURE, uv - vec2(amount, 0.0)).b;
    }

    // Cuantización de color PS1
    if (use_color_quantization) {
        float levels = mix(2.0, 32.0, color_levels);
        col.rgb = floor(col.rgb * levels) / levels;
    }

    // Dithering
    if (use_dithering) {
        float dither = random(uv + vec2(TIME * 0.01)) * dithering_intensity * 0.1;
        col.rgb += dither;
    }

    // Scanlines
    if (use_scanlines) {
        float scan = sin(uv.y / SCREEN_PIXEL_SIZE.y) * 0.5 + 0.5;
        col.rgb -= scan * scanlines_opacity * 0.2;
    }

    // VHS Noise
    if (use_vhs_noise) {
        float noise = random(vec2(uv.y + TIME, 0.0)) * noise_intensity * 0.1;
        col.rgb += noise;
    }

    // CRT bordes negros
    if (use_crt) {
        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
            col = vec4(0.0, 0.0, 0.0, 1.0);
        }
    }

    COLOR = col;
}