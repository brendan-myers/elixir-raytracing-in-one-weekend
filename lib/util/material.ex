defmodule Material do

  require Colour
  require Ray
  require Utilities
  require Vector

  def default() do
    default(Vector.vec3(0, 0, 0))
  end
  def default(attenuation) do
    %{
      attenuation: attenuation,
      scatter: fn(_ray, rec) ->
        scatter_d = rec.normal |> Vector.add(Vector.random_unit_vector())
        scatter_direction = if Vector.near_zero(scatter_d), do: rec.normal, else: scatter_d
        {true, Ray.ray(rec.p, scatter_direction)}
      end
    }
  end

  def metal() do
    metal(Vector.vec3(0, 0, 0), 0)
  end
  def metal(attenuation) do
    metal(attenuation, 0)
  end
  def metal(attenuation, fuzz) do
    %{
      attenuation: attenuation,
      fuzz: fuzz,
      scatter: fn(ray, rec) ->
        reflected = ray.direction
        |> Vector.unit_vector()
        |> Vector.reflect(rec.normal)

        scattered = Ray.ray(rec.p, reflected
          |> Vector.add(
            Vector.random_in_unit_sphere() |> Vector.mul(Utilities.clamp(fuzz, 0, 1) )
          ))
        scatter = scattered.direction |> Vector.dot(rec.normal)
        {scatter > 0, scattered}
      end
    }
  end

  def dielectric(index_of_refraction) do
    %{
      attenuation: Colour.colour(1, 1, 1),
      scatter: fn(ray, rec) ->
        refraction_ratio = if rec.front_face do
          1.0 / index_of_refraction
        else
          index_of_refraction
        end

        unit_direction = ray.direction |> Vector.unit_vector()

        cos_theta = unit_direction
        |> Vector.mul(-1)
        |> Vector.dot(rec.normal)
        |> min(1)

        sin_theta = :math.sqrt(1 - cos_theta*cos_theta)

        cannot_refract = refraction_ratio * sin_theta > 1

        direction = if cannot_refract || Utilities.reflectance(cos_theta, refraction_ratio) > :rand.uniform() do
          Vector.reflect(unit_direction, rec.normal)
        else
          Vector.refract(unit_direction, rec.normal, refraction_ratio)
        end

        {true, Ray.ray(rec.p, direction)}
      end
    }
  end
end
