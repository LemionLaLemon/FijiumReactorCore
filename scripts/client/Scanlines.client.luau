local Scanline: UIImage = script.Parent

function _Update()
	Scanline.TextureOffset = Vector2.New(Scanline.TextureOffset.X, Scanline.TextureOffset.Y - 0.005)
end