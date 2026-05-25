shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_nearest;

uniform bool use_dithering = true;
uniform float dithering_intensity: hint_range(0.0, 1.0) = 0.72;
uniform bool use_scanlines = true;
uniform float scanlines_opacity: hint_range(0.0, 1.0) = 0.0;
uniform bool use_chromatic_aberration = true;
uniform float aberration_amount: hint_range(0.0, 1.0) = 0.03;
uniform bool use_vhs_noise = true;
uniform float noise_intensity: hint_range(0.0, 1.0) = 0.0;
uniform bool use_color_quantization = true;
uniform float color_levels: hint_range(0.0, 1.0) = 0.21;
uniform bool use_pixelate = true;
uniform float pixel_size: hint_range(0.0, 1.0) = 0.21;
uniform bool use_crt = false;
uniform float crt_amount: hint_range(0.0, 1.0) = 0.0;

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = SCREEN_UV;

    if (use_crt) {
        vec2 centered = uv * 2.0 - 1.0;
        centered *= 1.0 + dot(centered.yx, centered.yx) * crt_amount * 0.3;
        uv = (centered + 1.0) / 2.0;
    }

    if (use_pixelate) {
        float scale = mix(2.0, 8.0, pixel_size);
        vec2 pixelated_uv = floor(uv / (SCREEN_PIXEL_SIZE * scale)) * (SCREEN_PIXEL_SIZE * scale);
        uv = pixelated_uv;
    }

    vec4 col = texture(SCREEN_TEXTURE, uv);

    if (use_chromatic_aberration) {
        float amount = aberration_amount * 0.05;
        col.r = texture(SCREEN_TEXTURE, uv + vec2(amount, 0.0)).r;
        col.b = texture(SCREEN_TEXTURE, uv - vec2(amount, 0.0)).b;
    }

    if (use_color_quantization) {
        float levels = mix(2.0, 32.0, color_levels);
        col.rgb = floor(col.rgb * levels) / levels;
    }

    if (use_dithering) {
        float dither = random(uv + vec2(TIME * 0.01)) * dithering_intensity * 0.1;
        col.rgb += dither;
    }

    if (use_scanlines) {
        float scan = sin(uv.y * 240.0 * 3.14159265) * 0.5 + 0.5;
        col.rgb -= scan * scanlines_opacity * 0.2;
    }

    if (use_vhs_noise) {
        float noise = random(vec2(uv.y + TIME, 0.0)) * noise_intensity * 0.1;
        col.rgb += noise;
    }

    if (use_crt) {
        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
            col = vec4(0.0, 0.0, 0.0, 1.0);
        }
    }

    COLOR = col;
}
