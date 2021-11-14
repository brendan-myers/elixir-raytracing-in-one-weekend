defmodule Colour do

  require Vector

  def colour(r, g, b) do
    Vector.vec3(r, g, b)
  end

  def colour(v) do
    %{
      r: v.x,
      g: v.y,
      b: v.z
    }
  end
end
