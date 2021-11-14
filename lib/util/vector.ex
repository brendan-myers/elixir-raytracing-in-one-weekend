defmodule Vector do

  require Utilities

  def vec3(x, y, z) do
    %{
      x: x,
      y: y,
      z: z
    }
  end
  def vec3_random() do
    %{
      x: :rand.uniform,
      y: :rand.uniform,
      z: :rand.uniform,
    }
  end
  def vec3_random(min, max) do
    %{
      x: Utilities.random(min, max),
      y: Utilities.random(min, max),
      z: Utilities.random(min, max),
    }
  end
  def add(v1, v2) do
    %{
      x: v1.x + v2.x,
      y: v1.y + v2.y,
      z: v1.z + v2.z
    }
  end
  def sub(v1, v2) do
    %{
      x: v1.x - v2.x,
      y: v1.y - v2.y,
      z: v1.z - v2.z
    }
  end
  def mul(v, t) do
    %{
      x: v.x * t,
      y: v.y * t,
      z: v.z * t
    }
  end
  def divide(v, t) do
    mul(v, 1/t)
  end
  def vec3_length(v) do
    :math.sqrt(length_squared(v))
  end
  def length_squared(v) do
    v.x*v.x + v.y*v.y + v.z*v.z
  end
  def element_mul(v1, v2) do
    %{
      x: v1.x * v2.x,
      y: v1.y * v2.y,
      z: v1.z * v2.z
    }
  end

  ## Helpers

  def dot(v1, v2) do
    v1.x*v2.x + v1.y*v2.y + v1.z*v2.z
  end
  def cross(v1, v2) do
    %{
      x: v1.y*v2.z - v1.z*v2.y,
      y: v1.z*v2.x - v1.x*v2.z,
      z: v1.x*v2.y - v1.y*v2.x
    }
  end
  def unit_vector(v) do
    divide(v, vec3_length(v))
  end
  def random_in_unit_disk() do
    p = vec3(
      :rand.uniform() * 2 -1,
      :rand.uniform() * 2 -1,
      0
    )

    if p |> length_squared() >= 1 do
      random_in_unit_disk()
    else
      p
    end
  end
  def random_in_unit_sphere() do
    v = vec3_random()

    if length_squared(v) < 1 do
      v
    else
      random_in_unit_sphere()
    end
  end
  def random_unit_vector() do
    random_in_unit_sphere() |> unit_vector()
  end
  def near_zero(v) do
    s = 1.0e-18

    (abs(v.x) < s) and (abs(v.y) < s) and (abs(v.z) < s)
  end
  def reflect(v, n) do
    v
    |> sub(
      n |> mul(2 * dot(v, n))
    )
  end
  def refract(uv, n, etai_over_etat) do
    cos_theta = uv
    |> mul(-1)
    |> dot(n)
    |> min(1)

    r_out_perp = n
    |> mul(cos_theta)
    |> add(uv)
    |> mul(etai_over_etat)

    r_out_parallel = n
    |> mul(
      -:math.sqrt(
        abs(
          1 - length_squared(r_out_perp)
        )
      )
    )

    r_out_perp |> add(r_out_parallel)
  end
end
