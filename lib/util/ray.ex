defmodule Ray do

  require Vector

  def ray(origin, direction) do
    %{
      origin: origin,
      direction: direction
    }
  end

  def ray_at(ray, t) do
    Vector.mul(ray.direction, t)
    |> Vector.add(ray.origin)
  end
end
