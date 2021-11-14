defmodule Utilities do
  def degrees_to_radians(degrees) do
    degrees * :math.pi / 180.0
  end

  def random(min, max) do
    min + (max-min) * :rand.uniform
  end

  def clamp(x, min, max) do
    case x do
      x when x < min ->
        min
      x when x > max ->
        max
      _ ->
        x
    end
  end

  def reflectance(cosine, ref_idx) do
    r0 = (1 - ref_idx) / (1 + ref_idx)
    r0_sq = r0*r0
    r0_sq + (1 - r0_sq) * :math.pow(1 - cosine, 5)
  end
end
