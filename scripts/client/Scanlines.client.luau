local Scanline: UIImage = script.Parent

while true do
	Scanline.TextureOffset = Vector2.New(Scanline.TextureOffset.X, Scanline.TextureOffset.Y - 0.005)
	if Scanline.TextureOffset.Y <= -1 then
		Scanline.TextureOffset = Vector2.New(Scanline.TextureOffset.X, 0)
	end
	wait(1/60)
end