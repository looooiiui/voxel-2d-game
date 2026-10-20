extends RefCounted

## 各种 UI 工具
class_name UiUtil

## 更换Panel的ThemeOverride背景贴图
static func set_panel_texture(target_panel: Panel, tex: Texture2D):
	# 读取当前panel的stylebox，复制一份（防止全局资源污染）
	var style_box = target_panel.get_theme_stylebox("panel").duplicate() as StyleBoxTexture
	if style_box == null:
		# 如果原本不是StyleBoxTexture，新建一个
		style_box = StyleBoxTexture.new()
	
	# 设置贴图
	style_box.texture = tex
	# 可选：九宫格切片，做边框
	style_box.texture_margin_left = 4
	style_box.texture_margin_right = 4
	style_box.texture_margin_top = 4
	style_box.texture_margin_bottom = 4

	# 覆盖ThemeOverride，只作用这个Panel实例
	target_panel.add_theme_stylebox_override("panel", style_box)
