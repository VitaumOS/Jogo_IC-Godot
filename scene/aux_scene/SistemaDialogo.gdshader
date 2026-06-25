shader_type canvas_item;

// Parâmetros que controlaremos via GDScript
uniform vec2 posicao_foco; // Centro do buraco (em pixels da tela)
uniform vec2 tamanho_foco;  // Largura e Altura do buraco (em pixels)
uniform vec4 cor_shadow : source_color = vec4(0.0, 0.0, 0.0, 0.6); // Preto com 60% opacidade

void fragment() {
	// Converte a posição do pixel atual para coordenadas globais de tela
	vec2 pixel_global = SCREEN_UV / SCREEN_PIXEL_SIZE;
	
	// Calcula as bordas do retângulo de foco
	float limite_esquerdo = posicao_foco.x - (tamanho_foco.x / 2.0);
	float limite_direito = posicao_foco.x + (tamanho_foco.x / 2.0);
	float limite_superior = posicao_foco.y - (tamanho_foco.y / 2.0);
	float limite_inferior = posicao_foco.y + (tamanho_foco.y / 2.0);
	
	// Verifica se o pixel atual está DENTRO do retângulo de foco
	if (pixel_global.x >= limite_esquerdo && pixel_global.x <= limite_direito &&
		pixel_global.y >= limite_superior && pixel_global.y <= limite_inferior) {
		// Se estiver dentro, o pixel fica 100% transparente
		COLOR = vec4(0.0);
	} else {
		// Se estiver fora, aplica a cor escura semitransparente
		COLOR = cor_shadow;
	}
}