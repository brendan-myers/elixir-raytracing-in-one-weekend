defmodule RayColour do

  require Colour
  require Vector

  def ray_colour(_ray, _objects, 0) do
    Colour.colour(0, 0, 0)
  end
  def ray_colour(ray, objects, depth) do
    case HitRecord.hittable_list_hit(objects, ray) do
      {:hit, rec} ->
        {scatter, v} = rec.material.scatter.(ray, rec)
        if scatter do
          ray_colour(v, objects, depth-1)
          |> Vector.element_mul(rec.material.attenuation)
        else
          Colour.colour(0, 0, 0)
        end
      {:miss} ->
        unit_direction = Vector.unit_vector(ray.direction)
        t = 0.5 * (unit_direction.y + 1)

        colour_1 = Colour.colour(1.0, 1.0, 1.0)
        colour_2 = Colour.colour(0.5, 0.7, 1.0)

        colour_1
        |> Vector.mul((1-t))
        |> Vector.add(
          colour_2
          |> Vector.mul(t))
    end
  end
end
