defmodule Camera do

  require Ray
  require Vector

  def camera(params) do
    w = params.origin
    |> Vector.sub(params.look_at)
    |> Vector.unit_vector()

    u = params.v_up
    |> Vector.cross(w)
    |> Vector.unit_vector()

    v = w |> Vector.cross(u)

    horizontal = u
    |> Vector.mul(params.viewport_width)
    |> Vector.mul(params.focus_dist)

    vertical = v
    |> Vector.mul(params.viewport_height)
    |> Vector.mul(params.focus_dist)

    lower_left_corner = params.origin
    |> Vector.sub(Vector.divide(horizontal, 2))
    |> Vector.sub(Vector.divide(vertical, 2))
    |> Vector.sub(
      w |> Vector.mul(params.focus_dist)
    )

    %{
      origin: params.origin,
      horizontal: horizontal,
      vertical: vertical,
      lower_left_corner: lower_left_corner,
      lens_radius: params.aperture / 2,
      u: u,
      v: v,
      w: w,
      position: params.position, # unused
    }
  end

  def camera_get_ray(camera, s, t) do
    rd = Vector.random_in_unit_disk() |> Vector.mul(camera.lens_radius)
    offset = camera.u
    |> Vector.mul(rd.x)
    |> Vector.add(
      camera.v |> Vector.mul(rd.y)
    )

    direction = camera.lower_left_corner
    |> Vector.add(Vector.mul(camera.horizontal, s))
    |> Vector.add(Vector.mul(camera.vertical, t))
    |> Vector.sub(camera.origin)
    |> Vector.sub(offset)

    Ray.ray(camera.origin |> Vector.add(offset), direction)
  end
end
