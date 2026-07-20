class_name WoodUI
extends RefCounted

const PANEL_TEXTURE := preload("res://assets/ui/level_up/panel_background_wood.webp")
const CARD_TEXTURE := preload("res://assets/ui/level_up/offer_background_wood.webp")
const BUTTON_TEXTURE := preload("res://assets/ui/level_up/button_background_wood.webp")

const TEXT_PRIMARY := Color(0.94, 0.88, 0.75, 1.0)
const TEXT_MUTED := Color(0.72, 0.66, 0.56, 1.0)
const TEXT_GOLD := Color(1.0, 0.78, 0.32, 1.0)

static func panel_style(tint: Color = Color.WHITE) -> StyleBoxTexture:
	return _texture_style(PANEL_TEXTURE, 24.0, 28.0, tint)

static func card_style(tint: Color = Color.WHITE) -> StyleBoxTexture:
	return _texture_style(CARD_TEXTURE, 24.0, 20.0, tint)

static func button_style(tint: Color = Color(0.82, 0.72, 0.58, 1.0)) -> StyleBoxTexture:
	return _texture_style(BUTTON_TEXTURE, 24.0, 16.0, tint)

static func _texture_style(texture: Texture2D, border: float, content: float, tint: Color) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = border
	style.texture_margin_top = border
	style.texture_margin_right = border
	style.texture_margin_bottom = border
	style.content_margin_left = content
	style.content_margin_top = content
	style.content_margin_right = content
	style.content_margin_bottom = content
	style.modulate_color = tint
	return style

static func style_title(label: Label) -> void:
	label.add_theme_color_override("font_color", TEXT_GOLD)
	label.add_theme_color_override("font_shadow_color", Color(0.06, 0.02, 0.0, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color(0.12, 0.045, 0.01, 0.95))
